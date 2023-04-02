package classes
{
    import by.blooddy.crypto.Base64;
    import com.flashfla.utils.ObjectUtil;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import game.noteskins.*;

    public class Noteskins extends EventDispatcher
    {
        private static const note_asset_names:Array = ["blue", "red", "yellow", "green", "purple", "pink", "orange", "cyan", "white"];
        private static const note_direction_names:Array = ["D", "U", "L", "R"];
        private static const TYPE_SWF:int = 0;
        private static const TYPE_BITMAP:int = 1;

        public static const CUSTOM_NOTESKIN_DATA:String = "custom_noteskin";
        public static const CUSTOM_NOTESKIN_IMPORT:String = "custom_noteskin_import";
        public static const CUSTOM_NOTESKIN_FILE:String = "custom_noteskin_filename";

        ///- Singleton Instance
        private static var _instance:Noteskins = null;
        private static var _externalNoteskins:Vector.<ExternalNoteskin>;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _isLoaded:Boolean = false;
        private var _isLoading:Boolean = false;
        private var _loadError:Boolean = false;

        private var _data:Object;

        public var totalNoteskins:int = 0;
        public var totalLoaded:int = 0;

        //******************************************************************************************//
        // Core Class Functions
        //******************************************************************************************//

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

        /**
         * Gets the loaded status.
         * @return Is loaded & No Load Errors
         */
        public function isLoaded():Boolean
        {
            return _isLoaded && !_loadError;
        }

        /**
         * Is there a load error.
         * @return
         */
        public function isError():Boolean
        {
            return _loadError;
        }

        /**
         * Called when a a noteskin is loaded.
         * Triggers a LOAD_COMPLETE when the total noteskins matchs the loaded noteskins.
         */
        private function loadComplete():void
        {
            // All Noteskins loaded.
            if (totalNoteskins == totalLoaded && totalNoteskins > 0)
            {
                _isLoaded = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
            }

            // No Loaded Noteskins
            else if (totalNoteskins == 0)
            {
                _loadError = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
            }
        }

        /**
         * Load the Noteskins data.
         */
        public function load():void
        {
            // Load New
            _isLoading = true;
            _isLoaded = false;
            _loadError = false;
            _data = {};

            var embeddedNoteskins:Vector.<EmbedNoteskinBase> = new <EmbedNoteskinBase>[new EmbedNoteskin1(),
                new EmbedNoteskin2(),
                new EmbedNoteskin3(),
                new EmbedNoteskin4(),
                new EmbedNoteskin5(),
                new EmbedNoteskin6(),
                new EmbedNoteskin7(),
                new EmbedNoteskin8(),
                new EmbedNoteskin9(),
                new EmbedNoteskin10()];

            for each (var embedNoteskin:EmbedNoteskinBase in embeddedNoteskins)
            {
                _data[embedNoteskin.getID()] = embedNoteskin.getData();
                _data[embedNoteskin.getID()]["notes"] = {};
                loadNoteskinSWF(embedNoteskin.getID(), embedNoteskin.getBytes());
            }

            loadCustomNoteskin();
        }

        //******************************************************************************************//
        // Providers
        //******************************************************************************************//

        /**
         * Gets all loaded noteskin data.
         * @return
         */
        public function get data():Object
        {
            return _data;
        }

        /**
         * Gets a single noteskin data, or the default noteskin if the requested
         * noteskin is null.
         * @param noteskin
         * @return
         */
        public function getInfo(noteskin:int):Object
        {
            if (_data[noteskin] != null)
            {
                return _data[noteskin];
            }
            return _data[1];
        }

        /**
         * Gets the Note Sprite from the noteskin.
         * @param noteskin
         * @param color
         * @param direction
         * @return
         */
        public function getNote(noteskin:int, color:String, direction:String):Sprite
        {
            try
            {
                // Is requested noteskin is missing, fallback to Default
                if (_data[noteskin] == null)
                    noteskin = 1;

                if (_data[noteskin]["type"] == TYPE_BITMAP)
                {
                    return drawBitmapNote(_data[noteskin]["notes"][color][direction]);
                }

                return new _data[noteskin]["notes"][color][direction];
            }
            catch (e:Error)
            {

            }
            return new Sprite();
        }

        /**
         * Gets the Receptor Movieclip from the noteskin.
         * This is slower and shouldn't be used for gameplay, only UI
         * to prevent crashes on corrupted noteskins. A blank movieclip will
         * be return if a error occurs.
         * @param noteskin
         * @param color
         * @param direction
         * @return
         */
        public function getReceptor(noteskin:int, direction:String):MovieClip
        {
            try
            {
                // Is requested noteskin is missing, fallback to Default
                if (_data[noteskin] == null)
                    noteskin = 1;

                if (_data[noteskin]["type"] == TYPE_BITMAP)
                    return new GameReceptor(direction, _data[noteskin]["receptor"][direction]);

                return new _data[noteskin]["receptor"][direction];
            }
            catch (e:Error)
            {

            }
            return new MovieClip();
        }

        /**
         * Draws a Notes BitmapData into a new sprite.
         * @param bmd BitmapData
         * @return
         */
        private function drawBitmapNote(bmd:BitmapData):Sprite
        {
            var n:Sprite = new Sprite();
            n.graphics.beginBitmapFill(bmd, null, false);
            n.graphics.drawRect(0, 0, bmd.width, bmd.height);
            n.graphics.endFill();
            n.cacheAsBitmap = true;
            n.cacheAsBitmapMatrix = new Matrix();
            n.mouseEnabled = false;
            n.doubleClickEnabled = false;
            n.tabEnabled = false;
            return n;
        }

        /**
         * Checks if noteskin ID is valid.
         * @param noteskin
         * @return
         */
        public function isValid(noteskin:int):Boolean
        {
            return _data[noteskin] != null;
        }

        //******************************************************************************************//
        // SWF Noteskins
        //******************************************************************************************//

        /**
         * Begin loading of a SWF noteskin and marks the type for this noteskin as TYPE_SWF.
         * @param noteID
         */
        private function loadNoteskinSWF(noteID:int, bytes:ByteArray):void
        {
            var _swfloader:DynamicLoader = new DynamicLoader();
            _swfloader.contentLoaderInfo.addEventListener(Event.COMPLETE, noteskinSWFLoadComplete);
            _swfloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, noteskinSWFLoadError);
            _swfloader.loadBytes(bytes, AirContext.getLoaderContext())
            _swfloader.ID = noteID;
            _data[noteID]["type"] = TYPE_SWF;
            totalNoteskins++;
        }

        /**
         * Event.COMPLETE for SWF loading complete.
         * @param e
         */
        private function noteskinSWFLoadComplete(e:Event = null):void
        {
            var loader:DynamicLoader = e.target.loader;
            var noteID:String = loader.ID;

            // Remove Listeners
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, noteskinSWFLoadComplete);
            loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, noteskinSWFLoadError);

            // Create Objects
            for each (var asset_name:String in note_asset_names)
            {
                _data[noteID]["notes"][asset_name] = getAssetFromTarget(e.target, "assets.noteskin::note_" + asset_name);
            }
            _data[noteID]["receptor"] = getAssetFromTarget(e.target, "assets.noteskin::receptor");

            // Verify or Remove
            if (verifyNoteSkin(noteID))
            {
                totalLoaded++;
            }
            else
            {
                totalNoteskins--;
                delete _data[noteID];
            }

            loadComplete();
        }

        /**
         * IOErrorEvent.IO_ERROR for SWF loading failure.
         * @param e
         */
        private function noteskinSWFLoadError(e:Event = null):void
        {
            var loader:DynamicLoader = e.target.loader;

            // Remove Listeners
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, noteskinSWFLoadComplete);
            loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, noteskinSWFLoadError);

            // Remove From List
            totalNoteskins--;
            delete _data[loader.ID];

            loadComplete();
        }

        /**
         * Attempts to retrieve a class definition from the given object.
         * Used to retrieve the notes and receptors from loaded swfs.
         * @param loader
         * @param assetName
         * @return
         */
        private function getAssetFromTarget(loader:Object, assetName:String):Object
        {
            try
            {
                return {"D": loader.applicationDomain.getDefinition(assetName) as Class};
            }
            catch (e:Error)
            {
            }
            return null;
        }

        //******************************************************************************************//
        // Bitmap Noteskin
        //******************************************************************************************//

        /**
         * Begin loading of a bitmap noteskin and marks the type for this noteskin as TYPE_BITMAP.
         * @param noteID
         */
        private function loadNoteskinBitmap(noteID:String):void
        {
            if (_data[noteID]["data"] == null)
                return;

            _data[noteID]["type"] = TYPE_BITMAP;

            var mbpString:String = _data[noteID]["data"];
            var imgLoader:DynamicLoader = new DynamicLoader();
            imgLoader.ID = noteID;
            totalNoteskins++;

            imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, e_bitmapFail);
            imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_bitmapLoad);

            try
            {
                imgLoader.loadBytes(Base64.decode(mbpString), AirContext.getLoaderContext());
            }
            catch (e:Error)
            {
                // Remove From List
                totalNoteskins--;
                delete _data[noteID];
            }
        }

        /**
         * Event.COMPLETE for bitmap loading complete.
         * @param e
         */
        private function e_bitmapLoad(e:Event):void
        {
            var loader:DynamicLoader = e.currentTarget.loader;
            loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, e_bitmapFail);
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, e_bitmapLoad);

            var noteID:String = loader.ID;
            var noteskin_struct:Object = null;

            // Get Noteskin Structure
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

            // Draw Source Bitmap
            var bmp:BitmapData = new BitmapData(loader.width, loader.height, true, 0);
            bmp.draw(loader);

            // Draw Sub-Images for Noteskin
            var arr:Object = buildFromBitmapData(bmp, noteskin_struct);
            if (arr == null)
            {
                totalNoteskins--;
                delete _data[noteID];
                loadComplete();
                return;
            }

            // Set parameters from structure.
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

            // Verify or Remove
            if (verifyNoteSkin(noteID))
            {
                totalLoaded++;
                delete _data[noteID]["data"];
                delete _data[noteID]["rects"];
            }
            else
            {
                totalNoteskins--;
                delete _data[noteID];
            }

            loadComplete();
        }

        /**
         * IOErrorEvent.IO_ERROR for bitmap loading failure.
         * @param e
         */
        private function e_bitmapFail(e:Event):void
        {
            var loader:DynamicLoader = e.currentTarget.loader;
            loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, e_bitmapFail);
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, e_bitmapLoad);

            var noteID:String = loader.ID;

            //- Remove From List
            totalNoteskins--;
            delete _data[noteID];

            loadComplete();
        }

        /**
         * Builds a group of noteskin bitmaps from the source BitmapData
         * following the cell structure
         * @param bmd Source Bitmap Data
         * @param import_struct
         * @return
         */
        public static function buildFromBitmapData(bmd:BitmapData, import_struct:Object):Object
        {
            var struct:Object = NoteskinsStruct.getDefaultStruct();
            var out:Object = {};
            var cuts:Object = {};
            ObjectUtil.merge(struct, import_struct);

            if (import_struct == null || struct["options"] == null || struct["options"]["grid_dim"] == null || struct["blue"] == null || struct["blue"]["D"] == null || struct["blue"]["D"]["c"] == null)
                return null;

            var parsedCell:Array = NoteskinsStruct.parseCellInput(struct["options"]["grid_dim"], 1, 1, 20, 20);
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

        /**
         * Verfies all required data is a part of a noteskin such as the Receptor and Blue note.
         * Once that is verified, it fill in any gaps for the other colors and direction that
         * might appear with filler data from the Blue note to prevent null errors.
         * @param noteID Note ID to check.
         * @return boolean If Valid Noteskin
         */
        private function verifyNoteSkin(noteID:String):Boolean
        {
            // Check if this noteskin has the bare minimum requirements.
            if (_data[noteID] == null)
                return false;

            // Check Receptor
            if (_data[noteID]["receptor"] == null || _data[noteID]["receptor"]["D"] == null)
                return false;

            // Check Blue Note
            if (_data[noteID]["notes"]["blue"] == null || _data[noteID]["notes"]["blue"]["D"] == null)
                return false;

            // Check Missing Notes and fill from Blue
            for each (var asset_name:String in note_asset_names)
            {
                if (_data[noteID]["notes"][asset_name] == null)
                    _data[noteID]["notes"][asset_name] = _data[noteID]["notes"]["blue"];

                // Check Missing Directions and fill from Down
                for each (var direction_name:String in note_direction_names)
                {
                    // Fill from same color.
                    if (_data[noteID]["notes"][asset_name][direction_name] == null && _data[noteID]["notes"][asset_name]["D"] != null)
                        _data[noteID]["notes"][asset_name][direction_name] = _data[noteID]["notes"][asset_name]["D"];

                    // Fill from blue.
                    if (_data[noteID]["notes"][asset_name][direction_name] == null && _data[noteID]["notes"]["blue"]["D"] != null)
                        _data[noteID]["notes"][asset_name][direction_name] = _data[noteID]["notes"]["blue"]["D"];
                }
            }

            // Check Missing Receptor Directions and fill from Down
            for each (var receptor_direction:String in note_direction_names)
            {
                if (_data[noteID]["receptor"][receptor_direction] == null)
                    _data[noteID]["receptor"][receptor_direction] = _data[noteID]["receptor"]["D"];
            }
            return true;
        }

        public function loadCustomNoteskin():void
        {
            var noteskinData:String = LocalStore.getVariable(CUSTOM_NOTESKIN_DATA, null);
            var noteskinImport:String = LocalStore.getVariable(CUSTOM_NOTESKIN_IMPORT, null);
            var noteskinFilename:String = LocalStore.getVariable(CUSTOM_NOTESKIN_FILE, null);

            // Copy Data into Import Slot if coming from old version.
            if (noteskinData != null && noteskinImport == null)
            {
                Logger.debug(this, "Storing Internal Noteskin");
                LocalStore.setVariable(CUSTOM_NOTESKIN_IMPORT, noteskinData);
            }

            // No Data, no Custom Noteskin
            if (noteskinData == null)
            {
                Logger.debug(this, "No Noteskin Data");
                return;
            }

            // Reload External Noteskin if exist
            if (noteskinFilename != null)
            {
                Logger.debug(this, "Reloading External Noteskin: " + noteskinFilename);
                var noteskinJSON:String = AirContext.readTextFile(AirContext.getAppFile(Constant.NOTESKIN_PATH).resolvePath(noteskinFilename));

                if (noteskinJSON == null)
                    LocalStore.deleteVariable(CUSTOM_NOTESKIN_FILE);
                else
                    noteskinData = noteskinJSON;
            }

            loadCustomNoteskinJSON(noteskinData);
        }

        public function loadCustomNoteskinJSON(data:String):void
        {
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

        public function get externalNoteskins():Vector.<ExternalNoteskin>
        {
            if (_externalNoteskins == null)
                loadExternalNoteskins();

            return _externalNoteskins;
        }

        public function loadExternalNoteskins():Boolean
        {
            _externalNoteskins = new <ExternalNoteskin>[];

            var noteskinFolder:File = AirContext.getAppFile(Constant.NOTESKIN_PATH);
            if (!noteskinFolder.exists || !noteskinFolder.isDirectory || noteskinFolder.isHidden)
                return false;

            var file:File;
            var fileDataJSON:String;
            var fileData:Object;
            var files:Array = noteskinFolder.getDirectoryListing();
            for (var i:int = 0; i < files.length; i++)
            {
                file = files[i];
                try
                {
                    if (file.type != ".txt")
                        continue;

                    fileDataJSON = AirContext.readTextFile(file);
                    fileData = JSON.parse(fileDataJSON);

                    var extNoteskin:ExternalNoteskin = new ExternalNoteskin();
                    extNoteskin.file = file.name;
                    extNoteskin.data = fileData;
                    extNoteskin.json = fileDataJSON;
                    _externalNoteskins.push(extNoteskin);
                }
                catch (error:Error)
                {

                }
            }

            return true;
        }
    }
}

class SingletonEnforcer
{
}
