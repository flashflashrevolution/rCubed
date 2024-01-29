package classes.mp.commands
{
    import classes.mp.room.MPRoom;

    public class MPCRoomEdit implements IMPCommand
    {
        public var room:MPRoom;

        public var name:String;
        public var password:String;

        public var team_count:Number;
        public var max_players:Number;

        public function MPCRoomEdit(room:MPRoom):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            var data:Object = {"uid": room.uid,
                    "name": name,
                    "password": password,
                    "team_count": team_count,
                    "max_players": max_players};

            return JSON.stringify({"t": "room",
                    "a": "edit",
                    "d": data});
        }
    }
}
