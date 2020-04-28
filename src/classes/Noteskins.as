package classes
{
    import classes.replay.Base64Decoder;
    import com.flashfla.utils.ObjectUtil;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.geom.Matrix;
    import flash.display.Sprite;

    public class Noteskins extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:Noteskins = null;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _loader:URLLoader;
        private var _isLoaded:Boolean = false;
        private var _isLoading:Boolean = false;
        private var _loadError:Boolean = false;
        private var _swfloaders:Array; // Vector.<DynamicLoader>;
        private var _data:Object;

        public var totalNoteskins:int = 1;
        public var totalLoaded:int = 0;

        ///- Constructor
        public function Noteskins(en:SingletonEnforcer)
        {
            if (en == null)
                throw Error("Multi-Instance Blocked");
        }

        public static function get instance():Noteskins
        {
            if (_instance == null)
                _instance = new Noteskins(new SingletonEnforcer());
            return _instance;
        }

        public function isLoaded():Boolean
        {
            return _isLoaded && !_loadError;
        }

        public function isError():Boolean
        {
            return _loadError;
        }

        public function get data():Object
        {
            return _data;
        }

        private function loadComplete():void
        {
            //- Complete if done
            if (totalNoteskins == totalLoaded && totalNoteskins > 0)
            {
                _isLoaded = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
            }
            else if (totalNoteskins == 0)
            {
                _loadError = true;
                    //_gvars.gameMain.addPopup(new PopupMessage(_gvars.gameMain, "No noteskins were loaded, making gameplay\nimpossible, please refresh the game and try again.", "ERROR"));
            }
        }

        ///- Public Functions
        public function getInfo(index:int):Object
        {
            if (_data[index] != null)
            {
                return _data[index];
            }
            return _data[1];
        }

        public function getNote(index:int, noteColor:String, direction:String):Sprite
        {
            for each (var skin:int in[index, 1])
            {
                if (_data[skin] != null)
                {
                    for each (var color:String in[noteColor, "blue"])
                    {
                        if (_data[skin] != null && _data[skin]["notes"][color] != null)
                        {
                            for each (var dir:String in[direction, "D"])
                            {
                                if (_data[skin]["notes"][color][dir] != null)
                                {
                                    if (_data[skin]["notes"][color][dir] is BitmapData)
                                    {
                                        var n:Sprite = new Sprite();
                                        n.graphics.beginBitmapFill(_data[skin]["notes"][color][dir], null, false);
                                        n.graphics.drawRect(0, 0, _data[skin]["notes"][color][dir].width, _data[skin]["notes"][color][dir].height);
                                        n.graphics.endFill();
                                        n.cacheAsBitmap = true;
                                        n.cacheAsBitmapMatrix = new Matrix();
                                        n.mouseEnabled = false;
                                        n.doubleClickEnabled = false;
                                        n.tabEnabled = false;
                                        return n;
                                    }
                                    else
                                    {
                                        return new _data[skin]["notes"][color][dir];
                                    }
                                }
                            }
                        }
                    }
                }
            }

            trace("1:Note", index, "-", noteColor, "-", dir, "missing.");
            return new MovieClip();
        }

        public function getReceptor(index:int, get_dir:String):MovieClip
        {
            for each (var skin:int in[index, 1])
            {
                if (_data[skin] != null)
                {
                    for each (var dir:String in[get_dir, "D"])
                    {
                        if (_data[skin]["receptor"] != null && _data[skin]["receptor"][dir] != null)
                        {
                            if (_data[skin]["receptor"][dir] is BitmapData)
                            {
                                return new GameReceptor(dir, _data[skin]["receptor"][dir]);
                            }
                            else
                            {
                                var receptor:MovieClip = new _data[skin]["receptor"][dir];
                                receptor.cacheAsBitmap = true;
                                receptor.cacheAsBitmapMatrix = new Matrix();
                                return receptor;
                            }
                        }
                    }
                }
            }
            trace("1:Receptor", index, "missing.");
            return new MovieClip();
        }

        public function isValid(index:int):Boolean
        {
            return _data[index] != null;
        }

        ///- noteskinXMLs Loading
        public function load():void
        {
            // Kill old Loading Stream
            if (_loader && _isLoading)
            {
                removeLoaderListeners();
                _loader.close();
            }

            // Load New
            _isLoaded = false;
            _loadError = false;
            _swfloaders = []; // new Vector.<DynamicLoader>;
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(Constant.NOTESKIN_URL + "?d=" + new Date().getTime());
            _loader.load(req);
            _isLoading = true;
        }

        private function noteskinXMLLoadComplete(e:Event):void
        {
            removeLoaderListeners();

            try
            {
                var xmlMain:XML = new XML(e.target.data);
                var xmlChildren:XMLList = xmlMain.children();
            }
            catch (e:Error)
            {
                _loadError = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
                return;
            }

            _data = new Object();
            totalNoteskins = xmlChildren.length();
            totalLoaded = 0;

            for (var a:uint = 0; a < xmlChildren.length(); ++a)
            {
                // Check for noteskinXML Object, if not, create one.
                var noteID:String = xmlChildren[a].attribute("id").toString();
                if (_data[noteID] == null)
                {
                    _data[noteID] = {};
                }

                // Add Text to Object
                _data[noteID]["id"] = noteID;
                var noteAttr:XMLList = xmlChildren[a].attributes();
                for (var b:uint = 0; b < noteAttr.length(); b++)
                {
                    _data[noteID]["_" + noteAttr[b].name()] = noteAttr[b].toString();
                }
                var noteNodes:XMLList = xmlChildren[a].children();
                for (var nc:uint = 0; nc < noteNodes.length(); nc++)
                {
                    var noteElem:XML = noteNodes[nc];
                    var noteElemName:String = noteElem.name();
                    _data[noteID][noteElemName] = noteElem.children()[0].toString();
                }

                _data[noteID]["notes"] = {};

                var noteType:String = xmlChildren[a].attribute("type");
                if (noteType == "bitmap")
                {
                    loadNoteskinBitmap(noteID);
                }
                else
                {
                    loadNoteskinSWF(noteID);
                }
            }
            loadCustomNoteskin();
        }

        private function noteskinXMLLoadError(e:Event = null):void
        {
            removeLoaderListeners();
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, noteskinXMLLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, noteskinXMLLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, noteskinXMLLoadError);
        }

        private function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, noteskinXMLLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, noteskinXMLLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, noteskinXMLLoadError);
        }

        //- Noteskins SWF
        private function loadNoteskinSWF(noteID:String):void
        {
            var urlrequest:URLRequest = new URLRequest(Constant.NOTESKIN_SWF_URL + "NoteSkin" + noteID + ".swf?d=" + new Date().getTime());
            var _swfloader:DynamicLoader = new DynamicLoader();
            _swfloader.contentLoaderInfo.addEventListener(Event.COMPLETE, noteskinSWFLoadComplete);
            _swfloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, noteskinSWFLoadError);
            _swfloader.load(urlrequest);
            _swfloader.ID = noteID;
            _swfloaders.push(_swfloader);
        }

        private function noteskinSWFLoadComplete(e:Event = null):void
        {
            var loader:DynamicLoader = e.target.loader;
            var noteID:String = loader.ID;
            var loaderIndex:int = -1;

            //- Remove Listeners
            for (var i:int = 0; i < _swfloaders.length; i++)
            {
                if (_swfloaders[i] === loader)
                    loaderIndex = i;
            }
            if (loaderIndex > -1)
            {
                _swfloaders[loaderIndex].contentLoaderInfo.removeEventListener(Event.COMPLETE, noteskinSWFLoadComplete);
                _swfloaders[loaderIndex].contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, noteskinSWFLoadError);
                _swfloaders[loaderIndex] = null;
            }

            //- Create Objects
            try
            {
                _data[noteID]["notes"]["blue"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_blue") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Blue Note");
            }
            try
            {
                _data[noteID]["notes"]["red"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_red") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Red Note");
            }
            try
            {
                _data[noteID]["notes"]["green"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_green") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Green Note");
            }
            try
            {
                _data[noteID]["notes"]["yellow"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_yellow") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Yellow Note");
            }
            try
            {
                _data[noteID]["notes"]["pink"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_pink") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Pink Note");
            }
            try
            {
                _data[noteID]["notes"]["purple"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_purple") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Purple Note");
            }
            try
            {
                _data[noteID]["notes"]["cyan"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_cyan") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Cyan Note");
            }
            try
            {
                _data[noteID]["notes"]["orange"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_orange") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Orange Note");
            }
            try
            {
                _data[noteID]["notes"]["white"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::note_white") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No White Note");
            }
            try
            {
                _data[noteID]["receptor"] = {"D": e.target.applicationDomain.getDefinition("assets.noteskin::receptor") as Class};
            }
            catch (e:Error)
            {
                trace("3:NS:" + noteID + " - No Receptors");
            }

            if (verifyNoteSkin(noteID))
                totalLoaded++;
            else
            {
                totalNoteskins--;
                delete _data[noteID];
            }

            loadComplete();
        }

        private function noteskinSWFLoadError(e:Event = null):void
        {
            var loader:DynamicLoader = e.target.loader;
            var loaderIndex:int = -1;

            //- Remove Listeners
            for (var i:int = 0; i < _swfloaders.length; i++)
            {
                if (_swfloaders[i] === loader)
                    loaderIndex = i;
            }
            if (loaderIndex > -1)
            {
                _swfloaders[loaderIndex].contentLoaderInfo.removeEventListener(Event.COMPLETE, noteskinSWFLoadComplete);
                _swfloaders[loaderIndex].contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, noteskinSWFLoadError);
                _swfloaders[loaderIndex] = null;
            }

            //- Remove From List
            totalNoteskins--;
            delete _data[loader.ID];
            trace("3:Noteskin", loader.ID, "failed to load.");

            loadComplete();
        }

        private function loadNoteskinBitmap(noteID:String):void
        {
            if (_data[noteID]["data"] == null)
                return;

            var mbpString:String = _data[noteID]["data"];

            var imgLoader:DynamicLoader = new DynamicLoader();
            imgLoader.ID = noteID;

            try
            {
                var decoder:Base64Decoder = new Base64Decoder();
                decoder.decode(mbpString);
                imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, e_bitmapFail);
                imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_bitmapLoad);
                imgLoader.loadBytes(decoder.toByteArray(), AirContext.getLoaderContext());
            }
            catch (e:Error)
            {
                //- Remove From List
                if (noteID != "0")
                    totalNoteskins--;
                delete _data[noteID];
                trace("3:Noteskin", noteID, "failed to load.");
            }
        }

        private function e_bitmapFail(e:Event):void
        {
            var noteID:String = e.currentTarget.loader.ID;

            //- Remove From List
            totalNoteskins--;
            delete _data[noteID];
            trace("3:Noteskin", noteID, "failed to load.");

            loadComplete();
        }

        private function e_bitmapLoad(e:Event):void
        {
            var loader:DynamicLoader = e.currentTarget.loader;
            var noteID:String = loader.ID;
            var noteskin_struct:Object = null;
            if (_data[noteID]["rects"] != null)
            {
                if (_data[noteID]["rects"] is String)
                {
                    try
                    {
                        noteskin_struct = JSON.parse(_data[noteID]["rects"]);
                    }
                    catch (e:Error)
                    {

                    }
                }
                else
                {
                    noteskin_struct = _data[noteID]["rects"];
                }
            }
            var bmp:BitmapData = new BitmapData(loader.width, loader.height, true, 0);
            bmp.draw(loader);

            var arr:Object = buildFromBitmapData(bmp, noteskin_struct);

            if (arr == null)
            {
                if (noteID != "0")
                    totalNoteskins--;
                delete _data[noteID];
                loadComplete();
                return;
            }

            _data[noteID]["width"] = arr["_cell"][0];
            _data[noteID]["height"] = arr["_cell"][1];
            _data[noteID]["rotation"] = arr["_cell"][2];

            for (var name:String in arr)
            {
                if (name == "receptor")
                    _data[noteID]["receptor"] = arr["receptor"];
                else
                    _data[noteID]["notes"][name] = arr[name];
            }

            if (verifyNoteSkin(noteID))
            {
                if (noteID != "0")
                    totalLoaded++;
                delete _data[noteID]["data"];
                delete _data[noteID]["rects"];
            }
            else
            {
                if (noteID != "0")
                    totalNoteskins--;
                delete _data[noteID];
            }
            loadComplete();
        }

        private function verifyNoteSkin(noteID:String):Boolean
        {
            // Check if this noteskin has the bare minimum requirements.
            if (_data[noteID] == null || _data[noteID]["receptor"] == null || (_data[noteID]["receptor"] != null && !_data[noteID]["receptor"]["D"] is Class) || _data[noteID]["notes"] == null || _data[noteID]["notes"]["blue"] == null || (_data[noteID]["notes"]["blue"] != null && !_data[noteID]["notes"]["blue"]["D"] is Class))
            {
                //_gvars.gameMain.addPopup(new PopupMessage(_gvars.gameMain, "Noteskin \"" + _data[noteID]["name"] + "\" is missing the blue note (assets.noteskin.note_blue), \nor the receptor (assets.noteskin.receptor).\nBoth are required for this noteskin to work correctly.", "ERROR"));
                return false;
            }

            if (_data[noteID]["notes"]["blue"] != null && _data[noteID]["notes"]["blue"]["D"] is Class)
            {
                //- Check Missing Notes
                if (_data[noteID]["notes"]["red"] == null)
                    _data[noteID]["notes"]["red"] = _data[noteID]["notes"]["blue"];
                if (_data[noteID]["notes"]["green"] == null)
                    _data[noteID]["notes"]["green"] = _data[noteID]["notes"]["blue"];
                if (_data[noteID]["notes"]["yellow"] == null)
                    _data[noteID]["notes"]["yellow"] = _data[noteID]["notes"]["blue"];
                if (_data[noteID]["notes"]["pink"] == null)
                    _data[noteID]["notes"]["pink"] = _data[noteID]["notes"]["blue"];
                if (_data[noteID]["notes"]["purple"] == null)
                    _data[noteID]["notes"]["purple"] = _data[noteID]["notes"]["blue"];
                if (_data[noteID]["notes"]["cyan"] == null)
                    _data[noteID]["notes"]["cyan"] = _data[noteID]["notes"]["blue"];
                if (_data[noteID]["notes"]["orange"] == null)
                    _data[noteID]["notes"]["orange"] = _data[noteID]["notes"]["blue"];
                if (_data[noteID]["notes"]["white"] == null)
                    _data[noteID]["notes"]["white"] = _data[noteID]["notes"]["blue"];
            }

            return true;
        }

        public static function buildFromBitmapData(bmd:BitmapData, import_struct:Object):Object
        {
            var struct:Object = NoteskinsStruct.getDefaultStruct();
            var out:Object = {};
            var cuts:Object = {};
            ObjectUtil.merge(struct, import_struct);

            if (import_struct == null || struct["options"] == null || struct["options"]["grid_dim"] == null || struct["blue"] == null || struct["blue"]["D"] == null || struct["blue"]["D"]["c"] == null)
                return null;

            var parsedCell:Array = NoteskinsStruct.parseCellInput(struct["options"]["grid_dim"]);
            var img_w:int = bmd.width;
            var img_h:int = bmd.height;
            var dim_w:int = parsedCell[0];
            var dim_h:int = parsedCell[1];
            var cell_width:Number = img_w / dim_w;
            var cell_height:Number = img_h / dim_h;
            var cell_rotate:Number = NoteskinsStruct.textToRotation(struct["options"]["rotate"], 90);

            out["_cell"] = [cell_width, cell_height, cell_rotate];

            for (var color:String in struct)
            {
                if (color == "options")
                    continue;

                for (var dir:String in struct[color])
                {
                    if (struct[color][dir]["c"] == "")
                        continue;

                    var note_pos:Array = NoteskinsStruct.parseCellInput(struct[color][dir]["c"]);

                    if (!out[color])
                        out[color] = {};

                    // Position outside grid.
                    if (note_pos[0] > dim_w || note_pos[1] > dim_h)
                    {
                        continue;
                    }
                    // Get Existing Bitmap if Cords already used.
                    else if (cuts[note_pos[0] + "x" + note_pos[1]])
                    {
                        out[color][dir] = cuts[note_pos[0] + "x" + note_pos[1]];
                    }
                    else
                    {
                        var note_canvas:BitmapData = new BitmapData(cell_width, cell_height, true, 0);
                        note_canvas.copyPixels(bmd, new Rectangle(note_pos[0] * cell_width, note_pos[1] * cell_height, cell_width, cell_height), new Point(0, 0), null, null, true);
                        out[color][dir] = note_canvas;
                        cuts[note_pos[0] + "x" + note_pos[1]] = out[color][dir];
                    }
                }
            }

            return out;
        }

        public function loadCustomNoteskin():void
        {
            var data:String = LocalStore.getVariable("custom_noteskin", null);
            if (data != null)
            {
                var obj:Object = JSON.parse(data);
                obj["id"] = "0";
                obj["_hidden"] = true;
                obj["notes"] = {};
                _data[obj["id"]] = obj;
                loadNoteskinBitmap("0");
            }
            else
            {
                if (_data["0"] != null)
                    delete _data["0"];
            }
        }
    }
}

class SingletonEnforcer
{
}
