package classes.mp.components
{
    import classes.Language;
    import classes.mp.MPColors;
    import classes.mp.MPUser;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCRoomMessage;
    import classes.mp.components.chatlog.MPChatLogEntry;
    import classes.mp.components.chatlog.MPChatLogEntryText;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.room.MPRoom;
    import classes.ui.BoxText;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.Text;
    import com.flashfla.utils.StringUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;

    public class MPViewChatLogRoom extends Sprite
    {
        private static const _lang:Language = Language.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;

        private static const HISTORY_LIMIT:int = 200;
        private const DATE:Date = new Date();

        private var _width:Number = 0;
        private var _height:Number = 0;

        private var room:MPRoom;
        private var user:MPUser;

        private var displayName:String;

        private var messagePlaceholderLeft:Text;
        private var messagePlaceholderRight:Text;
        private var messageText:BoxText;
        private var _last_message_text:String = "";

        private var pane:ScrollPane;

        private const scrollbarWidth:Number = 15;
        private var scrollbar:ScrollBar;

        private var _cachePositions:Vector.<CLItemCache> = new <CLItemCache>[];

        public function MPViewChatLogRoom(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, wid:Number = 0, hei:Number = 0):void
        {
            this.x = xpos;
            this.y = ypos;

            this._width = wid;
            this._height = hei;

            if (parent)
                parent.addChild(this);

            build();
        }

        /**
         * Init Chat Log for Room based views.
         * @param room
         */
        public function setRoom(room:MPRoom):void
        {
            this.room = room;
            this.displayName = room.name;

            messagePlaceholderLeft.text = sprintf(_lang.string("mp_room_chat_message_room"), {"name": displayName});

            // Add Initial Joining Message
            const joinLogItem:MPChatLogEntry = new MPChatLogEntryText("<font color=\"" + MPColors.SYSTEM_MESSAGE_COLOR + "\">" + sprintf(_lang.string("mp_room_chat_room_join"), {"name": room.name}) + "</font>");
            joinLogItem.build(pane.width - 1);
            _cachePositions.push(new CLItemCache(joinLogItem, 5, joinLogItem.height));
            addPaneChild(joinLogItem);
        }

        public function build():void
        {
            // Chat Log
            pane = new ScrollPane(this, 1, 1, _width - scrollbarWidth - 1, _height - 31, e_mouseWheelHandler);
            scrollbar = new ScrollBar(this, _width - scrollbarWidth, 1, scrollbarWidth, _height - 1, null, new Sprite(), e_scrollbarUpdater);
            scrollbar.draggerVisibility = false;

            // Chat Send
            messagePlaceholderRight = new Text(this, _width - 173, _height - 30, _lang.string("mp_room_chat_message_hint"));
            messagePlaceholderRight.setAreaParams(150, 30, "right");
            messagePlaceholderRight.alpha = 0.35;

            messagePlaceholderLeft = new Text(this, 10, _height - 30, "");
            messagePlaceholderLeft.setAreaParams(_width - messagePlaceholderRight.textfield.textWidth - 45, 30, "left");
            messagePlaceholderLeft.alpha = 0.35;

            messageText = new BoxText(this, 0, _height - 30, _width - scrollbarWidth - 2, 29);
            messageText.borderAlpha = 0;
            messageText.borderActiveAlpha = 0;
            messageText.field.y += 2;
            messageText.field.maxChars = 500;
            messageText.addEventListener(Event.CHANGE, e_onMessageType, false, 0, true);

            // Graphics
            redraw();
        }

        private function redraw():void
        {
            this.graphics.clear();

            // Scrollbar BG
            this.graphics.lineStyle(0, 0, 0);
            this.graphics.beginFill(0xFFFFFF, 0.05);
            this.graphics.drawRect(_width - scrollbarWidth, 1, scrollbarWidth, _height - 1);
            this.graphics.endFill();
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);

            // Scrollbar
            this.graphics.moveTo(_width - scrollbarWidth - 1, 1);
            this.graphics.lineTo(_width - scrollbarWidth - 1, _height);

            // Chat
            this.graphics.moveTo(1, _height - 30);
            this.graphics.lineTo(_width - scrollbarWidth - 1, _height - 30);
        }

        public function onKeyInput(e:KeyboardEvent):void
        {
            if (e.keyCode == Keyboard.ENTER && e.target == messageText.field)
            {
                _mp.sendCommand(new MPCRoomMessage(room, _last_message_text));
                _last_message_text = "";
                messageText.text = "";
                messagePlaceholderRight.visible = messagePlaceholderLeft.visible = true;
            }
        }

        private function e_onMessageType(e:Event):void
        {
            _last_message_text = messageText.text;
            messagePlaceholderRight.visible = messagePlaceholderLeft.visible = (_last_message_text.length <= 0);
        }

        public function onChatMessage(e:MPRoomEvent):void
        {
            var data:Object = e.command.data;

            DATE.setTime(data.timestamp);

            var type:Number = data.type;
            var color:String = (type == MPChatTypes.ADMIN ? MPColors.MESSAGE_ADMIN_COLOR : (type == MPChatTypes.MOD ? MPColors.MESSAGE_MOD_COLOR : MPColors.MESSAGE_COLOR));

            var message:String = "";

            message += "<font color=\"" + MPColors.TIMESTAMP_COLOR + "\">" + StringUtil.pad(DATE.getHours().toString(), 2, "0") + ":" + StringUtil.pad(DATE.getMinutes().toString(), 2, "0") + "</font> ";

            if (type == MPChatTypes.SYSTEM)
            {
                message += "<font face=\"" + Fonts.BASE_FONT + "\" color=\"" + MPColors.SYSTEM_MESSAGE_COLOR + "\"><i>" + data.message + "</i></font>";
            }
            else
            {
                message += e.user.nameHTML + ":  ";
                message += "<font color=\"" + color + "\">" + data.message + "</font>";
            }

            addItem(new MPChatLogEntryText(message));
        }

        public function addItem(entry:MPChatLogEntry):void
        {
            // Build Item Elements
            entry.build(pane.width - 1);

            // Get Start and End Y Positions
            const startY:int = _cachePositions[_cachePositions.length - 1].endY;
            const endY:int = startY + entry.height;
            _cachePositions.push(new CLItemCache(entry, startY, endY));

            // Add to Pane
            entry.y = startY;
            addPaneChild(entry);

            scrollbar.draggerVisibility = endY > pane.height;
        }

        private function addPaneChild(entry:MPChatLogEntry):void
        {
            const lastScrollPosition:Number = scrollbar.scroll;
            const lastCacheItem:CLItemCache = _cachePositions[_cachePositions.length - 1];
            const shouldScrollStart:Boolean = lastCacheItem.startY < pane.height && lastCacheItem.endY > pane.height; // Item crosses height bounds.
            var yShiftValue:int = 0;

            if (_cachePositions.length > HISTORY_LIMIT)
            {
                while (_cachePositions.length > HISTORY_LIMIT)
                {
                    pane.content.removeChild(_cachePositions[0].entry);
                    _cachePositions.shift();
                }

                yShiftValue = _cachePositions[0].startY;

                // Reposition All Items
                var historyItem:CLItemCache;
                var lastY:int = 0;
                for (var i:int = 0; i < HISTORY_LIMIT; i++)
                {
                    historyItem = _cachePositions[i];
                    historyItem.startY = lastY;
                    historyItem.endY = lastY + historyItem.entry.height;
                    historyItem.entry.y = lastY;
                    historyItem.entry.visible = false;

                    lastY = historyItem.endY;
                }
            }
            pane.content.addChild(entry);

            // Scroll Newest if near bottom, or scroll has started.
            if (lastScrollPosition > 0.99 || shouldScrollStart)
            {
                pane.update();

                pane.scrollTo(1);
                scrollbar.scrollTo(1);
            }
            // Keep Scroll position when adding/removing items.
            else
            {
                pane.content.y += yShiftValue;

                if (pane.content.y > 0)
                    pane.content.y = 0;

                pane.update();

                scrollbar.scrollTo(-pane.content.y / (pane.content.height - pane.height));
            }
        }

        /**
         * Mouse Wheel Handler for the Chat Log Pane.
         * Moves the scroll pane based on the scroll delta direction.
         * @param e
         */
        private function e_mouseWheelHandler(e:MouseEvent):void
        {
            // Sanity
            if (!scrollbar.draggerVisibility)
                return;

            // Scroll
            const newScrollPosition:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(newScrollPosition);
            scrollbar.scrollTo(newScrollPosition);
        }

        private function e_scrollbarUpdater(e:Event):void
        {
            pane.scrollTo(e.target.scroll);
        }
    }
}

import classes.mp.components.chatlog.MPChatLogEntry;

internal class CLItemCache
{
    public var startY:Number;
    public var endY:Number;
    public var entry:MPChatLogEntry;

    public function CLItemCache(entry:MPChatLogEntry, startY:Number, endY:Number):void
    {
        this.startY = startY;
        this.endY = endY;
        this.entry = entry;
    }
}
