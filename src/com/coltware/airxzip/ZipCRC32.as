/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxzip {
	
	import 	flash.utils.*;
	
	/**
	 * @private
	 * 
	 */
	public class ZipCRC32 {
		
		public static var CRYPTHEADLEN:int = 12;
		
		private static var S_KEY1:uint = 305419896;
		private static var S_KEY2:uint = 591751049;
		private static var S_KEY3:uint = 878082192;
		
		private static var _crc32table:Array = createTable();
		
		private var _key:Array;
		
		public function ZipCRC32() {
		}
		
		private static function createTable():Array{
			
			var arr:Array = new Array(256);
			var p:uint = 0xEDB88320;
			var c:uint;
			for(var i:uint =0; i<256; i++){
				c = i;
				for(var j:uint = 0; j < 8; j++){
					if(c & 1){
						c = uint(p ^ uint(c >>> 1));
					}
					else{
						c = uint(c >>> 1);
					}
					arr[i] = c;
				}
			}
			return arr;
		}
		
		public static function getByteArrayValue(data:ByteArray):uint{
			var c:uint = 0xffffffff;
			var n:uint = 0;
			for(var i:int =0; i<data.length; i++){
				n = ( c ^ data[i] ) & 0xFF;
				c = uint(_crc32table[n]) ^ ( c >>> 8 );
			}
			return (c ^ 0xffffffff);
		}
		
		public static function getCRC32(n1:uint,n2:uint):uint{
            var _idx:uint = ( n1 ^ n2 ) & 0xFF;
            var _val:uint = _crc32table[_idx] ^ (n1 >>> 8 );
            return _val;
        }
		
		public static function getStringValue(str:String):uint{
			var ba:ByteArray = new ByteArray();
			ba.writeUTFBytes(str);
			return getByteArrayValue(ba);
		}
		
	}
}