/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxzip {
	
	import flash.events.Event;
	import flash.utils.*;
	
	use namespace zip_internal;
	/**
	 *  ZIPの解凍や圧縮時のイベントクラス
	 *
	 */
	public class ZipEvent extends Event{
		
		public static var ZIP_LOAD_DATA:String = "zipLoadData";
		public static var ZIP_DATA_UNCOMPRESS:String = "zipDataUncompress";
		public static var ZIP_DATA_COMPRESS:String   = "zipDataCompress";
		public static var ZIP_FILE_CREATED:String  = "zipFileCreated";
		
		zip_internal var $entry:ZipEntry;
		zip_internal var $data:ByteArray;
		zip_internal var $method:String;
		
		public function ZipEvent(type:String) {
			super(type);
		}
		
		public function get entry():ZipEntry{
			return $entry;
		}
		
		public function get data():ByteArray{
			if($method){
				$data.uncompress($method);
			}
			return $data;
		}
	}
}