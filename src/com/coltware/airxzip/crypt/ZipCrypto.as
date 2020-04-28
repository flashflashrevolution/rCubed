/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxzip.crypt
{
	
	import com.coltware.airxzip.ZipCRC32;
	import com.coltware.airxzip.ZipEntry;
	import com.coltware.airxzip.ZipError;
	import com.coltware.airxzip.ZipHeader;
	import com.coltware.airxzip.zip_internal;
	
	import flash.utils.*;
	
	use namespace zip_internal;
	
	public class ZipCrypto implements ICrypto
	{
		
		private static var CRYPTHEADLEN:int = 12;
		
		// Initial keys
		private static var S_KEY1:int = 305419896;
		private static var S_KEY2:int = 591751049;
		private static var S_KEY3:int = 878082192;
		
		private var _key:Array;
		private var _password:ByteArray;
		private var _header:ZipHeader;
		
		private var _outBytes:ByteArray;
		
		public function ZipCrypto()
		{
		
		}
		
		public function initEncrypt(password:ByteArray, header:ZipHeader):void
		{
			var crc32:uint = header._crc32;
			_outBytes = new ByteArray();
			_initEncrypt(password, crc32);
			
			header._compressSize += CRYPTHEADLEN;
		
		}
		
		/**
		 *  暗号時に使用する初期化処理
		 *
		 */
		private function _initEncrypt(password:ByteArray, crc32:uint):void
		{
			
			crc32 = crc32 >> 24;
			
			var ret:ByteArray = _outBytes;
			_key = new Array(3);
			_key[0] = S_KEY1;
			_key[1] = S_KEY2;
			_key[2] = S_KEY3;
			
			password.position = 0;
			while (password.bytesAvailable > 0)
			{
				var n:uint = password.readUnsignedByte();
				updateKeys(n);
			}
			
			var d:uint;
			for (var i:int = 0; i < CRYPTHEADLEN; i++)
			{
				if (i == CRYPTHEADLEN - 1)
				{
					d = uint(crc32 & 0xff);
				}
				else
				{
					d = uint((crc32 >> 32) & 0xFF);
				}
				d = zencode(d);
				ret.writeByte(d);
			}
		
		}
		
		/**
		 *  encrypt data
		 */
		public function encrypt(data:ByteArray):ByteArray
		{
			
			data.position = 0;
			while (data.bytesAvailable)
			{
				var n:uint = data.readUnsignedByte();
				_outBytes.writeByte(zencode(n));
			}
			_outBytes.position = 0;
			
			return _outBytes;
		}
		
		public function checkDecrypt(entry:ZipEntry):Boolean
		{
			return true;
		}
		
		public function initDecrypt(password:ByteArray, header:ZipHeader):void
		{
			this._password = password;
			this._header = header;
		}
		
		public function decrypt(data:ByteArray):ByteArray
		{
			var check1:uint = _header._crc32 >>> 24;
			var cryptoHeader:ByteArray = new ByteArray();
			data.readBytes(cryptoHeader, 0, CRYPTHEADLEN);
			var check2:uint = _initDecrypt(this._password, cryptoHeader);
			check2 = (check2 & 0xffff);
			if (check1 == check2)
			{
				return _decrypt(data);
			}
			else
			{
				throw new ZipError("password is not match");
			}
		
		}
		
		/**
		 *  解凍時に使用する初期化処理
		 *
		 */
		private function _initDecrypt(password:ByteArray, cryptHeader:ByteArray):uint
		{
			
			var ret:ByteArray = new ByteArray();
			_key = new Array(3);
			_key[0] = S_KEY1;
			_key[1] = S_KEY2;
			_key[2] = S_KEY3;
			
			password.position = 0;
			
			while (password.bytesAvailable > 0)
			{
				var n:uint = password.readUnsignedByte();
				updateKeys(n);
			}
			cryptHeader.position = 0;
			
			for (var i:int = 0; i < CRYPTHEADLEN; i++)
			{
				var b:uint = cryptHeader.readUnsignedByte();
				b = zdecode(b);
			}
			return b;
		}
		
		/**
		 *  解凍処理
		 *
		 */
		private function _decrypt(data:ByteArray):ByteArray
		{
			
			var out:ByteArray = new ByteArray();
			while (data.bytesAvailable > 0)
			{
				var n:uint = data.readUnsignedByte();
				n = zdecode(n);
				out.writeByte(n);
			}
			out.position = 0;
			return out;
		}
		
		/**
		 *  解凍用
		 */
		protected function zdecode(n:uint):uint
		{
			var t:uint = n;
			
			var d:uint = decryptByte();
			n ^= d;
			updateKeys(n);
			return n;
		}
		
		/**
		 *  暗号用
		 */
		protected function zencode(n:uint):uint
		{
			var t:uint = decryptByte();
			updateKeys(n);
			return (t ^ n);
		}
		
		/**
		 *
		 *  @return unsigned char
		 */
		protected function decryptByte():int
		{
			var temp:uint = _key[2] & 0xFFFF | 2;
			var ret:int = ((temp * (temp ^ 1)) >> 8) & 0xFF;
			return ret;
		}
		
		/**
		 *
		 *
		 */
		protected function updateKeys(uchar:uint):void
		{
			_key[0] = ZipCRC32.getCRC32(_key[0], uchar);
			_key[1] = _key[1] + (_key[0] & 0xFF);
			
			//  ここで２つに分けるのは計算途中でNumber型になってしまい精度が落ちてしまうので・・・
			var k2:int = _key[1];
			var b1:int = 134775000;
			var b2:int = 813;
			var t:int = uint(k2 * b1) + uint(k2 * b2) + 1;
			_key[1] = t;
			
			var k3:int = _key[1];
			
			var tmp:int = _key[1] >> 24;
			_key[2] = int(ZipCRC32.getCRC32(_key[2], tmp));
		}
	}
}