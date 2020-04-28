package popups
{
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.Box;
    import classes.BoxButton;
    import classes.Language;
    import classes.Playlist;
    import classes.StarSelector;
    import classes.Text;
    import com.flashfla.utils.ObjectUtil;
    import com.greensock.easing.Back;
    import com.greensock.TweenLite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.text.AntiAliasType;
    import flash.text.StyleSheet;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import menu.MenuPanel;

    public class PopupSongRating extends MenuPanel
    {
        private var _lang:Language = Language.instance;
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _playlist:Playlist = Playlist.instance;
        private var _loader:URLLoader;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var sObject:Object;

        private var sRating:StarSelector;
        private var cRating:StarSelector;

        private var confirmOptions:BoxButton;
        private var closeOptions:BoxButton;

        public function PopupSongRating(myParent:MenuPanel, song:Object)
        {
            super(myParent);
            sObject = song;
        }

        override public function stageAdd():void
        {
            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);
            bmp.alpha = 0;
            this.addChild(bmp);

            // 250, 125
            var bgbox:Box = new Box(Main.GAME_WIDTH / 2, Main.GAME_HEIGHT - 290, false, false);
            bgbox.x = ((Main.GAME_WIDTH / 2) / 2);
            bgbox.y = (290 / 2);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;
            bgbox.alpha = 0;
            this.addChild(bgbox);

            box = new Box(Main.GAME_WIDTH / 2, Main.GAME_HEIGHT - 290, false, false);
            box.x = ((Main.GAME_WIDTH / 2) / 2);
            box.y = (290 / 2);
            box.activeAlpha = 0.4;
            box.alpha = 0;
            this.addChild(box);

            var titleDisplay:Text = new Text(_lang.string("song_rating_title"), 20);
            titleDisplay.x = 5;
            titleDisplay.y = 5;
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;
            box.addChild(titleDisplay);

            var songName:Text = new Text(sObject["name"], 16);
            songName.x = 5;
            songName.y = 35;
            songName.width = box.width - 10;
            songName.align = Text.CENTER;
            box.addChild(songName);

            // Divider
            box.graphics.lineStyle(1, 0xffffff);
            box.graphics.moveTo(10, 65);
            box.graphics.lineTo(box.width - 20, 65);

            var lblSongRating:Text = new Text(_lang.string("song_rating_label"), 14);
            lblSongRating.x = 5;
            lblSongRating.y = 85;
            lblSongRating.width = 145;
            lblSongRating.align = Text.RIGHT;
            box.addChild(lblSongRating);

            sRating = new StarSelector();
            sRating.x = 160;
            sRating.y = 83;
            sRating.value = _gvars.playerUser.getSongRating(sObject["level"]);
            sRating.addEventListener(Event.CHANGE, e_changeEvent);
            box.addChild(sRating);

            /*var lblChartRating:Text = new Text(_lang.string("song_rating_label"), 14);
               lblChartRating.x = 5;
               lblChartRating.y = 125;
               lblChartRating.width = 145;
               lblChartRating.align = Text.RIGHT;
               box.addChild(lblChartRating);

               cRating = new StarSelector();
               cRating.x = 160;
               cRating.y = 123;
               cRating.value = 0;
               cRating.addEventListener(Event.CHANGE, e_changeEvent);
               box.addChild(cRating);
             */

            // Divider
            box.graphics.lineStyle(1, 0xffffff);
            box.graphics.moveTo(10, 170 - 40);
            box.graphics.lineTo(box.width - 20, 170 - 40);

            //- Close
            closeOptions = new BoxButton(79.5, 27, _lang.string("menu_close"));
            closeOptions.x = box.width - 94.5;
            closeOptions.y = box.height - 42;
            closeOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(closeOptions);

            //- Confirm
            confirmOptions = new BoxButton(79.5, 27, _lang.string("menu_confirm"));
            confirmOptions.x = closeOptions.x - 94.5;
            confirmOptions.y = box.height - 42;
            confirmOptions.visible = false;
            confirmOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(confirmOptions);

            TweenLite.to(bmp, 1, {alpha: 1});
            TweenLite.to(bgbox, 1, {alpha: 1});
            TweenLite.to(box, 1, {alpha: 1});
        }

        private function e_changeEvent(e:Event):void
        {
            var shown:int = 0;
            var exist:int = 0;

            if (sRating)
            {
                shown++;
                if (sRating.value > 0)
                    exist++;
            }

            if (cRating)
            {
                shown++;
                if (cRating.value > 0)
                    exist++;
            }

            confirmOptions.visible = (shown == exist);
        }

        override public function stageRemove():void
        {
            box.dispose();
            bmp = null;
            box = null;
        }

        private function clickHandler(e:MouseEvent):void
        {
            //- Confirm Rating
            if (e.target == confirmOptions)
            {
                saveRatings();
                removePopup();
                return;
            }
            //- Close
            else if (e.target == closeOptions)
            {
                removePopup();
                return;
            }
        }

        private function saveRatings():void
        {
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(Constant.SONG_RATING_URL + "?d=" + new Date().getTime());
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = _gvars.userSession;
            requestVars.id = sObject["level"];
            requestVars.song_rating = sRating ? sRating.value : 2.5;
            requestVars.chart_rating = cRating ? cRating.value : 2.5;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, ratingLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, ratingLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, ratingLoadError);
        }

        private function ratingLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            try
            {
                var _data:Object = JSON.parse(e.target.data);
                if (_data["result"] && _data["result"] == "success")
                {
                    _gvars.playerUser.songRatings[sObject["level"]] = sRating.value;
                    _gvars.gameMain.addAlert("Saved rating for " + sObject["name"] + "!", 120, Alert.GREEN);
                    if (_data["type"] && _data["type"] == 1)
                    {
                        _playlist.playList[sObject["level"]]["song_rating"] = _data["new_value"];
                    }
                }
                else
                {
                    _gvars.gameMain.addAlert("Failed to save song rating.", 120, Alert.RED);
                }
            }
            catch (e:Error)
            {
            }
        }

        private function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, ratingLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, ratingLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, ratingLoadError);
        }

        private function ratingLoadError(e:Event):void
        {
            removeLoaderListeners();
        }
    }

}
