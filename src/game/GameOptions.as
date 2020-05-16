package game
{
    import classes.User;
    import classes.chart.Song;
    import classes.replay.Replay;
    import arc.ArcGlobals;

    public class GameOptions extends Object
    {
        public var DISABLE_NOTE_POOL:Boolean = false;

        public var frameRate:int = 60;
        public var songRate:Number = 1;

        public var scrollDirection:String = "up";
        public var scrollSpeed:Number = 1.5;
        public var receptorSpacing:int = 80;
        public var noteScale:Number = 1;
        public var screencutPosition:Number = 0.5;
        public var mods:Array = [];
        public var noteskin:int = 1;

        public var offsetGlobal:Number = 0;
        public var offsetJudge:Number = 0;
        public var autoJudgeOffset:Boolean = false;

        public var forceNewJudge:Boolean = false;

        public var displayGameTopBar:Boolean = true;
        public var displayGameBottomBar:Boolean = true;
        public var displayJudge:Boolean = true;
        public var displayHealth:Boolean = true;
        public var displayScore:Boolean = true;
        public var displayCombo:Boolean = true;
        public var displayComboTotal:Boolean = true;
        public var displayPA:Boolean = true;
        public var displayAmazing:Boolean = true;
        public var displayPerfect:Boolean = true;
        public var displayScreencut:Boolean = false;
        public var displaySongProgress:Boolean = true;

        public var displayMP:Boolean = true;
        public var displayMPJudge:Boolean = true;
        public var displayMPPA:Boolean = true;
        public var displayMPCombo:Boolean = true;

        public var judgeColours:Array = [0x78ef29, 0x12e006, 0x01aa0f, 0xf99800, 0xfe0000, 0x804100];
        public var comboColours:Array = [0x0099CC, 0x00AD00, 0xFCC200];
        public var gameColours:Array = [0x1495BD, 0x033242, 0x0C6A88, 0x074B62];
        public var noteDirections:Array = ["D", "L", "U", "R"];
        public var noteColors:Array = ["red", "blue", "purple", "yellow", "pink", "orange", "cyan", "green", "white"];
        public var noteSwapColours:Object = {"red": "red", "blue": "blue", "purple": "purple", "yellow": "yellow", "pink": "pink", "orange": "orange", "cyan": "cyan", "green": "green", "white": "white"};

        public var layout:Object = {};

        public var judgeWindow:Array = null;

        public var song:Song = null;
        public var replay:Replay = null;
        public var loadPreview:Boolean = false;
        public var isEditor:Boolean = false;
        public var isAutoplay:Boolean = false;
        public var multiplayer:Object = null;
        public var singleplayer:Boolean = false;
        public var autofail:Array = [0, 0, 0, 0, 0, 0, 0];

        public var isolationOffset:int = 0;
        public var isolationLength:int = 0;

        public function get isolation():Boolean
        {
            return isolationOffset > 0 || isolationLength > 0;
        }

        public function set isolation(value:Boolean):void
        {
            if (!value)
                isolationOffset = isolationLength = 0;
        }

        public function fillFromUser(user:User):void
        {
            frameRate = user.frameRate;
            songRate = user.songRate;
            forceNewJudge = user.forceNewJudge;

            scrollDirection = user.slideDirection;
            scrollSpeed = user.gameSpeed;
            receptorSpacing = user.receptorGap;
            noteScale = user.noteScale;
            screencutPosition = user.screencutPosition;
            mods = user.activeMods.concat(user.activeVisualMods);
            modCache = null;
            noteskin = user.activeNoteskin;

            offsetGlobal = user.GLOBAL_OFFSET;
            offsetJudge = user.JUDGE_OFFSET;
            autoJudgeOffset = user.AUTO_JUDGE_OFFSET;

            displayJudge = user.DISPLAY_JUDGE;
            displayHealth = user.DISPLAY_HEALTH;
            displayGameTopBar = user.DISPLAY_GAME_TOP_BAR;
            displayGameBottomBar = user.DISPLAY_GAME_BOTTOM_BAR;
            displayScore = user.DISPLAY_SCORE;
            displayCombo = user.DISPLAY_COMBO;
            displayComboTotal = user.DISPLAY_TOTAL;
            displayPA = user.DISPLAY_PACOUNT;
            displayAmazing = user.DISPLAY_AMAZING;
            displayPerfect = user.DISPLAY_PERFECT;
            displayScreencut = user.DISPLAY_SCREENCUT;
            displaySongProgress = user.DISPLAY_SONGPROGRESS;
            displayMP = !user.DISPLAY_MP_MASK;

            judgeColours = user.judgeColours.concat();
            comboColours = user.comboColours.concat();
            gameColours = user.gameColours.concat();

            for (var i:int = 0; i < noteColors.length; i++)
            {
                noteSwapColours[noteColors[i]] = user.noteColours[i];
            }

            autofail = [user.autofailAmazing,
                user.autofailPerfect,
                user.autofailGood,
                user.autofailAverage,
                user.autofailMiss,
                user.autofailBoo,
                user.autofailRawGoods];
        }

        public function fillFromArcGlobals():void
        {
            var avars:ArcGlobals = ArcGlobals.instance;

            isolationOffset = avars.configIsolationStart;
            isolationLength = avars.configIsolationLength;

            var layoutKey:String = multiplayer ? (multiplayer.user.isPlayer ? "mp" : "mpspec") : "sp";
            if (!avars.configInterface[layoutKey])
                avars.configInterface[layoutKey] = {};
            layout = avars.configInterface[layoutKey];
            layoutKey = scrollDirection;
            if (!layout[layoutKey])
                layout[layoutKey] = {};
            layout = layout[layoutKey];

            judgeWindow = avars.configJudge;
        }

        public function fillFromReplay(r:Object = null):void
        {
            if (!r)
                r = replay;
            if (!r)
                return;

            var settings:Object = r.settings;

            frameRate = settings["frameRate"] || 30;
            songRate = settings["songRate"] || 1;
            forceNewJudge = settings["forceNewJudge"] || false;

            scrollDirection = settings["direction"] || "up";
            scrollSpeed = settings["speed"] || 1.5;
            receptorSpacing = settings["gap"] || 80;
            noteScale = settings["noteScale"] || 1;
            screencutPosition = settings["screencutPosition"] || 0;
            mods = settings["visual"] || [];
            modCache = null;
            noteskin = settings["noteskin"] || 1;

            offsetGlobal = settings["viewOffset"] || 0;
            offsetJudge = settings["judgeOffset"] || 0;
            autoJudgeOffset = settings["autoJudgeOffset"] || false;

            isolationOffset = settings["isolationOffset"] || 0;
            isolationLength = settings["isolationLength"] || 0;

            displayJudge = settings["viewJudge"];
            displayHealth = settings["viewHealth"];
            displayCombo = settings["viewCombo"];
            displayComboTotal = settings["viewTotal"];
            displayPA = settings["viewPACount"];
            displayAmazing = settings["viewAmazing"];
            displayPerfect = settings["viewPerfect"];
            displayScreencut = settings["viewScreencut"];
            displaySongProgress = settings["viewSongProgress"];

            // New - November 2016 Update
            if (settings["viewScore"] != null)
                displayScore = settings["viewScore"];
            if (settings["viewGameTopBar"] != null)
                displayGameTopBar = settings["viewGameTopBar"];
            if (settings["viewGameBottomBar"] != null)
                displayGameBottomBar = settings["viewGameBottomBar"];

            if (settings["noteSwapColours"] != null)
            {
                for (var i:int = 0; i < noteColors.length; i++)
                {
                    noteSwapColours[noteColors[i]] = settings["noteSwapColours"][i];
                }
            }
        }

        public function fill():void
        {
            fillFromUser(GlobalVariables.instance.activeUser);
            fillFromArcGlobals();
        }

        public var modCache:Object = null;

        public function modEnabled(mod:String):Boolean
        {
            if (!modCache)
            {
                modCache = new Object();
                for each (var gameMod:String in mods)
                    modCache[gameMod] = true;
            }
            return mod in modCache;
        }

        public function settingsEncode():Object
        {
            var settings:Object = new Object();
            settings["viewOffset"] = offsetGlobal;
            settings["judgeOffset"] = offsetJudge;
            settings["autoJudgeOffset"] = autoJudgeOffset;
            settings["viewJudge"] = displayJudge;
            settings["viewHealth"] = displayHealth;
            settings["viewScore"] = displayScore;
            settings["viewCombo"] = displayCombo;
            settings["viewTotal"] = displayComboTotal;
            settings["viewPACount"] = displayPA;
            settings["viewAmazing"] = displayAmazing;
            settings["viewPerfect"] = displayPerfect;
            settings["viewScreencut"] = displayScreencut;
            settings["viewSongProgress"] = displaySongProgress;
            settings["speed"] = scrollSpeed;
            settings["direction"] = scrollDirection;
            settings["noteskin"] = noteskin;
            settings["gap"] = receptorSpacing;
            settings["noteScale"] = noteScale;
            settings["screencutPosition"] = screencutPosition;
            settings["forceNewJudge"] = forceNewJudge;
            settings["frameRate"] = frameRate;
            settings["songRate"] = songRate;
            settings["visual"] = mods;


            if (isolation)
            {
                settings["isolationOffset"] = isolationOffset;
                settings["isolationLength"] = isolationLength;
            }

            // New - November 2016 Update
            settings["viewGameTopBar"] = displayGameTopBar;
            settings["viewGameBottomBar"] = displayGameBottomBar;
            settings["noteSwapColours"] = [];
            for (var i:int = 0; i < noteColors.length; i++)
            {
                settings["noteSwapColours"][i] = noteSwapColours[noteColors[i]];
            }

            var user:User = GlobalVariables.instance.activeUser;
            settings["keys"] = [user.keyLeft, user.keyDown, user.keyUp, user.keyRight, user.keyRestart, user.keyQuit, user.keyOptions];

            return settings;
        }

        public function isScoreValid(score:Boolean = true, replay:Boolean = true):Boolean
        {
            var ret:Boolean = false;
            ret ||= score && (isAutoplay ||
                //modEnabled("shuffle") ||
                //modEnabled("random") ||
                //modEnabled("scramble") ||
                judgeWindow);
            ret ||= replay && ( //songRate != 1 ||
                modEnabled("reverse") ||
                //modEnabled("nobackground") ||
                isolation);
            return !ret;
        }

        public function isScoreUpdated(score:Boolean = true, replay:Boolean = true):Boolean
        {
            var ret:Boolean = false;
            ret ||= score && (isAutoplay || modEnabled("shuffle") || modEnabled("random") || modEnabled("scramble") || judgeWindow);
            ret ||= replay && (songRate != 1 || modEnabled("reverse") //||
                //modEnabled("nobackground") ||
                //isolation
                );
            return !ret;
        }

        public function getNewNoteColor(color:String):String
        {
            return noteSwapColours[color];
        }
    }
}
