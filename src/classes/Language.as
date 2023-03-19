/**
 * @author Jonathan (Velocity)
 */

package classes
{
    import classes.ui.Text;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

    public class Language extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:Language = null;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _loader:URLLoader;
        private var _isLoaded:Boolean = false;
        private var _isLoading:Boolean = false;
        private var _loadError:Boolean = false;

        public var data:Object;
        public var indexed:Array;

        ///- Constructor
        public function Language(en:SingletonEnforcer)
        {
            if (en == null)
            {
                throw Error("Multi-Instance Blocked");
            }
        }

        public static function get instance():Language
        {
            if (_instance == null)
            {
                _instance = new Language(new SingletonEnforcer());
            }

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

        ///- Public Functions
        public function font(testStr:String = ""):String
        {
            return Text.isUnicode(testStr) ? Fonts.BASE_FONT_CJK : Fonts.BASE_FONT;
        }

        public function wrapFont(text:String):String
        {
            return "<font face=\"" + font(text) + "\">" + text + "</font>";
        }

        public function string(id:String):String
        {
            return string2(id, _gvars.playerUser ? _gvars.playerUser.language : "us");
        }

        public function string2(id:String, lang:String):String
        {
            // Get Text
            var text:String = id;
            if (!data)
            {

            }
            else if (data[lang] && data[lang][id])
            {
                text = data[lang][id];
            }
            else if (data["us"][id] != null)
            {
                text = data["us"][id];
            }
            if (data && text == id)
                trace(id);
            return wrapFont(text);
        }

        public function stringSimple(id:String):String
        {
            return string2Simple(id, _gvars.playerUser ? _gvars.playerUser.language : "us");
        }

        public function string2Simple(id:String, lang:String):String
        {
            // Get Text
            var text:String = id;
            if (!data)
            {

            }
            else if (data[lang] && data[lang][id])
            {
                text = data[lang][id];
            }
            else if (data["us"][id] != null)
            {
                text = data["us"][id];
            }
            if (data && text == id)
                trace(id);
            return text;
        }

        ///- Language Loading
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
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.SITE_LANGUAGE_URL) + "?d=" + new Date().getTime());
            _loader.load(req);
            _isLoading = true;
        }

        private function languageLoadComplete(e:Event):void
        {
            Logger.info(this, "Data Loaded");
            removeLoaderListeners();

            // Parse Response
            var siteDataString:String = e.target.data;
            try
            {
                var xmlMain:XML = new XML(siteDataString);
                var xmlChildren:XMLList = xmlMain.children();
            }
            catch (err:Error)
            {
                Logger.error(this, "Parse Failure: " + Logger.exception_error(err));
                Logger.error(this, "Wrote invalid response data to log folder. [logs/language.txt]");
                AirContext.writeTextFile(AirContext.getAppFile("logs/language.txt"), siteDataString);

                _loadError = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
                return;
            }

            // Has Response
            data = new Object();
            indexed = new Array();

            for (var a:uint = 0; a < xmlChildren.length(); ++a)
            {
                // Check for Language Object, if not, create one.
                var lang:String = xmlChildren[a].attribute("id").toString();
                if (data[lang] == null)
                {
                    data[lang] = new Object();
                }

                // Add Attributes to Object
                var langAttr:XMLList = xmlChildren[a].attributes();
                for (var b:uint = 0; b < langAttr.length(); b++)
                {
                    data[lang]["_" + langAttr[b].name()] = langAttr[b].toString();
                }

                // Add Text to Object
                var langNodes:XMLList = xmlChildren[a].children();
                for (var c:uint = 0; c < langNodes.length(); c++)
                {
                    data[lang][langNodes[c].attribute("id").toString()] = langNodes[c].children()[0].toString().replace(/\r\n/gi, "\n");
                }
                indexed[data[lang]["_index"]] = lang;
            }

            _isLoaded = true;
            _loadError = false;
            Logger.info(this, "Parse Complete");
            checkCompleteLoad();
        }

        private function checkCompleteLoad():void
        {
            if (isLoaded())
            {
                this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
            }
        }

        private function languageLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Load Failure: " + Logger.event_error(err));
            removeLoaderListeners();
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, languageLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, languageLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, languageLoadError);
        }

        private function removeLoaderListeners():void
        {
            _loadError = true;
            _loader.removeEventListener(Event.COMPLETE, languageLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, languageLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, languageLoadError);
        }
    }

}

class SingletonEnforcer
{
}
