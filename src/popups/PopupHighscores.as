package popups
{
    import assets.GameBackgroundColor;
    import classes.Language;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import com.flashfla.loader.DataEvent;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.ObjectUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import menu.MenuPanel;
    import classes.SongInfo;

    public class PopupHighscores extends MenuPanel
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var page:int = 0;
        private var maxPage:int = 2147483647; // Max Int Limit
        private var throbber:Throbber;
        private var pageText:Text;
        private var myUsernameText:Text;
        private var myScoreText:Text;
        private var myAVText:Text;
        private var songInfo:SongInfo;
        private var scorePane:Sprite;

        private var prevBtn:BoxButton;
        private var nextBtn:BoxButton;
        private var closeBtn:BoxButton;
        private var refreshBtn:BoxButton;

        public function PopupHighscores(myParent:MenuPanel, songInfo:SongInfo)
        {
            super(myParent);
            this.songInfo = songInfo;
        }

        override public function stageAdd():void
        {
            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);

            this.addChild(bmp);

            var bgbox:Box = new Box(this, 20, 20, false, false);
            bgbox.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;

            box = new Box(this, 20, 20, false, false);
            box.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            box.activeAlpha = 0.4;

            var titleDisplay:Text = new Text(box, 5, 8, songInfo.name, 20);
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;

            pageText = new Text(box, 200, box.height - 42, sprintf(_lang.string("popup_highscores_page_number"), {"page": page + 1}));

            var infoRanks:Object = _gvars.activeUser.getLevelRank(songInfo);
            // Username
            myUsernameText = new Text(box, 25, 345, "#" + infoRanks.rank + ": " + _gvars.activeUser.name, 16, "#D9FF9E");
            myUsernameText.width = 164;

            // Score
            myScoreText = new Text(box, 360, 345, NumberUtil.numberFormat(infoRanks.rawscore), 15, "#B8D8B3");
            myScoreText.width = 150;

            // AV
            myAVText = new Text(box, 545, 345, infoRanks.results, 15, "#99B793");
            myAVText.width = 200;

            //- Previous
            prevBtn = new BoxButton(box, 10, box.height - 42, 79.5, 27, _lang.string("popup_highscores_previous"), 12, clickHandler);

            //- Next
            nextBtn = new BoxButton(box, 100, box.height - 42, 79.5, 27, _lang.string("popup_highscores_next"), 12, clickHandler);

            //- Close
            closeBtn = new BoxButton(box, box.width - 94.5, box.height - 42, 79.5, 27, _lang.string("menu_close"), 12, clickHandler);

            //- Refresh
            refreshBtn = new BoxButton(box, box.width - 184.5, box.height - 42, 79.5, 27, _lang.string("popup_highscores_refresh"), 12, clickHandler);

            //- Render List
            renderHighscores();
        }

        private function renderHighscores():void
        {
            if (scorePane && box && box.contains(scorePane))
            {
                box.removeChild(scorePane);
                scorePane = null;
            }
            scorePane = new Sprite();
            scorePane.y = 50;
            if (box)
                box.addChild(scorePane);

            var textLine:Text;
            var urank:Text;
            var tY:int = 0;

            if (throbber)
            {
                if (box && box.contains(throbber))
                    box.removeChild(throbber);
                throbber.stop();
            }

            if (page > maxPage)
                page = maxPage;

            var highscores:Object = _gvars.getHighscores(songInfo.level);
            if (highscores && (highscores[(10 * page) + 1] != null))
            {
                // Username
                textLine = new Text(scorePane, 25, tY, _lang.string("popup_highscores_username"), 16, "#C6F0FF");
                textLine.width = 200;

                // Score
                textLine = new Text(scorePane, 360, tY, _lang.string("popup_highscores_score"), 15, "#C6F0FF");
                textLine.width = 150;

                // AV
                textLine = new Text(scorePane, 545, tY, _lang.string("popup_highscores_pa_spread"), 15, "#C6F0FF");
                textLine.width = 200;
                tY += 30;

                var lastRank:int = 0;
                var lastScore:Number = Number.MAX_VALUE;
                for (var vr:int = 1; vr <= 10; vr++)
                {
                    var r:int = (10 * page) + vr;
                    if (highscores[r])
                    {
                        var username:String = highscores[r]['name'];
                        var score:Number = highscores[r]['score'];
                        var av:String = highscores[r]['av'];
                        var isMyPB:Boolean = (!_gvars.activeUser.isGuest) && (_gvars.activeUser.name == username);

                        // Username
                        textLine = new Text(scorePane, 25, tY, "#" + r + ": " + username, 16);
                        textLine.width = 200;
                        textLine.fontColor = isMyPB ? "#D9FF9E" : "#FFFFFF";

                        // Score
                        textLine = new Text(scorePane, 360, tY, NumberUtil.numberFormat(score), 15);
                        textLine.width = 150;
                        textLine.fontColor = isMyPB ? "#B8D8B3" : "#DDDDDD";

                        // AV
                        textLine = new Text(scorePane, 545, tY, av, 15);
                        textLine.width = 200;
                        textLine.fontColor = isMyPB ? "#99B793" : "#BBBBBB";
                        tY += 25;
                    }
                    else
                    {
                        maxPage = page;
                        break;
                    }
                }
            }
            else
            {
                if (!throbber)
                {
                    throbber = new Throbber();
                    if (box)
                    {
                        throbber.x = box.width / 2 - 16;
                        throbber.y = box.height / 2 - 16;
                    }
                }
                if (box)
                    box.addChild(throbber);
                throbber.start();

                _gvars.addEventListener(GlobalVariables.HIGHSCORES_LOAD_COMPLETE, highscoresLoaded);
                _gvars.loadHighscores(songInfo.level, page * 10);
            }
            pageText.text = sprintf(_lang.string("popup_highscores_page_number"), {"page": page + 1});

            prevBtn.enabled = page == 0 ? false : true;
            prevBtn.alpha = page == 0 ? 0.5 : 1;
            nextBtn.enabled = page == maxPage ? false : true;
            nextBtn.alpha = page == maxPage ? 0.5 : 1;
        }

        private function highscoresLoaded(e:DataEvent):void
        {
            _gvars.removeEventListener(GlobalVariables.HIGHSCORES_LOAD_COMPLETE, highscoresLoaded);
            if (e.data.error == null)
            {
                var newEntriesCount:uint = ObjectUtil.count(e.data);
                // No entries but no error, last page.
                if (newEntriesCount == 0)
                {
                    page--;
                    maxPage = page;
                }
                // Less then 10 entries, most likely the last page.
                else if (newEntriesCount < 10)
                {
                    maxPage = page;
                }
            }
            renderHighscores();
        }

        private function refreshPersonalRanks():void
        {
            var infoRanks:Object = _gvars.activeUser.getLevelRank(songInfo);
            myUsernameText.text = "#" + infoRanks.rank + ": " + _gvars.activeUser.name;
            myScoreText.text = NumberUtil.numberFormat(infoRanks.rawscore);
            myAVText.text = infoRanks.results;
        }

        override public function stageRemove():void
        {
            prevBtn.dispose();
            nextBtn.dispose();
            closeBtn.dispose();
            refreshBtn.dispose();

            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == prevBtn)
            {
                if (page > 0)
                {
                    page--;
                    renderHighscores();
                }
            }
            if (e.target == nextBtn)
            {
                page++;
                renderHighscores();
            }
            if (e.target == refreshBtn)
            {
                _gvars.clearHighscores();
                _gvars.activeUser.loadLevelRanks();
                refreshPersonalRanks();
                renderHighscores();
            }

            //- Close
            if (e.target == closeBtn)
            {
                removePopup();
                return;
            }
        }
    }
}
