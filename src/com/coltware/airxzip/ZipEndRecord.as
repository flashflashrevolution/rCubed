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

	
	/**
	 * 
	 * @private
	 * 
	 */
	public class ZipEndRecord {
		
		public static var LENGTH:int = 22;
		public static var SIGNATURE:uint 	= 0x06054b50; 
		
		private var _signature:int;
		private var _numberDisk:uint;
		private var _numberDiskStartCentralDir:uint;
		private var _totalEntriesDisk:uint;
		private var _totalEntries:uint;
		private var _sizeCentralDir:uint;
		private var _offsetCentralDir:uint;
		private var _commentLength:uint;
		private var _comment:ByteArray;
		
		
		public function ZipEndRecord() {
			
		}
		
		public function write(data:IDataOutput,fileNum:int,offset:int,centralDirSize:int):void{
			
			_signature = SIGNATURE;
			_numberDisk = 0;
			_totalEntries = fileNum;
			_commentLength = 0;
			_sizeCentralDir = centralDirSize;
			_offsetCentralDir = offset;
			
			data.writeUnsignedInt(SIGNATURE);
			
			data.writeShort(_numberDisk);  // Number of this disk
			
			data.writeShort(0);
			data.writeShort(_totalEntries);
			data.writeShort(_totalEntries);
			
			data.writeUnsignedInt(_sizeCentralDir);
			data.writeUnsignedInt(_offsetCentralDir);
			
			data.writeShort(_commentLength);	//	コメント
			
		}
		
		public function read(data:IDataInput):void{
			var bytes:ByteArray = new ByteArray();
			bytes.endian 	= Endian.LITTLE_ENDIAN;
			data.readBytes(bytes,0,LENGTH);
			
			bytes.position = 0;
			_signature 					= bytes.readInt();
			
			bytes.position = 4;
			_numberDisk 				= bytes.readUnsignedShort();
			bytes.position = 6;
			_numberDiskStartCentralDir 	= bytes.readUnsignedShort();
			bytes.position = 8;
			_totalEntriesDisk			= bytes.readShort();
			bytes.position = 10;
			_totalEntries				= bytes.readShort();
			bytes.position = 12;
			_sizeCentralDir				= bytes.readInt();
			bytes.position = 16;
			_offsetCentralDir			= bytes.readInt();
			bytes.position = 20;
			_commentLength				= bytes.readUnsignedShort();
			
			if(_commentLength > 0 ){
				data.readBytes(bytes,LENGTH,_commentLength);
			}	
		}
		/**
		*  Central Direcotry のオフセットを取得する
		*/
		public function getOffset():int{
			return _offsetCentralDir;
		}
		
		public function getSize():int{
			return _sizeCentralDir;
		}
		
		/**
		*  TOTALのファイルサイズを返す
		*
		*/
		public function getTotalEntries():uint{
			return _totalEntries;
		}
	}
}