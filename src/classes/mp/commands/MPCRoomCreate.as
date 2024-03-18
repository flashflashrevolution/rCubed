package classes.mp.commands
{

    public class MPCRoomCreate implements IMPCommand
    {
        public var name:String;
        public var password:String;
        public var type:String;

        public var max_players:Number;
        public var team_count:Number;

        public function toJSON():String
        {
            var data:Object = {"type": type,
                    "name": name,
                    "password": password,
                    "team_count": team_count,
                    "max_players": max_players};

            return JSON.stringify({"t": "room",
                    "a": "create",
                    "d": data});
        }
    }
}
