package classes.replay
{
    import by.blooddy.crypto.MD5;
    import classes.User;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.ByteArray;
    import classes.replay.ReplayPack;

    public class Replay
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _loader:URLLoader;

        public var fileReplay:Boolean = false;

        public var replayBin:ByteArray;

        public var isLoaded:Boolean = false;
        public var isEdited:Boolean = false;
        public var isPreview:Boolean = false;
        public var generationReplayNotes:Array;
        public var needsBeatboxGeneration:Boolean = false;

        public var id:Number;
        public var user:User;
        public var level:int;
        public var settings:Object;
        public var score:Number;
        public var perfect:Number;
        public var good:Number;
        public var average:Number;
        public var miss:Number;
        public var boo:Number;
        public var maxcombo:Number;
        public var replayData:Array;
        public var timestamp:Number;

        public function Replay(id:Number, doLoad:Boolean = false)
        {
            this.id = id;

            if (doLoad)
                load();
        }

        private function load():void
        {
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(Constant.USER_LOAD_REPLAY_URL);
            var urlVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(urlVars);

            // Post Game Data
            urlVars.id = id;

            // Set Request
            req.data = urlVars;
            req.method = URLRequestMethod.POST;

            // Load
            _loader.load(req);
        }

        private function replayLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            var site_data:Object = JSON.parse(e.target.data);
            if (site_data.result != 1)
            {
                parseReplay(site_data);
            }
            else
            {
                isLoaded = true;
            }
        }

        private function replayLoadError(e:Event):void
        {
            removeLoaderListeners();
        }

        private function parseReplay(data:Object, loadUser:Boolean = true):void
        {
            if (data == null)
                return;

            var jsonSettings:Object;

            //- Level Details
            this.user = new User(loadUser, false, data.userid);
            this.user.addEventListener(GlobalVariables.LOAD_COMPLETE, userLoad);
            if (!loadUser)
                this.user.id = data.userid;
            this.level = data.replaylevelid;
            this.timestamp = data.timestamp;

            //- Score Data
            var tempScore:Array = data.replayscore.split("|");
            this.score = tempScore[0];
            this.perfect = tempScore[1];
            this.good = tempScore[2];
            this.average = tempScore[3]
            this.miss = tempScore[4];
            this.boo = tempScore[5];
            this.maxcombo = tempScore[6];
            this.score = (perfect * 50) + (good * 25) + (average * 5) - (miss * 10) - (boo * 5);

            //- Settings
            var tempSettings:* = data.replaysettings;

            // Legacy / Velo
            var mirrorIndex:int = -1;
            if (data.replayversion == "FFR")
            {
                tempSettings = tempSettings.split("|");
                jsonSettings = _gvars.playerUser.isGuest ? new User().settings : _gvars.playerUser.settings;
                jsonSettings.speed = Number(tempSettings[0]);
                jsonSettings.direction = Constant.cleanScrollDirection(tempSettings[2]);
                if (tempSettings.length >= 12)
                {
                    if (tempSettings[11] == "Mirror")
                    {
                        jsonSettings.visual.push("mirror");
                    }
                    else if ((mirrorIndex = jsonSettings.visual.indexOf("mirror")) >= 0)
                    {
                        jsonSettings.visual.splice(mirrorIndex, 1); // Remove Mirror is user had it set, but not in the replay.
                    }
                }
                jsonSettings.viewOffset = 0;
                jsonSettings.judgeOffset = 0;
                this.settings = jsonSettings;
            }
            else if (data.replayversion == "R^2")
            {
                tempSettings = tempSettings.split(",");
                for (var ss:int = 0; ss < tempSettings.length; ss++)
                {
                    tempSettings[ss] = tempSettings[ss].split("|");
                }
                jsonSettings = _gvars.playerUser.isGuest ? new User().settings : _gvars.playerUser.settings;
                jsonSettings.speed = Number(tempSettings[0][1]);
                jsonSettings.direction = Constant.cleanScrollDirection(tempSettings[0][0]);
                if (tempSettings[0][2] == "true")
                {
                    jsonSettings.visual.push("mirror");
                }
                else if ((mirrorIndex = jsonSettings.visual.indexOf("mirror")) >= 0)
                {
                    jsonSettings.visual.splice(mirrorIndex, 1); // Remove Mirror is user had it set, but not in the replay.
                }
                jsonSettings.gap = Number(tempSettings[2][0]);
                jsonSettings.noteskin = Number(tempSettings[2][3]);
                jsonSettings.viewOffset = 0;
                jsonSettings.judgeOffset = 0;
                this.settings = jsonSettings;
            }

            // R^3 Replay JSON
            else if (data.replayversion == "R^3")
            {
                this.settings = JSON.parse(data.replaysettings);
            }

            //- Frames
            var tempReplay:String = data.replayframes;
            replayData = [];

            //- Clean up
            // Legacy Replay Format ((LDUR),(FRAME)|), Handled in the Velo Converter
            if (tempReplay.indexOf(",") > -1)
            {
                tempReplay = tempReplay.replace(/,/g, "");
            }

            //- Conversion
            // Velocity Replay Format ((LDUR)(FRAME)|)
            if (tempReplay.indexOf("|") > -1)
            {
                parseVelocityReplay(tempReplay);
            }

            // R^2/3 Replay Format ((WXYZ)(FRAME))
            else if (tempReplay.charCodeAt(0) >= 87 && tempReplay.charCodeAt(0) <= 90)
            {
                parserRCubedReplay(tempReplay, data.replayversion);
            }
        }

        private function parseReplayPack(data:ReplayPacked, loadUser:Boolean = true):void
        {
            if (data == null)
                return;

            //- Level Details
            this.user = new User(loadUser, false, data.user_id);
            this.user.addEventListener(GlobalVariables.LOAD_COMPLETE, userLoad);
            if (!loadUser)
                this.user.id = data.user_id;
            this.level = data.song_id;
            this.timestamp = data.timestamp;

            //- Score Data
            this.perfect = (data.judgements["perfect"] + data.judgements["amazing"]);
            this.good = data.judgements["good"];
            this.average = data.judgements["average"];
            this.miss = data.judgements["miss"];
            this.boo = data.judgements["boo"];
            this.maxcombo = data.judgements["maxcombo"];
            this.score = (perfect * 50) + (good * 25) + (average * 5) - (miss * 10) - (boo * 5);

            this.settings = data.settings;

            //- Replay
            this.replayData = [];
            for each (var item:Object in data.rep_boos)
                this.replayData.push(new ReplayNote(item["d"], -2, item["t"]));

            //- Edited Check
            if (data.checksum != data.rechecksum)
                isEdited = true;

            this.replayBin = data.replay_bin;
            this.generationReplayNotes = data.rep_notes;
            this.needsBeatboxGeneration = true;
        }

        //// Parsers
        private function parseVelocityReplay(_input:String):void
        {
            var tempReplay:Array = _input.split("|");
            for (var x:int = 0; x < tempReplay.length; x++)
            {
                var dir:String = tempReplay[x].charAt(0);
                var frame:Number = uint("0x" + tempReplay[x].substr(1));
                replayData.push(new ReplayNote(dir, frame - 30));
            }

        }

        private function parserRCubedReplay(_input:String, _version:String):void
        {
            var offsetf:int = (_version == "R^2" ? 30 : 0);
            var totalReplay:int = 0;
            var lastFrame:int = 0;
            var noteVal:String = "";
            var noteDir:String = "";
            var game_curChar:String;
            var game_nexChar:String;
            for (var x:int = 0; x < _input.length; x++)
            {
                game_curChar = _input.charAt(x);
                game_nexChar = _input.charAt(x + 1);
                if (game_nexChar === false || game_nexChar == "" || game_nexChar == "W" || game_nexChar == "X" || game_nexChar == "Y" || game_nexChar == "Z")
                {
                    var dir:String = getDirCol(noteDir);
                    var frame:int = uint("0x" + noteVal + game_curChar) + lastFrame;
                    replayData.push(new ReplayNote(dir, frame - offsetf));
                    lastFrame = frame;
                }
                else if (game_curChar == "W" || game_curChar == "X" || game_curChar == "Y" || game_curChar == "Z")
                {
                    noteDir = game_curChar;
                    noteVal = "";
                }
                else
                {
                    noteVal += game_curChar;
                }
            }
        }

        /////
        private function getDirCol(noteDir:String):String
        {
            if (noteDir == "L")
                return "L";
            if (noteDir == "D")
                return "D";
            if (noteDir == "U")
                return "U";
            if (noteDir == "R")
                return "R";
            if (noteDir == "W")
                return "L";
            if (noteDir == "X")
                return "D";
            if (noteDir == "Y")
                return "U";
            if (noteDir == "Z")
                return "R";
            return noteDir;
        }

        private function userLoad(e:Event):void
        {
            this.user.removeEventListener(GlobalVariables.LOAD_COMPLETE, userLoad);
            this.user.settings = this.settings;
            isLoaded = true;
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, replayLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, replayLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, replayLoadError);
        }

        private function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, replayLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, replayLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, replayLoadError);
        }

        /////
        public function getPress(index:int):ReplayNote
        {
            return replayData[index];
        }

        public function getEncode(onlyBinReplay:Boolean = false):String
        {
            if (replayBin != null)
            {
                var enc:Base64Encoder = new Base64Encoder();
                enc.encodeBytes(replayBin);
                return ReplayPack.MAGIC + "|" + enc.toString();
            }

            if (!onlyBinReplay)
            {
                var sT:Number = (perfect * 550) + (good * 275) + (average * 55) + (maxcombo * 1000) - (miss * 310) - (boo * 20);
                var o:Object = {};
                o.userid = this.user.id;
                o.replaylevelid = this.level;
                o.replaysettings = JSON.stringify(this.settings);
                o.replayscore = (sT + "|" + perfect + "|" + good + "|" + average + "|" + miss + "|" + boo + "|" + maxcombo);
                o.replayframes = getReplayString(replayData);
                o.replayversion = "R^3";
                o.timestamp = timestamp;

                var outJson:String = JSON.stringify(o);
                return (outJson + "|" + MD5.hash(outJson + "|" + MD5.hash(outJson)));
            }

            return null;
        }

        public function parseEncode(str:String, loadUser:Boolean = true):void
        {
            try
            {
                if (str.substr(0, 4) == ReplayPack.MAGIC)
                {
                    var aa:String = str.substr(5);
                    var b64:Base64Decoder = new Base64Decoder();
                    b64.decode(aa);
                    parseReplayPack(ReplayPack.readReplay(b64.toByteArray()), loadUser);
                }
                else
                {
                    if (str.charAt(str.length - 33) == "|")
                    {
                        var md5:String = str.substr(str.length - 32);
                        str = str.substr(0, str.length - 33);
                        if (md5 != MD5.hash(str + "|" + MD5.hash(str)))
                        {
                            isEdited = true;
                        }
                    }
                    else
                    {
                        isEdited = true;
                    }
                    parseReplay(JSON.parse(str), loadUser);
                }
            }
            catch (e:Error)
            {
                trace(e);
            }
        }

        public function isValid():Boolean
        {
            return replayData != null;
        }

        public static function getReplayString(replay:Object):String
        {
            // Build Replay String
            var noteObj:ReplayNote;
            var lastDifference:int = 0;
            var replayString:String = "";
            for (var x:int = 0; x < replay.length; x++)
            {
                noteObj = replay[x];
                replayString += getReplayChar(noteObj.direction) + (noteObj.frame - lastDifference).toString(16).toUpperCase();
                lastDifference = noteObj.frame;
            }
            return replayString;
        }

        public static function getReplayChar(dir:String):String
        {
            if (dir == 'L')
                return 'W';
            if (dir == 'D')
                return 'X';
            if (dir == 'U')
                return 'Y';
            if (dir == 'R')
                return 'Z';
            return dir;
        }
    }
}
