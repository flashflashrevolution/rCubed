package com.coltware.airxzip
{
	import flash.events.ErrorEvent;

	public class ZipErrorEvent extends ErrorEvent
	{
		public static const ZIP_NO_SUCH_METHOD:String = "ZipNoSuchMethod";
		/**
		 *  Password is not match or not set(NULL)
		 */
		public static const ZIP_PASSWORD_ERROR:String = "ZipPasswordError"; 
		
		public function ZipErrorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, text:String=null, id:int=0)
		{
			super(type, bubbles, cancelable, text, id);
		}
		
	}
}