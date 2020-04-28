package it.gotoandplay.smartfoxserver.data
{
	import it.gotoandplay.smartfoxserver.data.*
	
	/**
	 * The Zone class stores the properties of the current server zone.
	 * This class is used internally by the {@link SmartFoxClient} class.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 * 
	 * @exclude
	 */
	public class Zone
	{
		private var roomList:Array
		private var name:String
		
		public function Zone(name:String)
		{
			this.name = name
			this.roomList = []
		}
		
		public function getRoom(id:int):Room
		{
			return (roomList[id] as Room) 
		}
		
		public function getRoomByName(name:String):Room
		{
			var room:Room = null
			var found:Boolean = false
			
			for (var key:String in roomList)
			{
				room = roomList[key] as Room
				
				if (room.getName() == name)
				{
					found = true
					break
				}	
			}
			
			if (found)
				return room
			else
				return null
		}
	}
}