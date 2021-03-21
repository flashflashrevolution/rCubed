package classes
{

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
        public var songID:int;
        public var status:int;
        public var statusLoading:int;
        public var gameScoreRecorded:Boolean;
        public var encodedReplay:String;

        public var room:Room;
        public var user:User;
        public var song:Object;

        /**
         * Only used in Velocity engine
         */
        public var userName:String;

        /**
         * Only used in Legacy engine
         */
        public var songName:String;

        public function Gameplay()
        {
        }
    }
}
