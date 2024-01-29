
package classes.mp.commands
{
    import classes.mp.MPUser;
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRPlaybackRequest implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var user:MPUser;
        public var index:uint;

        public function MPCFFRPlaybackRequest(room:MPRoomFFR, user:MPUser, index:uint)
        {
            this.room = room;
            this.user = user;
            this.index = index;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "playback_request",
                    "d": {
                        "uid": room.uid,
                        "userUID": user.uid,
                        "index": index
                    }});
        }
    }
}
