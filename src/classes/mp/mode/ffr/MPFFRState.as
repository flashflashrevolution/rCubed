package classes.mp.mode.ffr
{
    import classes.mp.MPUser;
    import classes.mp.room.MPRoomFFR;

    public class MPFFRState
    {
        public var user:MPUser;
        public var room:MPRoomFFR;

        public var game_state:String; // ["menu", "loading", "game", "waiting", "results"]
        public var playable_state:int = 0;
        public var ready_state:Boolean = false;
        public var loading_state:Boolean = false;
        public var loading_percent:Number = 0;

        public var song_rate:Number = 1;

        public var settings:Object = null;
        public var layout:Object = null;
        public var noteskin:String = null;
        public var replay_buffer:Array = [];

        public function MPFFRState(room:MPRoomFFR, user:MPUser):void
        {
            this.room = room;
            this.user = user;
        }

        public function update(data:Object):void
        {
            if (data.playable_state != undefined)
                playable_state = data.playable_state;

            if (data.ready_state != undefined)
                ready_state = data.ready_state;

            if (data.game_state != undefined)
                game_state = data.game_state;

            if (data.loading_state != undefined)
                loading_state = data.loading_state;

            if (data.ready_state != undefined)
                ready_state = data.ready_state;

            if (data.loading_percent != undefined)
                loading_percent = data.loading_percent;

            if (data.song_rate != undefined)
                song_rate = data.song_rate;

            if (data.settings != undefined)
                settings = data.settings;

            if (data.layout != undefined)
                layout = data.layout;

            if (data.noteskin != undefined)
                noteskin = data.noteskin;
        }
    }
}
