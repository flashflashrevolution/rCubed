package game
{
    import arc.ArcGlobals;
    import classes.Room;
    import classes.User;
    import classes.chart.Song;
    import classes.replay.Replay;

    public class GameOptions extends Object
    {
        public var DISABLE_NOTE_POOL:Boolean = false;

        public var frameRate:int = 60;
        public var songRate:Number = 1;

        public var scrollDirection:String = "up";
        public var judgeSpeed:Number = 1;
        public var scrollSpeed:Number = 1.5;
        public var receptorSpacing:int = 80;
        public var receptorSpeed:Number = 1;
        public var noteScale:Number = 1;
        public var judgeScale:Number = 1;
        public var screencutPosition:Number = 0.5;
        public var mods:Array = [];
        public var noteskin:int = 1;

        public var offsetGlobal:Number = 0;
        public var offsetJudge:Number = 0;
        public var autoJudgeOffset:Boolean = false;

        public var displayGameTopBar:Boolean = true;
        public var displayGameBottomBar:Boolean = true;
        public var displayJudge:Boolean = true;
        public var displayJudgeAnimations:Boolean = true;
        public var displayReceptorAnimations:Boolean = true;
        public var displayHealth:Boolean = true;
        public var displayScore:Boolean = true;
        public var displayCombo:Boolean = true;
        public var displayRawGoods:Boolean = false;
        public var displayComboTotal:Boolean = true;
        public var displayAccuracyBar:Boolean = true;
        public var displayPA:Boolean = true;
        public var displayAmazing:Boolean = true;
        public var displayPerfect:Boolean = true;
        public var displayScreencut:Boolean = false;
        public var displaySongProgress:Boolean = true;
        public var displaySongProgressText:Boolean = false;

        public var displayMPUI:Boolean = true;
        public var displayMPJudge:Boolean = true;
        public var displayMPPA:Boolean = true;
        public var displayMPCombo:Boolean = true;
        public var displayMPRawGoods:Boolean = false;

        public var judgeColors:Array = [0x78ef29, 0x12e006, 0x01aa0f, 0xf99800, 0xfe0000, 0x804100];
        public var comboColors:Array = [0x0099CC, 0x00AD00, 0xFCC200, 0xC7FB30, 0x6C6C6C, 0xF99800, 0xB06100, 0x990000, 0xDC00C2]; // Normal, FC, AAA, SDG, BlackFlag, AvFlag, BooFlag, MissFlag, RawGood
        public var enableComboColors:Vector.<Boolean> = new <Boolean>[true, true, true, false, false, false, false, false, false];
        public var receptorColors:Array = [0xFFFFFF, 0xFFFFFF, 0x64FF64, 0xFFFF00, 0xBB8500, 0xA80000];
        public var enableReceptorColors:Vector.<Boolean> = new <Boolean>[true, true, true, true, true, false];
        public var gameColors:Array = [0x1495BD, 0x033242, 0x0C6A88, 0x074B62, 0x000000];
        public var noteDirections:Array = ["D", "L", "U", "R"];
        public var noteColors:Array = ["red", "blue", "purple", "yellow", "pink", "orange", "cyan", "green", "white"];
        public var noteSwapColors:Object = {"red": "red", "blue": "blue", "purple": "purple", "yellow": "yellow", "pink": "pink", "orange": "orange", "cyan": "cyan", "green": "green", "white": "white"};
        public var rawGoodTracker:Number = 0;
        public var rawGoodsColor:Number = 0xDC00C2;

        public var layout:Object = {};

        public var judgeWindow:Array = null;

        public var song:Song = null;
        public var replay:Replay = null;
        public var isEditor:Boolean = false;
        public var isAutoplay:Boolean = false;
        public var mpRoom:Room = null;
        public var singleplayer:Boolean = false;
        public var autofail:Array = [0, 0, 0, 0, 0, 0, 0];
        public var autofail_restart:Boolean = false;

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

            scrollDirection = user.slideDirection;
            judgeSpeed = user.judgeSpeed;
            scrollSpeed = user.gameSpeed;
            receptorSpacing = user.receptorGap;
            receptorSpeed = user.receptorSpeed;
            noteScale = user.noteScale;
            judgeScale = user.judgeScale;
            screencutPosition = user.screencutPosition;
            mods = user.activeMods.concat(user.activeVisualMods);
            modCache = null;
            noteskin = user.activeNoteskin;

            offsetGlobal = user.GLOBAL_OFFSET;
            offsetJudge = user.JUDGE_OFFSET;
            autoJudgeOffset = user.AUTO_JUDGE_OFFSET;

            displayJudge = user.DISPLAY_JUDGE;
            displayJudgeAnimations = user.DISPLAY_JUDGE_ANIMATIONS;
            displayReceptorAnimations = user.DISPLAY_RECEPTOR_ANIMATIONS;
            displayHealth = user.DISPLAY_HEALTH;
            displayGameTopBar = user.DISPLAY_GAME_TOP_BAR;
            displayGameBottomBar = user.DISPLAY_GAME_BOTTOM_BAR;
            displayScore = user.DISPLAY_SCORE;
            displayCombo = user.DISPLAY_COMBO;
            displayRawGoods = user.DISPLAY_RAWGOODS;
            displayComboTotal = user.DISPLAY_TOTAL;
            displayPA = user.DISPLAY_PACOUNT;
            displayAccuracyBar = user.DISPLAY_ACCURACY_BAR;
            displayAmazing = user.DISPLAY_AMAZING;
            displayPerfect = user.DISPLAY_PERFECT;
            displayScreencut = user.DISPLAY_SCREENCUT;
            displaySongProgress = user.DISPLAY_SONGPROGRESS;
            displaySongProgressText = user.DISPLAY_SONGPROGRESS_TEXT;

            displayMPUI = user.DISPLAY_MP_UI;
            displayMPPA = user.DISPLAY_MP_PA;
            displayMPJudge = user.DISPLAY_MP_JUDGE;
            displayMPCombo = user.DISPLAY_MP_COMBO;
            displayMPRawGoods = user.DISPLAY_MP_RAWGOODS;

            judgeColors = user.judgeColors.concat();
            comboColors = user.comboColors.concat();
            enableComboColors = user.enableComboColors.concat();
            receptorColors = user.receptorColors.concat();
            enableReceptorColors = user.enableReceptorColors.concat();
            gameColors = user.gameColors.concat();
            rawGoodTracker = user.rawGoodTracker;
            rawGoodsColor = user.rawGoodsColor;

            for (var i:int = 0; i < noteColors.length; i++)
            {
                noteSwapColors[noteColors[i]] = user.noteColors[i];
            }

            autofail = [user.autofailAmazing,
                user.autofailPerfect,
                user.autofailGood,
                user.autofailAverage,
                user.autofailMiss,
                user.autofailBoo,
                user.autofailRawGoods];

            autofail_restart = user.autofailRestart;
        }

        public function fillFromArcGlobals():void
        {
            var avars:ArcGlobals = ArcGlobals.instance;

            isolationOffset = avars.configIsolationStart;
            isolationLength = avars.configIsolationLength;

            var layoutKey:String = mpRoom ? (mpRoom.connection.currentUser.isPlayer ? "mp" : "mpspec") : "sp";
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

            var i:int;
            var settings:Object = r.settings;

            frameRate = settings["frameRate"] || 30;
            songRate = settings["songRate"] || 1;

            scrollDirection = settings["direction"] || "up";
            judgeSpeed = settings["judgeSpeed"] || 1;
            scrollSpeed = settings["speed"] || 1.5;
            receptorSpacing = settings["gap"] || 80;
            noteScale = settings["noteScale"] || 1;
            judgeScale = settings["judgeScale"] || 1;
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
            displayRawGoods = settings["viewRawGoods"];
            displayComboTotal = settings["viewTotal"];
            displayPA = settings["viewPACount"];
            displayAmazing = settings["viewAmazing"];
            displayPerfect = settings["viewPerfect"];
            displayScreencut = settings["viewScreencut"];
            displaySongProgress = settings["viewSongProgress"];
            displaySongProgressText = settings["viewSongProgressText"];

            if (settings["viewScore"] != null)
                displayScore = settings["viewScore"];
            if (settings["viewGameTopBar"] != null)
                displayGameTopBar = settings["viewGameTopBar"];
            if (settings["viewGameBottomBar"] != null)
                displayGameBottomBar = settings["viewGameBottomBar"];

            if (settings["viewJudgeAnimations"] != null)
                displayJudgeAnimations = settings["viewJudgeAnimations"];
            if (settings["viewReceptorAnimations"] != null)
                displayReceptorAnimations = settings["viewReceptorAnimations"];

            if (settings["noteSwapColours"] != null)
            {
                for (i = 0; i < noteColors.length; i++)
                {
                    noteSwapColors[noteColors[i]] = settings["noteSwapColours"][i];
                }
            }

            if (settings["judgeColors"] != null)
            {
                for (i = 0; i < judgeColors.length; i++)
                {
                    judgeColors[i] = settings["judgeColors"][i];
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
            var i:int;
            var settings:Object = new Object();
            settings["viewOffset"] = offsetGlobal;
            settings["judgeOffset"] = offsetJudge;
            settings["autoJudgeOffset"] = autoJudgeOffset;
            settings["viewJudge"] = displayJudge;
            settings["viewJudgeAnimations"] = displayJudgeAnimations;
            settings["viewReceptorAnimations"] = displayReceptorAnimations;
            settings["viewHealth"] = displayHealth;
            settings["viewScore"] = displayScore;
            settings["viewCombo"] = displayCombo;
            settings["viewRawGoods"] = displayRawGoods;
            settings["viewTotal"] = displayComboTotal;
            settings["viewPACount"] = displayPA;
            settings["viewAmazing"] = displayAmazing;
            settings["viewPerfect"] = displayPerfect;
            settings["viewScreencut"] = displayScreencut;
            settings["viewSongProgress"] = displaySongProgress;
            settings["viewSongProgressText"] = displaySongProgressText;
            settings["viewGameTopBar"] = displayGameTopBar;
            settings["viewGameBottomBar"] = displayGameBottomBar;
            settings["speed"] = scrollSpeed;
            settings["judgeSpeed"] = judgeSpeed;
            settings["receptorSpeed"] = receptorSpeed;
            settings["direction"] = scrollDirection;
            settings["noteskin"] = noteskin;
            settings["gap"] = receptorSpacing;
            settings["noteScale"] = noteScale;
            settings["judgeScale"] = judgeScale;
            settings["screencutPosition"] = screencutPosition;
            settings["frameRate"] = frameRate;
            settings["songRate"] = songRate;
            settings["visual"] = mods;

            if (isolation)
            {
                settings["isolationOffset"] = isolationOffset;
                settings["isolationLength"] = isolationLength;
            }

            settings["noteSwapColours"] = [];
            for (i = 0; i < noteColors.length; i++)
            {
                settings["noteSwapColours"][i] = noteSwapColors[noteColors[i]];
            }
            settings["judgeColors"] = [];
            for (i = 0; i < judgeColors.length; i++)
            {
                settings["judgeColors"][i] = judgeColors[i];
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
            return noteSwapColors[color];
        }
    }
}
