package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRGameModifiers implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var mods:Object;

        public function MPCFFRGameModifiers(room:MPRoomFFR, mods:Object)
        {
            this.room = room;
            this.mods = mods;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "game_mods",
                    "d": {
                        "uid": room.uid,
                        "mods": mods
                    }});
        }
    }
}
