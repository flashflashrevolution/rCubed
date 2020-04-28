/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxzip
{
	
	import com.coltware.airxzip.crypt.ICrypto;
	import com.coltware.airxzip.crypt.ZipCrypto;
	import flash.events.*;
	import flash.filesystem.*;
	import flash.utils.*;
	
	use namespace zip_internal;
	
	/**
	 *  ZIPファイルを読み込むクラス
	 */
	public class ZipFileReader extends EventDispatcher
	{
		
		private var _file:File;					//	Zipファイル
		private var _stream:FileStream;
		
		private var _charset:String = "shift_jis";
		
		/*  イベント名 */
		
		//public static var LOAD_ZIPFILE:String = "loadZipFile";
		
		private var _unzipStack:Array;
		private var _unzipWorking:Boolean = false;
		private var _unzipNum:int = 0;
		
		private var _endRecord:ZipEndRecord;
		private var _entries:Array;
		private var _totalEntries:uint = 0;
		
		private var _decryptors:Array;
		
		/* 暗号化されているときのパスワード */
		private var _password:ByteArray;
		
		/**
		 *  dataAsync()コマンドを投げてデータが書き出せる状態になったときのイベント
		 *
		 * @eventType com.coltware.airxzip.ZipEvent.ZIP_DATA_UNCOMPRESS
		 */
		[Event(name = "zipDataUncompress", type = "com.coltware.airxzip.ZipEvent")]
		
		public function ZipFileReader()
		{
			_stream = new FileStream();
			_stream.addEventListener(IOErrorEvent.IO_ERROR, ioError);
			_unzipStack = new Array();
			_entries = new Array();
			_decryptors = new Array();
		}
		
		/**
		 *  ファイルがZIP形式かチェックします
		 *
		 * メモ：先頭バイトが0x04034b50であるかを確認します
		 */
		public function check(file:File):Boolean
		{
			if (file.isDirectory)
			{
				return false;
			}
			else if (file.isSymbolicLink)
			{
				return false;
			}
			else
			{
				try
				{
					var s:FileStream = new FileStream();
					s.open(file, FileMode.READ);
					s.endian = Endian.LITTLE_ENDIAN;
					s.position = 0;
					var i:int = s.readInt();
					s.close();
					if (i == ZipHeader.HEADER_LOCAL_FILE)
					{
						return true;
					}
				}
				catch (err:Error)
				{
					return false;
				}
				return false;
			}
		}
		
		/**
		 * ファイルをオープンします
		 *
		 */
		public function open(file:File):void
		{
			_file = file;
			_stream.open(_file, FileMode.READ);
			
			_stream.endian = Endian.LITTLE_ENDIAN;
			
			_stream.position = _stream.bytesAvailable - ZipEndRecord.LENGTH;
			var pos:int = 0;
			var sig:int = 0;
			while (_stream.position > 0)
			{
				pos = _stream.position;
				sig = _stream.readInt();
				if (sig == ZipEndRecord.SIGNATURE)
				{
					_endRecord = new ZipEndRecord();
					_stream.position = pos;
					_endRecord.read(_stream);
					//_endRecord.dumpLogInfo();
					
					_entries = new Array();
					_totalEntries = _endRecord.getTotalEntries();
					
					break;
				}
				_stream.position = pos - 1;
			}
		}
		
		public function close():void
		{
			if (_stream)
			{
				_stream.close();
			}
		}
		
		/**
		 *   Add decrypto instance
		 */
		public function addDecrypto(crypto:ICrypto):void
		{
			this._decryptors.push(crypto);
		}
		
		public function setPasswordBytes(bytes:ByteArray):void
		{
			this._password = bytes;
			this._password.position = 0;
		}
		
		/**
		 *  パスワードを文字列で指定する
		 */
		public function setPassword(password:String, charset:String = null):void
		{
			var ba:ByteArray = new ByteArray();
			if (charset == null)
			{
				ba.writeUTFBytes(password);
			}
			else
			{
				ba.writeMultiByte(password, charset);
			}
			this._password = ba;
			this._password.position = 0;
		}
		
		/**
		 *  Zipファイルのエントリーをリストを取得します
		 *
		 */
		public function getEntries():Array
		{
			parseCentralHeaders();
			return _entries;
		}
		
		/**
		 *
		 *  解凍してByteArrayにして返す
		 *
		 */
		public function unzip(entry:ZipEntry):ByteArray
		{
			var pos:int = entry.getLocalHeaderOffset();
			
			_stream.position = pos;
			var lzh:ZipHeader = new ZipHeader();
			lzh.readAuto(_stream);
			entry._headerLocal = lzh;
			
			var bytes:ByteArray = new ByteArray();
			var size:int = entry.getCompressSize();
			if (size > 0)
			{
				_stream.readBytes(bytes, 0, entry.getCompressSize());
			}
			
			if (entry.isEncrypted())
			{
				if (this._password == null)
				{
					throw new ZipError("password is NULL");
				}
				
				var decrypt:ICrypto = null;
				for (var i:int = 0; (i < _decryptors.length && decrypt == null); i++)
				{
					var _decrypt:ICrypto = _decryptors[i];
					if (_decrypt.checkDecrypt(entry))
					{
						decrypt = _decrypt;
					}
				}
				if (decrypt == null)
				{
					decrypt = new ZipCrypto();
				}
				decrypt.initDecrypt(this._password, lzh);
				bytes = decrypt.decrypt(bytes);
			}
			
			var method:int = entry.getCompressMethod();
			if (method == ZipEntry.METHOD_NONE)
			{
			}
			else if (method == ZipEntry.METHOD_DEFLATE)
			{
				bytes.uncompress(CompressionAlgorithm.DEFLATE);
			}
			else
			{
				throw new ZipError("not support compress method : " + method);
			}
			return bytes;
		}
		
		/**
		 *  何もせずに、生のデータを取得する
		 *
		 */
		public function rawdata(entry:ZipEntry):ByteArray
		{
			var pos:int = entry.getLocalHeaderOffset();
			_stream.position = pos;
			var lzh:ZipHeader = new ZipHeader();
			lzh.readAuto(_stream);
			entry._headerLocal = lzh;
			
			var bytes:ByteArray = new ByteArray();
			var size:int = entry.getCompressSize();
			if (size > 0)
			{
				_stream.readBytes(bytes, 0, entry.getCompressSize());
			}
			bytes.position = 0;
			return bytes;
		}
		
		/**
		 *  非同期処理として解凍処理をします
		 *
		 *	@eventType com.coltware.airxzip.ZipEvent.ZIP_DATA_UNCOMPRESS
		 *
		 */
		public function unzipAsync(entry:ZipEntry):void
		{
			this._unzipStack.push(entry);
			if (_unzipWorking == false)
			{
				this.execUnzip(1000);
			}
		}
		
		private function unzipAsyncTimeout(entry:ZipEntry):void
		{
			var event:ZipEvent = new ZipEvent(ZipEvent.ZIP_DATA_UNCOMPRESS);
			var pos:int = entry.getLocalHeaderOffset();
			_stream.position = pos;
			_stream.position = pos;
			var lzh:ZipHeader = new ZipHeader();
			lzh.readAuto(_stream);
			entry._headerLocal = lzh;
			
			var bytes:ByteArray = new ByteArray();
			var size:int = entry.getCompressSize();
			if (size > 0)
			{
				_stream.readBytes(bytes, 0, size);
			}
			
			var err:ZipErrorEvent;
			
			if (entry.isEncrypted())
			{
				
				if (this._password == null)
				{
					err = new ZipErrorEvent(ZipErrorEvent.ZIP_PASSWORD_ERROR);
					this.dispatchEvent(err);
					return;
				}
				
				var decrypt:ICrypto = null;
				for (var i:int = 0; (i < _decryptors.length && decrypt == null); i++)
				{
					var _decrypt:ICrypto = _decryptors[i];
					if (_decrypt.checkDecrypt(entry))
					{
						decrypt = _decrypt;
					}
				}
				if (decrypt == null)
				{
					decrypt = new ZipCrypto();
				}
				decrypt.initDecrypt(this._password, lzh);
				
				try
				{
					bytes = decrypt.decrypt(bytes);
				}
				catch (ze:ZipError)
				{
					err = new ZipErrorEvent(ZipErrorEvent.ZIP_PASSWORD_ERROR);
					this.dispatchEvent(err);
				}
			}
			
			var method:int = entry.getCompressMethod();
			if (method == ZipEntry.METHOD_NONE)
			{
				
			}
			else if (method == ZipEntry.METHOD_DEFLATE)
			{
				event.$method = CompressionAlgorithm.DEFLATE;
			}
			else
			{
				var e:ZipErrorEvent = new ZipErrorEvent(ZipErrorEvent.ZIP_NO_SUCH_METHOD);
				this.dispatchEvent(e);
				return;
			}
			
			event.$entry = entry;
			event.$data = bytes;
			this.dispatchEvent(event);
			_unzipWorking = false;
			_unzipNum++;
			
			execUnzip();
		}
		
		private function execUnzip(delay:int = 10):void
		{
			if (_unzipStack.length > 0)
			{
				_unzipWorking = true;
				var entry:ZipEntry = _unzipStack.shift();
				setTimeout(unzipAsyncTimeout, delay, entry);
			}
			else
			{
				
			}
		}
		
		private function ioError(e:Event):void
		{
			this.dispatchEvent(e);
		}
		
		protected function parseCentralHeaders():void
		{
			var offset:int = _endRecord.getOffset();
			var size:int = _endRecord.getSize();
			_stream.position = offset;
			var bytes:ByteArray = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			_stream.readBytes(bytes, 0, size);
			bytes.position = 0;
			
			var _tmpBytes:ByteArray = new ByteArray();
			_tmpBytes.endian = Endian.LITTLE_ENDIAN;
			
			while (bytes.bytesAvailable)
			{
				var sig:int = bytes.readInt();
				var header:ZipHeader = new ZipHeader(sig);
				header.read(bytes, _tmpBytes);
				var entry:ZipEntry = new ZipEntry(_stream);
				entry.setHeader(header);
				_entries.push(entry);
			}
		}
		
		private function readStream(e:Event):void
		{
			//trace("byte available " + _stream.bytesAvailable + "/" + _file.size);
			var bytes:ByteArray = new ByteArray();
			_stream.endian = Endian.LITTLE_ENDIAN;
			bytes.endian = Endian.LITTLE_ENDIAN;
			while (_stream.bytesAvailable)
			{
				//trace("byte available " + _stream.bytesAvailable);
				var sig:int = _stream.readInt();
				if (sig == ZipHeader.HEADER_LOCAL_FILE)
				{
					
					//  LOCAL FILE HEADER
					var header:ZipHeader = new ZipHeader(sig);
					header.read(_stream, bytes);
					
					var contentByteArray:ByteArray = new ByteArray();
					if (header.getCompressSize() > 0)
					{
						_stream.readBytes(contentByteArray, 0, header.getCompressSize());
					}
					var entry:ZipEntry = new ZipEntry(_stream);
					entry.setHeader(header);
						//entry.setContent(contentByteArray);
				}
				else if (sig == ZipHeader.HEADER_CENTRAL_DIR)
				{
					//	CENTRAL DIRECTORY
					var centralHeader:ZipHeader = new ZipHeader(sig);
					centralHeader.read(_stream, bytes);
				}
				else
				{
					//trace("sig NG " + sig.toString(16));
					break;
				}
				
			}
		}
	}
}