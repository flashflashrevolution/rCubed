package menu
{
    import assets.menu.ScrollBackground;
    import assets.menu.ScrollDragger;
    import assets.menu.SongSelectionBackground;
    import classes.Language;
    import classes.Playlist;
    import com.flashfla.components.ScrollBar;
    import com.flashfla.components.ScrollPane;
    import com.flashfla.utils.ObjectUtil;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class MenuStats extends MenuPanel
    {
        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _playlist:Playlist = Playlist.instanceCanon;

        private var background:Sprite;
        private var scrollbar:ScrollBar;
        private var pane:ScrollPane;
        private var statBoxItems:Array; // Vector.<FriendItem>;

        public var options:Object;
        public var isLoading:Boolean = false;

        public function MenuStats(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():void
        {
            //- Setup Settings
            options = new Object();
            options.activeIndex = -1;
            options.totalItems = 0;

            //- Add Background
            background = new SongSelectionBackground();
            background.x = 145;
            background.y = 52;
            this.addChild(background);

            //- Add ScrollPane
            pane = new ScrollPane(578, 351);
            pane.x = 155; // 332
            pane.y = 64;
            var border:Sprite = new Sprite();
            border.graphics.lineStyle(1, 0xFFFFFF, 1, true);
            border.graphics.lineTo(578, 0);
            border.graphics.moveTo(0, 350);
            border.graphics.lineTo(578, 350);
            border.alpha = 0.35;
            pane.addChild(border);
            this.addChild(pane);

            //- Add ScrollBar
            scrollbar = new ScrollBar(21, 325, new ScrollDragger(), new ScrollBackground());
            scrollbar.x = 744;
            scrollbar.y = 81;
            this.addChild(scrollbar);

            //- Add Content
            buildStats();
        }

        override public function dispose():void
        {
            if (pane)
            {
                pane.dispose();
                this.removeChild(pane);
                pane = null;
            }
            super.dispose();
        }

        override public function stageAdd():void
        {
            //- Add Listeners
            if (stage)
            {
                scrollbar.addEventListener(Event.CHANGE, scrollBarMoved, false, 0, false);
                pane.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMoved, false, 0, false);
            }
        }

        override public function stageRemove():void
        {
            //- Remove Listeners
            if (stage)
            {
                scrollbar.removeEventListener(Event.CHANGE, scrollBarMoved, false);
                pane.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMoved, false);
            }
        }

        public function buildStats():void
        {
            //- Clear out old MC in content pane
            scrollbar.reset();
            pane.clear();

            statBoxItems = [];
            var yOffset:int = 0;
            var sI:StatItem;
            var sX:int = 0;
            for (var sO:String in _gvars.playerUser.level_ranks)
            {
                var song:Object = _playlist.getSong(Number(sO));
                if (song.error != null)
                    continue;
                sI = new StatItem(_gvars.playerUser.level_ranks[sO], song);
                sI.y = yOffset;
                sI.index = sX;
                sI.addEventListener(MouseEvent.CLICK, statItemClick, false, 0, true);
                pane.content.addChild(sI);
                statBoxItems[statBoxItems.length] = sI;
                yOffset += 57;
                sX += 1;
            }
            options.totalItems = sX;
            pane.scrollTo(scrollbar.scroll, false);
            scrollbar.draggerVisibility = (yOffset > pane.height);
        }

        private function statItemClick(e:Event = null):void
        {
            // Set Active
            if (options.activeIndex != e.target.index)
            {
                options.activeIndex = e.target.index;
            }
            else if (options.activeIndex == e.target.index)
            {
                options.activeIndex = -1;
            }
            //buildStats();
        }

        private function mouseWheelMoved(e:MouseEvent):void
        {
            var dist:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(dist);
            scrollbar.scrollTo(dist);
        }

        private function scrollBarMoved(e:Event):void
        {
            pane.scrollTo(e.target.scroll, false);
        }
    }
}
