package popups.replays
{
    import classes.Alert;
    import classes.Language;
    import classes.replay.Replay;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import com.flashfla.net.WebRequest;
    import com.flashfla.utils.SpriteUtil;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class ReplayHistoryTabOnline extends ReplayHistoryTabBase
    {
        private static var INITIAL_LOAD:Boolean = false;
        private static var REPLAYS:Vector.<Replay>;
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        private var _http:WebRequest;
        private var btn_refresh:BoxButton;

        private var uiLock:Sprite;
        private var uiLockBG:Bitmap;
        private var loadingCancelButton:BoxButton;

        public function ReplayHistoryTabOnline(replayWindow:ReplayHistoryWindow):void
        {
            super(replayWindow);

            // UI Lock
            uiLock = new Sprite();
            var lockUIText:Text = new Text(uiLock, 0, 200, _lang.string("replay_loading_online"), 24);
            lockUIText.setAreaParams(780, 30, "center");

            loadingCancelButton = new BoxButton(uiLock, 390 - 40, 440, 80, 30, _lang.string("menu_cancel"), 12, clickHandler);
        }

        override public function get name():String
        {
            return "online";
        }

        override public function openTab():void
        {
            // Add UI Elements
            if (!btn_refresh)
            {
                btn_refresh = new BoxButton(null, 5, Main.GAME_HEIGHT - 35, 162, 29, _lang.string("menu_refresh"), 12, loadOnlineReplays);
            }
            parent.addChild(btn_refresh);

            // Initial Load
            if (!INITIAL_LOAD)
            {
                loadOnlineReplays();
                INITIAL_LOAD = true;
            }
        }

        override public function closeTab():void
        {
            parent.removeChild(btn_refresh);
        }

        override public function setValues():void
        {
            var render_list:Array = [];
            for each (var r:Replay in REPLAYS)
            {
                if (r.song == null)
                    continue;

                if (parent.searchText.length >= 1 && r.song.name.toLowerCase().indexOf(parent.searchText) == -1)
                    continue;

                render_list[render_list.length] = r;
            }
            parent.pane.setRenderList(render_list);
            parent.updateScrollPane();
        }

        private function loadOnlineReplays(e:MouseEvent = null):void
        {
            Logger.info(this, "Loading Online Replays");
            lockUI = true;

            REPLAYS = new <Replay>[];

            _http = new WebRequest(URLs.resolve(URLs.SITE_REPLAYS_URL), e_webLoad, e_webError);
            _http.load({"session": _gvars.userSession});
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == loadingCancelButton)
            {
                webLoadComplete(true);
            }
        }

        private function e_webLoad(e:Event):void
        {
            var data:String = e.target.data;

            try
            {
                var json:Object = JSON.parse(data);
                for each (var replay:Object in json)
                {
                    var r:Replay = new Replay(replay["replayid"]);
                    r.parseReplay(replay, false);
                    r.loadSongInfo();
                    r.user = _gvars.playerUser;
                    REPLAYS[REPLAYS.length] = r;
                }
            }
            catch (error:Error)
            {
            }

            webLoadComplete();
        }

        private function e_webError(e:Event):void
        {
            Alert.add(_lang.string("replay_error_retrieving_online"), 120, Alert.RED);
            webLoadComplete();
        }

        private function webLoadComplete(cancelled:Boolean = false):void
        {
            if (cancelled)
                _http.loader.close();

            _http = null;
            lockUI = false;
            setValues();
        }

        public function set lockUI(val:Boolean):void
        {
            if (val)
            {
                uiLockBG = SpriteUtil.getBitmapSprite(_gvars.gameMain.stage, 0.3);
                uiLock.addChildAt(uiLockBG, 0);
                parent.addChild(uiLock);
            }
            else
            {
                if (parent.contains(uiLock))
                {
                    uiLock.removeChildAt(0);
                    uiLockBG = null;
                    parent.removeChild(uiLock);
                }
            }
        }
    }
}
