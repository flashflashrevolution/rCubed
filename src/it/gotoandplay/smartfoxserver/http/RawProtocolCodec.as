package it.gotoandplay.smartfoxserver.http
{
	/**
	 * RawProtocolCodec class.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public class RawProtocolCodec implements IHttpProtocolCodec
	{
		private static const SESSION_ID_LEN:int = 32
		
		public function encode(sessionId:String, message:String):String
		{
			return ((sessionId == null ? "" : sessionId) + message)
		}
		
		public function decode(message:String):String
		{
			var decoded:String
			
			// Decode the connect response
			if (message.charAt(0) == HttpConnection.HANDSHAKE_TOKEN)
			{
				decoded = message.substr(1, SESSION_ID_LEN)		
			}
			
			return decoded
		}
	}
}