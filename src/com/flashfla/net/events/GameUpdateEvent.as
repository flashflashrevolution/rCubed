package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class GameUpdateEvent extends TypedSFSEvent
    {
        public var room:Object;
        public var user:Object;
        public var gameScore:int;
        public var gameLife:int;
        public var hitMaxCombo:int;
        public var hitCombo:int;
        public var hitAmazing:int;
        public var hitPerfect:int;
        public var hitGood:int;
        public var hitAverage:int;
        public var hitMiss:int;
        public var hitBoo:int;

        public function GameUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_GAME_UPDATE);
            room = params.room;
            user = params.user;
            gameScore = params.gameScore;
            gameLife = params.gameLife;
            hitMaxCombo = params.hitMaxCombo;
            hitCombo = params.hitCombo;
            hitAmazing = params.hitAmazing;
            hitPerfect = params.hitPerfect;
            hitGood = params.hitGood;
            hitAverage = params.hitAverage;
            hitMiss = params.hitMiss;
            hitBoo = params.hitBoo;
        }
    }
}
