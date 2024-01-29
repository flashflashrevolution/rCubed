package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSongStart implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var settings:Object;
        public var layout:Object;
        public var noteskin:String;

        public function MPCFFRSongStart(room:MPRoomFFR, settings:Object, layout:Object, noteskin:String)
        {
            this.room = room;
            this.settings = settings;
            this.layout = layout;
            this.noteskin = noteskin;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "song_start",
                    "d": {
                        "uid": room.uid,
                        "settings": settings,
                        "layout": layout,
                        "noteskin": noteskin
                    }});
        }
    }
}
