package classes
{

    import com.flashfla.net.Multiplayer;

    public class Gameplay
    {
        public var amazing:int;
        public var perfect:int;
        public var good:int;
        public var average:int;
        public var miss:int;
        public var boo:int;
        public var combo:int;
        public var maxCombo:int;

        public var life:int;
        public var score:int;

        public var status:int;
        public var statusLoading:int;
        public var encodedReplay:String;

        public var songId:int;
        public var songInfo:SongInfo;

        // Flags
        public var statusChanged:Boolean = false;

        /**
         * Only used in Legacy engine
         */
        public var songName:String;

        public function Gameplay()
        {
        }

        public function reset():void
        {
            amazing = 0;
            perfect = 0;
            good = 0;
            average = 0;
            miss = 0;
            boo = 0;
            combo = 0;
            maxCombo = 0;

            life = 0;
            score = 0;

            songInfo = null;
            songId = NaN;

            status = Multiplayer.STATUS_NONE;
            statusLoading = 0;

            statusChanged = false;
        }

        public function setStatus(status:int):void
        {
            this.status = status;
            statusChanged = true;
        }
    }
}
