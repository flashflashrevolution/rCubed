package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRReadyForce implements IMPCommand
    {
        public var room:MPRoomFFR;

        public function MPCFFRReadyForce(room:MPRoomFFR):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "ready_force",
                    "d": {
                        "uid": room.uid
                    }});
        }
    }
}
