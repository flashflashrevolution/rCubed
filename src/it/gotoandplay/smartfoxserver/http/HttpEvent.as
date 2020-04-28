package it.gotoandplay.smartfoxserver.http
{
	import flash.events.Event;
	
	/**
	 * HttpEvent class.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public class HttpEvent extends Event
	{
		public static const onHttpData:String = "onHttpData"
		public static const onHttpError:String = "onHttpError"
		public static const onHttpConnect:String = "onHttpConnect"
		public static const onHttpClose:String = "onHttpClose"
		
		public var params:Object
		private var evtType:String
		
		function HttpEvent(type:String, params:Object)
		{
			super(type)
			
			this.params = params
			this.evtType = type
		}
		
		public override function clone():Event
		{
			return new HttpEvent(this.evtType, this.params)
		}
		
		public override function toString():String
		{
			return formatToString("HttpEvent", "type", "bubbles", "cancelable", "eventPhase", "params")
		}
		
	}
}