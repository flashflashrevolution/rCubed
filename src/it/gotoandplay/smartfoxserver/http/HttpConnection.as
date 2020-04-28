package it.gotoandplay.smartfoxserver.http
{
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	
	/**
	 * HttpConnection class.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public class HttpConnection extends EventDispatcher
	{
		private static const HANDSHAKE:String = "connect"
		private static const DISCONNECT:String = "disconnect"
		private static const CONN_LOST:String = "ERR#01"
		
		public static const HANDSHAKE_TOKEN:String = "#"
		
		private static const servletUrl:String = "BlueBox/HttpBox.do"
		private static const paramName:String = "sfsHttp"
		
		private var sessionId:String;
		private var connected:Boolean = false
		private var ipAddr:String
		private var port:int
		private var webUrl:String
		private var urlLoaderFactory:LoaderFactory
		private var urlRequest:URLRequest
		
		private var codec:IHttpProtocolCodec
		
		function HttpConnection()
		{
			codec = new RawProtocolCodec()
			urlLoaderFactory = new LoaderFactory(handleResponse, handleIOError)
		}
		
		public function getSessionId():String
		{
			return this.sessionId
		}
		
		public function isConnected():Boolean
		{
			return this.connected
		}
		
		public function connect(addr:String, port:int = 8080):void
		{
			this.ipAddr = addr
			this.port = port
			this.webUrl = "http://" + this.ipAddr + ":" + this.port + "/" + servletUrl
			this.sessionId = null
			urlRequest = new URLRequest(webUrl)
			urlRequest.method = URLRequestMethod.POST
			
			send( HANDSHAKE )	
		}
		
		public function close():void
		{
			send( DISCONNECT )
		}
		
		public function send(message:String):void
		{
			if (connected || (!connected && message == HANDSHAKE) || (!connected && message == "poll"))
			{				
				var vars:URLVariables = new URLVariables()
				vars[paramName] = codec.encode(this.sessionId, message)
				
				urlRequest.data = vars
				
				if (message != "poll")
					trace("[ Send ]: " + urlRequest.data)
				
				var urlLoader:URLLoader = urlLoaderFactory.getLoader()
				urlLoader.data = vars
				urlLoader.load(urlRequest)
			}
		}
		
		private function handleResponse(evt:Event):void
		{
			var loader:URLLoader = evt.target as URLLoader
			var data:String = loader.data as String

			var event:HttpEvent
			var params:Object = {}
			
			// handle handshake
			if (data.charAt(0) == HANDSHAKE_TOKEN)
			{
				// Init the sessionId
				if (sessionId == null)
				{
					sessionId = codec.decode(data)
					connected = true
					
					params.sessionId = this.sessionId
					params.success = true
					
					event = new HttpEvent(HttpEvent.onHttpConnect, params)
					dispatchEvent(event)
				}
				else
				{
					// Error, session already exist and cannot be redefined!
					trace("**ERROR** SessionId is being rewritten")
				}
			}
			
			// handle data
			else
			{
				// fire disconnection
				if (data.indexOf(CONN_LOST) == 0)
				{
					params.data = {}
					event = new HttpEvent(HttpEvent.onHttpClose, params)
				}
				
				// fire onHttpData
				else
				{
					params.data = data
					event = new HttpEvent(HttpEvent.onHttpData, params)
				}
				
				dispatchEvent(event)
			}	 
		}
		
		private function handleIOError(error:IOErrorEvent):void
		{
			var params:Object = {}
			params.message = error.text
			
			var event:HttpEvent = new HttpEvent(HttpEvent.onHttpError, params)
			
			dispatchEvent(event)
		}
	}
}