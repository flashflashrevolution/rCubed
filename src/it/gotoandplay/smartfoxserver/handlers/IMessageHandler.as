package it.gotoandplay.smartfoxserver.handlers
{
	/**
	 * Handlers interface.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public interface IMessageHandler
	{
		function handleMessage(msgObj:Object, type:String):void
	}
}