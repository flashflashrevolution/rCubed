package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSong implements IMPCommand
    {
        public var room:MPRoomFFR;

        public var type:String;
        public var id:uint;
        public var level_id:String;

        public var name:String;
        public var author:String;
        public var time:String;
        public var note_count:Number;
        public var difficulty:Number;

        public var engine:Object;


        public function MPCFFRSong(room:MPRoomFFR):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            var data:Object = {"uid": room.uid,
                    "type": type,
                    "id": id,
                    "level_id": level_id,
                    "name": name,
                    "author": author,
                    "time": time,
                    "note_count": note_count,
                    "difficulty": difficulty,
                    "engine": engine};

            return JSON.stringify({"t": "mode",
                    "a": "song",
                    "d": data});
        }
    }
}
