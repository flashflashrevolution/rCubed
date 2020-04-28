/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxzip {
	
	import flash.utils.*;
	
	use namespace zip_internal;
	
	/**
	*  ZIPファイルのヘッダ情報を管理する
	*  
	 * @private
	*/
	public class ZipHeader {
		
		public static var HEADER_LOCAL_FILE:uint  		= 0x04034b50;
		public static var HEADER_CENTRAL_DIR:uint 		= 0x02014b50;
		public static var HEADER_END_CENTRAL_DIR:uint 	= 0x06054b50; 
		
		public static var WIN_DIR:int 	= 16;
		public static var WIN_FILE:int 	= 32;
		
		public static var UNIX_DIR:int 	= 0x4000; 
		public static var UNIX_FILE:int = 0x8000;
		
		zip_internal var _signature:uint;
		zip_internal var _version:uint;
		zip_internal var _bitFlag:uint;
		zip_internal var _compressMethod:uint;
		zip_internal var _lastModTime:int;
		zip_internal var _lastModDate:int;
		zip_internal var _crc32:uint;
		zip_internal var _compressSize:uint;
		zip_internal var _uncompressSize:uint;
		zip_internal var _filenameLength:uint;
		zip_internal var _extraFieldLength:uint;
		zip_internal var _filename:ByteArray;
		zip_internal var _extraField:ByteArray;
		
		//  ここより CENTRAL DIRECTORY 
		zip_internal var _versionBy:uint;
		zip_internal var _commentLength:uint;
		zip_internal var _diskNumber:uint = 0;
		zip_internal var _internalFileAttrs:uint = 0;
		zip_internal var _externalFileAttrs:uint = 0;
		zip_internal var _offsetLocalHeader:uint;
		zip_internal var _comment:ByteArray;
		
		public function ZipHeader(sig:uint = 0x04034b50 ) {
			_signature = sig;
		}
		
		public function read(stream:IDataInput,bytes:ByteArray):void{
			if(_signature == HEADER_LOCAL_FILE){
				readLocalHeader(stream,bytes);
			}
			else if(_signature == HEADER_CENTRAL_DIR){
				readCentralHeader(stream,bytes);
			}
		}
		
		public function readAuto(stream:IDataInput):void{
			var bytes:ByteArray = new ByteArray();
			bytes.endian 	= Endian.LITTLE_ENDIAN;
			_signature = stream.readInt();
			this.read(stream,bytes);
		}
		
		public function getCompressMethod():uint{
			return _compressMethod;
		}
		
		/**
		*  圧縮前のサイズ
		*
		*/
		public function getUncompressSize():uint{
			return _uncompressSize;
		}
		/**
		*  圧縮後のサイズを取得
		*
		*/
		public function getCompressSize():uint{
			return _compressSize;
		}
		/**
		*  ディレクトリか（ファイルか)
		*
		*/
		public function isDirectory():Boolean{
			if(_uncompressSize == 0){
				if(_externalFileAttrs == 0 ){
					return false;
				}
				else{
					if(_externalFileAttrs&16){
						return true;
					}
					else{
						var num:uint = ((_externalFileAttrs >> 16) & 0xFFFF);
						if(num & ZipHeader.UNIX_DIR){
							return true;
						}
					}
					
				}
			}
			return false;
		}
		
		public function getCompressRate():Number{
			if(_uncompressSize == 0 ){
				return 0;
			}
			var num:Number = _compressSize / _uncompressSize;
			return 1 - num;
		}
		
		public function getDate():Date{
			var sec:int   = _lastModTime & 0x001f;
			var min:int   = ( _lastModTime & 0x07e0 ) >> 5;
			var hour:int  = ( _lastModTime & 0xf800 ) >> 11;
			var day:int   = ( _lastModDate & 0x001f );
			var month:int = ( _lastModDate & 0x01e0 ) >> 5;
			var year:int  = (( _lastModDate & 0xfe00 ) >> 9 ) + 1980;
			var date:Date = new Date(year,month -1, day,hour,min,sec,0);
			return date;  
		}
		/**
		*  LOCAL FILE HEADER ヘッダの場所を返す.
		*
		*/
		public function getLocalHeaderOffset():int{
			return _offsetLocalHeader;
		}
		
		public function getFilename(charset:String = null):String{
			if(_filenameLength < 1 ){
				return "";
			}
			if(charset == null){
				//  自動的に判断する
				if(( _versionBy >> 8 ) == 3){
					charset = "utf-8";
				}
				else{
					charset = "shift_jis";
				}
			}
			
			var _char:String = charset.toLowerCase();
			if(_char == "utf-8"){
				return getFilenameUTF8();
			}
			else{
				_filename.position = 0;
				return _filename.readMultiByte(_filename.bytesAvailable,charset);
			}
		}
		
		/**
		*  LOCAL HEADERのサイズを返します.
		* 
		*
		*/ 
		public function getLocalHeaderSize():int{
			return 30 + _filenameLength + _extraFieldLength;
		}
		
		protected function readLocalHeader(stream:IDataInput,bytes:ByteArray):void{
			stream.readBytes(bytes,0,26);
			// バージョン情報
			bytes.position = 0;
			_version = bytes.readUnsignedShort();
			
			// 設定ビット
			bytes.position = 2;
			_bitFlag = bytes.readUnsignedShort();
			
			// 圧縮方式
			bytes.position = 4;
			_compressMethod = bytes.readUnsignedShort();
			
			//  最終変更時刻
			bytes.position = 6;
			_lastModTime = bytes.readUnsignedShort();
			
			// 最終変更日時
			bytes.position = 8;
			_lastModDate = bytes.readUnsignedShort();
			
			// CRC32
			bytes.position = 10;
			_crc32 = bytes.readUnsignedInt();
			
			// 圧縮後のサイズ
			bytes.position = 14;
			_compressSize = bytes.readUnsignedInt();
			
			// 圧縮前のサイズ
			bytes.position = 18;
			_uncompressSize = bytes.readUnsignedInt();
			
			// ファイルの長さ
			bytes.position = 22;
			_filenameLength = bytes.readShort();
			
			// 拡張領域のサイズ
			bytes.position = 24;
			_extraFieldLength = bytes.readShort();
			
			if(_signature == HEADER_LOCAL_FILE){
			
				//  さらにファイル名と拡張領域のサイズ分だけさらに読み込む
				stream.readBytes(bytes,26,_filenameLength + _extraFieldLength);
			
				// ファイル名
				bytes.position = 26;
				_filename = new ByteArray();
				bytes.readBytes(_filename,0,_filenameLength);
			
				// 拡張領域
				if(_extraFieldLength > 0 ){
					_extraField = new ByteArray();
					bytes.readBytes(_extraField,0,_extraFieldLength);
				}
			}
		}
		
		public function writeLocalHeader(stream:IDataOutput):void{
			this.writeHeader(stream,false);
		}
		
		public function writeCentralHeader(stream:IDataOutput):void{
			this.writeHeader(stream,true);
		}
		
		/**
		*  ヘッダを書き込む
		*
		*/
		protected function writeHeader(stream:IDataOutput,isCentral:Boolean = false):void{
			if(isCentral){
				_signature = HEADER_CENTRAL_DIR;
				stream.writeUnsignedInt(HEADER_CENTRAL_DIR);
				stream.writeShort(_versionBy);	
			}
			else{
				_signature = HEADER_LOCAL_FILE;
				stream.writeUnsignedInt(HEADER_LOCAL_FILE);	
			}
			stream.writeShort(_version);
			stream.writeShort(_bitFlag);
			stream.writeShort(_compressMethod);
			stream.writeShort(_lastModTime);
			stream.writeShort(_lastModDate);
			stream.writeUnsignedInt(_crc32);
			stream.writeUnsignedInt(_compressSize);
			stream.writeUnsignedInt(_uncompressSize);
			stream.writeShort(_filenameLength);
			stream.writeShort(_extraFieldLength);
			
			
			if(_extraFieldLength > 0 ){
				_extraField.position = 0;
				stream.writeBytes(_extraField);
			}
			
			if(isCentral){
				stream.writeShort(_commentLength);
				stream.writeShort(_diskNumber);
				stream.writeShort(_internalFileAttrs);
				stream.writeUnsignedInt(_externalFileAttrs);
				stream.writeUnsignedInt(_offsetLocalHeader);
			}
			
			_filename.position = 0;
			stream.writeBytes(_filename);
			
			if(_extraFieldLength > 0 ){
				
			}
			
		}
		
		protected function readCentralHeader(stream:IDataInput,bytes:ByteArray):void{
			
			stream.readBytes(bytes,0,42);
			// 作成されてバージョン
			bytes.position = 0;
			_versionBy = bytes.readUnsignedShort();
			
			// バージョン情報
			bytes.position = 2;
			_version = bytes.readUnsignedShort();
			
			// 設定ビット
			bytes.position = 4;
			_bitFlag = bytes.readUnsignedShort();
			
			// 圧縮方式
			bytes.position = 6;
			_compressMethod = bytes.readUnsignedShort();
			
			//  最終変更時刻
			bytes.position = 8;
			_lastModTime = bytes.readUnsignedShort();
			
			// 最終変更日時
			bytes.position = 10;
			_lastModDate = bytes.readUnsignedShort();
			
			// CRC32
			bytes.position = 12;
			_crc32 = bytes.readUnsignedInt();
			
			// 圧縮後のサイズ
			bytes.position = 16;
			_compressSize = bytes.readUnsignedInt();
			
			// 圧縮前のサイズ
			bytes.position = 20;
			_uncompressSize = bytes.readUnsignedInt();
			
			// ファイルの長さ
			bytes.position = 24;
			_filenameLength = bytes.readShort();
			
			// 拡張領域のサイズ
			bytes.position = 26;
			_extraFieldLength = bytes.readShort();
			
			// コメント
			bytes.position = 28;
			_commentLength = bytes.readUnsignedShort();
			
			bytes.position = 30;
			_diskNumber    = bytes.readUnsignedShort();
			
			bytes.position = 32;
			_internalFileAttrs = bytes.readUnsignedShort();
			
			bytes.position = 34;
			_externalFileAttrs = bytes.readUnsignedInt();
			
			bytes.position = 38;
			_offsetLocalHeader = bytes.readUnsignedInt();
			
			//  さらにファイル名と拡張領域・コメントのサイズ分だけさらに読み込む
			var len:int = _filenameLength + _extraFieldLength + _commentLength;
			stream.readBytes(bytes,42,len);
			
			// ファイル名
			bytes.position = 42;
			if(_filenameLength > 0 ){
				_filename = new ByteArray();
				bytes.readBytes(_filename,0,_filenameLength);
			}
			// 拡張領域
			if(_extraFieldLength > 0 ){
				_extraField = new ByteArray();
				bytes.readBytes(_extraField,0,_extraFieldLength);
			}
			
			if(_commentLength > 0 ){
				_comment = new ByteArray();
				bytes.readBytes(_comment,0,_commentLength);
			}
		}
		
		
		
		/**
		*  MAC もしくはWindowsを意識することなくファイル名を取得する
		*/
		protected function getFilenameUTF8():String{
			
			if(!_filename){
				return "";
			}
			
			_filename.position = 0;
			var ch:int;
			var ba:ByteArray = new ByteArray();
			var ret:String = "";
			while(_filename.bytesAvailable){
				ch = _filename.readUnsignedByte();
				if(ch >= 0x00 && ch <= 0x7F){
					ba.writeByte(ch);
				}
				else if(ch >= 0xC0 && ch <= 0xDF){
					// 2byte
					ba.writeByte(ch);
					ba.writeByte(_filename.readUnsignedByte());
				}
				else if(ch >= 0xE0 && ch <= 0xEF){
					// 3byte
					
					var ch1:int = _filename.readUnsignedByte();
					var ch2:int = _filename.readUnsignedByte();
					
					if(ch == 0xe3 && ch1 == 0x82 && ch2 == 0x99){
						ba.position--;
						ch = ba.readUnsignedByte() + 1;
						ba.position--;
						ba.writeByte(ch);
					}
					else if(ch == 0xe3 && ch1 == 0x82 && ch2 == 0x9a){
						ba.position--;
						ch = ba.readUnsignedByte() + 2;
						ba.position--;
						ba.writeByte(ch);
					}
					
					else{
						ba.writeByte(ch);
						ba.writeByte(ch1);
						ba.writeByte(ch2);
					}
				}
				else if(ch >= 0xF0 && ch <= 0xF7){
					// 4byte
					ba.writeByte(ch);
					ba.writeByte(_filename.readUnsignedByte());
					ba.writeByte(_filename.readUnsignedByte());
					ba.writeByte(_filename.readUnsignedByte());
					
				}
				
			}
			ba.position = 0;
			ret = ba.readMultiByte(ba.bytesAvailable,"utf-8");
			return ret;
		}
		
		public function getVersion():int{
			return ( _versionBy & 0xff );
		}
		
		
	}

}