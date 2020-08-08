package menu
{
    import assets.menu.GenreSelection;
    import assets.menu.ScrollBackground;
    import assets.menu.ScrollDragger;
    import assets.menu.SongSelectionBackground;
    import classes.Friends;
    import classes.Language;
    import classes.Text;
    import com.flashfla.components.ScrollBar;
    import com.flashfla.components.ScrollPane;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class MenuFriends extends MenuPanel
    {
        ///- Private Locals
        private var _friends:Friends = Friends.instance;
        private var _lang:Language = Language.instance;

        private var background:Sprite;
        private var scrollbar:ScrollBar;
        private var pane:ScrollPane;
        private var friendBoxItems:Array; // Vector.<FriendItem>;
        private var selectedGenre:Sprite;
        private var refreshButton:Text;

        public var isLoading:Boolean = false;

        public function MenuFriends(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
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

            // Sidebar Menu
            selectedGenre = new GenreSelection();
            selectedGenre.x = 5;
            selectedGenre.y = 120;
            this.addChild(selectedGenre);

            refreshButton = new Text("Refresh", 14);
            refreshButton.x = 5;
            refreshButton.y = 122;
            refreshButton.height = 22.6;
            refreshButton.width = 130.75;
            refreshButton.mouseChildren = false;
            refreshButton.useHandCursor = true;
            refreshButton.buttonMode = true;
            refreshButton.addEventListener(MouseEvent.CLICK, refreshClick);
            this.addChild(refreshButton);

            //- Add Content
            buildFriends();

            return true;
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

        public function buildFriends():void
        {
            //- Clear out old MC in content pane
            scrollbar.reset();
            pane.clear();

            friendBoxItems = []; // new Vector.<FriendItem>;
            var friendsLength:int = _friends.list.length;
            _friends.list.sortOn(["state", "user"], [Array.NUMERIC, Array.CASEINSENSITIVE]);
            var yOffset:int = 0;
            var sI:FriendItem;
            for (var sX:int = 0; sX < friendsLength; sX++)
            {
                sI = new FriendItem(_friends.list[sX]);
                sI.y = yOffset + 30 * sX;
                pane.content.addChild(sI);
                friendBoxItems[friendBoxItems.length] = sI;
            }
            pane.scrollTo(scrollbar.scroll, false);
            scrollbar.visible = (pane.content.height > pane.height);
        }

        private function refreshClick(e:MouseEvent = null):void
        {
            if (!isLoading)
            {
                _friends.addEventListener(GlobalVariables.LOAD_COMPLETE, friendScriptLoad);
                _friends.addEventListener(GlobalVariables.LOAD_ERROR, friendScriptLoad);
                _friends.load();
                isLoading = true;
            }
        }

        private function friendScriptLoad(e:Event):void
        {
            _friends.removeEventListener(GlobalVariables.LOAD_COMPLETE, friendScriptLoad);
            _friends.removeEventListener(GlobalVariables.LOAD_ERROR, friendScriptLoad);
            isLoading = false;
            buildFriends();
        }

        private function mouseWheelMoved(e:MouseEvent):void
        {
            var dist:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(dist);
            scrollbar.scrollTo(dist);
        }

        private function scrollBarMoved(e:Event):void
        {
            pane.scrollTo(e.target.scroll);
        }
    }
}
