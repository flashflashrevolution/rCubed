package it.gotoandplay.smartfoxserver.http
{
	/**
	 * IHttpProtocolCodec interface.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public interface IHttpProtocolCodec
	{
		function encode(sessionId:String, message:String):String
		function decode(message:String):String
	}
}