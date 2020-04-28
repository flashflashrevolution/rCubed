package it.gotoandplay.smartfoxserver.handlers
{
	import it.gotoandplay.smartfoxserver.SmartFoxClient;
	import it.gotoandplay.smartfoxserver.util.ObjectSerializer;
	import it.gotoandplay.smartfoxserver.SFSEvent;
	
	/**
	 * ExtHandler class.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public class ExtHandler implements IMessageHandler
	{
		private var sfs:SmartFoxClient
		
		function ExtHandler(sfs:SmartFoxClient)
		{
			this.sfs = sfs	
		}
		
		/**
		 * Handle messages
		 */
	 	public function handleMessage(msgObj:Object, type:String):void
		{
			var params:Object
			var evt:SFSEvent
			
			if (type == SmartFoxClient.XTMSG_TYPE_XML)
			{
				var xmlData:XML = msgObj as XML
				var action:String = xmlData.body.@action
				var roomId:int = int(xmlData.body.@id)
				
				if (action == "xtRes")
				{
					var xmlStr:String = xmlData.body.toString()
					var asObj:Object = ObjectSerializer.getInstance().deserialize(xmlStr)
					
					// Fire event!
					params = {}
					params.dataObj = asObj
					params.type = type
					
					evt = new SFSEvent(SFSEvent.onExtensionResponse, params)
					sfs.dispatchEvent(evt)
				}
			}

			else if (type == SmartFoxClient.XTMSG_TYPE_JSON)
			{
				// Fire event!
				params = {}
				params.dataObj = msgObj.o
				params.type = type

				evt = new SFSEvent(SFSEvent.onExtensionResponse, params)
				sfs.dispatchEvent(evt)
			}
			
			else if (type == SmartFoxClient.XTMSG_TYPE_STR)
			{
				// Fire event!
				params = {}
				params.dataObj = msgObj
				params.type = type

				evt = new SFSEvent(SFSEvent.onExtensionResponse, params)
				sfs.dispatchEvent(evt)
			}
		}
	}
}