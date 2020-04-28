package it.gotoandplay.smartfoxserver.http
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	
	/**
	 * LoaderFactory class.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public class LoaderFactory
	{
		private static const DEFAULT_POOL_SIZE:int = 8
		
		private var loadersPool:Array
		private var currentLoaderIndex:int
		
		function LoaderFactory(responseHandler:Function, errorHandler:Function, poolSize:int = DEFAULT_POOL_SIZE)
		{
			loadersPool = []
			
			for (var i:int = 0; i < poolSize; i++)
			{
				var urlLoader:URLLoader = new URLLoader()
				urlLoader.dataFormat = URLLoaderDataFormat.TEXT
				urlLoader.addEventListener(Event.COMPLETE, responseHandler)
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler)
				urlLoader.addEventListener(IOErrorEvent.NETWORK_ERROR, errorHandler)
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler)
				
				loadersPool.push(urlLoader)
			}
			
			currentLoaderIndex = 0
		}
		
		public function getLoader():URLLoader
		{
			var urlLoader:URLLoader = loadersPool[currentLoaderIndex]
			
			currentLoaderIndex++
			
			if (currentLoaderIndex >= loadersPool.length)
				currentLoaderIndex = 0
			
			return urlLoader
		}
	}
}