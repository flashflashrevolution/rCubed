package classes.mp.components
{
    import classes.Language;
    import classes.mp.MPUser;
    import classes.mp.Multiplayer;
    import classes.mp.events.MPPMSelect;
    import classes.mp.pm.MPUserChatHistory;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class MPViewUserListPM extends Sprite
    {
        private static const _mp:Multiplayer = Multiplayer.instance;
        private static const _lang:Language = Language.instance;

        private var _width:Number = 200;
        private var _height:Number = 388;

        private var pane:ScrollPane;

        private const scrollbarWidth:Number = 15;
        private var scrollbar:ScrollBar;
        private var scrollbarBG:Sprite;

        private const labelHeight:Number = 27;
        private var userLabels:Vector.<UserLabel> = new <UserLabel>[];

        public function MPViewUserListPM(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0):void
        {
            this.x = xpos;
            this.y = ypos;

            if (parent)
                parent.addChild(this);

            build();
        }

        public function build():void
        {
            new Text(this, 5, 0, _lang.string("mp_user_list"), 16, "#FFFFFF").setAreaParams(_width - 10, 30);

            pane = new ScrollPane(this, 0, 31, _width, _height - 31, e_scrollMouseWheel);
            pane.addEventListener(MouseEvent.CLICK, e_onUserClick);

            // Scroll Bar
            scrollbarBG = new Sprite();
            scrollbarBG.x = _width - scrollbarWidth;
            scrollbarBG.y = 31;
            addChild(scrollbarBG);

            scrollbar = new ScrollBar(this, _width - scrollbarWidth, 31, scrollbarWidth, _height - 31, null, new Sprite(), e_scrollbarUpdater);

            // Graphics
            redraw();
        }

        public function redraw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(0, 0, 0);

            // BG
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();

            // Title BG
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, 0, _width, 30);
            this.graphics.endFill();

            // Borders
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.moveTo(0, 0);
            this.graphics.lineTo(_width, 0);
            this.graphics.lineTo(_width, _height);
            this.graphics.lineTo(0, _height);

            // Title
            this.graphics.moveTo(0, 30);
            this.graphics.lineTo(_width, 30);

            // Scroll BG
            scrollbarBG.graphics.clear();

            scrollbarBG.graphics.lineStyle(0, 0, 0);
            scrollbarBG.graphics.beginFill(0xFFFFFF, 0.05);
            scrollbarBG.graphics.drawRect(0, 0, scrollbarWidth, _height - 31);
            scrollbarBG.graphics.endFill();

            scrollbarBG.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            scrollbarBG.graphics.moveTo(-1, 0);
            scrollbarBG.graphics.lineTo(-1, _height - 31);
        }

        public function update():void
        {
            var my:Number = 0;

            var userLabel:UserLabel;
            var chat:MPUserChatHistory;

            for each (chat in _mp.pms)
            {
                userLabel = getUserLabel(chat);
                userLabel.y = my;
                userLabel.update();
                my += labelHeight;
            }

            pane.update();

            // Check for Change in Scrollbar appearence, recalculate widths if needed.
            var oldScrollbarVisible:Boolean = scrollbar.visible;
            scrollbarBG.visible = scrollbar.visible = (pane.content.height > pane.height - 5);

            if (oldScrollbarVisible != scrollbar.visible)
            {
                userLabels.forEach(_setSize);
            }
        }

        public function updateUnread():void
        {
            userLabels.forEach(_setUnread);
        }

        private function _setSize(item:UserLabel, index:int = 0, vector:Vector.<*> = null):void
        {
            item.setSize(_width - (scrollbar.visible ? scrollbarWidth + 1 : 0), labelHeight);
        }

        private function _setUnread(item:UserLabel, index:int = 0, vector:Vector.<*> = null):void
        {
            item.update();
        }

        private function _markUnactive(item:UserLabel, index:int = 0, vector:Vector.<*> = null):void
        {
            item.setActive(false);
        }

        private function e_onUserClick(e:MouseEvent):void
        {
            if (e.target is UserLabel)
            {
                userLabels.forEach(_markUnactive);

                const label:UserLabel = e.target as UserLabel;
                label.chat.newMessage = false;
                label.setActive(true);
                label.update();

                dispatchEvent(new MPPMSelect(label.chat));
            }
        }

        private function e_scrollMouseWheel(e:MouseEvent):void
        {
            if (!scrollbar.visible)
                return;

            var dist:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(dist);
            scrollbar.scrollTo(dist);
        }

        private function e_scrollbarUpdater(e:Event):void
        {
            if (!scrollbar.visible)
                return;

            pane.scrollTo(e.target.scroll);
        }

        override public function set width(value:Number):void
        {
            _width = value;
            redraw();
        }

        override public function get width():Number
        {
            return _width;
        }

        override public function set height(value:Number):void
        {
            _height = height;
            redraw();
        }

        override public function get height():Number
        {
            return _height;
        }

        // //////
        // Object Pool
        private function getUserLabel(chat:MPUserChatHistory):UserLabel
        {
            for each (var label:UserLabel in userLabels)
            {
                if (chat === label.chat)
                {
                    return label;
                }
            }

            var newLabel:UserLabel = new UserLabel(chat);
            pane.content.addChild(newLabel);
            userLabels.push(newLabel);
            _setSize(newLabel);

            return newLabel;
        }
    }
}

import assets.menu.icons.fa.iconRight;
import classes.Language;
import classes.mp.MPUser;
import classes.mp.Multiplayer;
import classes.mp.pm.MPUserChatHistory;
import classes.ui.Text;
import com.greensock.TweenLite;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

internal class UserLabel extends Sprite
{
    protected static const _mp:Multiplayer = Multiplayer.instance;
    protected static const _lang:Language = Language.instance;

    protected var _width:Number = 184;
    protected var _height:Number = 27;

    public var chat:MPUserChatHistory;
    public var user:MPUser;
    public var messageDot:Sprite;
    private var chevron:iconRight;

    protected var nameText:Text;

    private var active:Boolean = false;
    private var hover:Boolean = false;

    public function UserLabel(chat:MPUserChatHistory):void
    {
        this.chat = chat;
        this.user = chat.user;

        this.buttonMode = true;
        this.mouseChildren = false;

        build();
        draw();
    }

    protected function build():void
    {
        nameText = new Text(this, 5, 0, user.userLabelHTML, 11, "#FFFFFF");
        nameText.setAreaParams(_width - 11, _height);
        nameText.cacheAsBitmap = true;

        messageDot = new Sprite();
        messageDot.graphics.beginFill(0xffaa42);
        messageDot.graphics.drawCircle(0, 0, 4);
        messageDot.graphics.endFill();
        messageDot.visible = chat.newMessage;
        addChild(messageDot);

        chevron = new iconRight();
        chevron.x = 9;
        chevron.y = _height / 2 + 0.5;
        chevron.scaleX = chevron.scaleY = 0.15;
        chevron.visible = false;
        addChild(chevron);

        this.addEventListener(MouseEvent.ROLL_OVER, e_showHover);
        this.addEventListener(MouseEvent.ROLL_OUT, e_hideHover);
    }

    protected function draw():void
    {
        this.graphics.clear();
        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.moveTo(0, _height);
        this.graphics.lineTo(_width, _height);

        this.graphics.lineStyle(0, 0x000000, 0);
        this.graphics.beginFill(0xFFFFFF, (active && hover ? 0.15 : (hover || active ? 0.08 : 0)));
        this.graphics.drawRect(0, 0, _width, _height);
        this.graphics.endFill();
    }

    public function setSize(w:Number, h:Number):void
    {
        _width = w;
        _height = h;
        resize();
    }

    protected function resize():void
    {
        draw();
        scrollRect = new Rectangle(0, 0, _width + 1, _height + 1);
        nameText.width = nameText.x - 5;
        messageDot.x = _width - 10;
        messageDot.y = _height / 2;
    }

    public function update():void
    {
        messageDot.visible = chat.newMessage;
    }

    public function setActive(newState:Boolean):void
    {
        if (this.active != newState)
        {
            TweenLite.to(nameText, 0.25, {"x": (newState ? 15 : 5)});
            this.active = newState;
            this.chevron.visible = newState;
            draw();
        }
    }

    private function e_showHover(e:MouseEvent):void
    {
        hover = true;
        draw();
    }

    private function e_hideHover(e:MouseEvent):void
    {
        hover = false;
        draw();
    }
}
