package classes.mp.views
{
    import assets.menu.icons.fa.iconClose;
    import assets.menu.icons.fa.iconEye;
    import assets.menu.icons.fa.iconRefresh;
    import assets.menu.icons.fa.iconUsers;
    import classes.Alert;
    import classes.mp.MPView;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCRoomJoinCode;
    import classes.mp.components.browser.MPBrowserEntry;
    import classes.mp.components.browser.MPBrowserScrollpane;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.events.MPViewEvent;
    import classes.mp.room.MPRoom;
    import classes.ui.BoxButton;
    import classes.ui.BoxCheck;
    import classes.ui.BoxIcon;
    import classes.ui.BoxText;
    import classes.ui.Prompt;
    import classes.ui.PromptInput;
    import classes.ui.ScrollBar;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    public class MPServerBrowserView extends MPView
    {
        private var _width:Number = 610;
        private var _height:Number = 388;

        private var pane:MPBrowserScrollpane;

        private const scrollbarWidth:Number = 15;
        private var scrollbar:ScrollBar;

        private static var loadFirstTime:Boolean = false;
        private var refreshLockoutTimer:Timer;
        private var refreshLockout:Boolean = false;
        private var thobber:Throbber;

        private var search_field:BoxText;
        private var search_field_placeholder:Text;
        private var _search_text:String = "";

        private var showPrivateCheck:BoxCheck;

        private var btnCreateRoom:BoxButton;
        private var btnJoinCode:BoxIcon;
        private var btnRefreshRooms:BoxIcon;

        private var _createRoomPrompt:RoomCreatePrompt;
        private var _roomPasswordPrompt:RoomPasswordPrompt;
        private var _joinViaCodePrompt:PromptInput;

        public function MPServerBrowserView(parent:DisplayObjectContainer, xpos:Number = 0, ypos:Number = 0):void
        {
            super(parent, xpos, ypos);

            addRoomEvents();
            build();
        }

        public function addRoomEvents():void
        {
            _mp.addEventListener(MPEvent.SYS_ROOM_LIST, e_onRoomList);
        }

        override public function dispose():void
        {
            setBlocker(false);

            if (_createRoomPrompt)
            {
                _createRoomPrompt.close();
                _createRoomPrompt = null;
            }

            if (_roomPasswordPrompt)
            {
                _roomPasswordPrompt.close();
                _roomPasswordPrompt = null;
            }

            if (_roomPasswordPrompt)
            {
                _roomPasswordPrompt.close();
                _roomPasswordPrompt = null;
            }

            _mp.removeEventListener(MPEvent.SYS_ROOM_LIST, e_onRoomList);
        }

        override public function build():void
        {
            super.build();

            pane = new MPBrowserScrollpane(this, 6, 1, _width - scrollbarWidth - 6, _height - 50);
            pane.addEventListener(MouseEvent.MOUSE_WHEEL, e_mouseWheelHandler, false, 0, false);
            pane.addEventListener(MouseEvent.CLICK, e_roomEntryClick);

            scrollbar = new ScrollBar(this, _width - scrollbarWidth, 1, scrollbarWidth, pane.height, null, new Sprite(), e_scrollbarUpdater);
            scrollbar.draggerVisibility = false;

            refreshLockoutTimer = new Timer(2500, 1);
            refreshLockoutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_lockoutFinish);

            thobber = new Throbber();
            thobber.x = pane.x + pane.width / 2;
            thobber.y = pane.y + pane.height / 2;
            thobber.start();

            // Search
            search_field_placeholder = new Text(this, 10, _height - 32, _lang.string("mp_room_search"));
            search_field_placeholder.setAreaParams(190, 27, "left");
            search_field_placeholder.alpha = 0.6;

            search_field = new BoxText(this, 5, _height - 35, 190, 29);
            search_field.addEventListener(Event.CHANGE, e_searchChange, false, 0, true);
            search_field.field.y += 1;

            // Password
            new Text(this, 204 + 22, _height - 30, _lang.string("mp_room_list_show_private"));
            showPrivateCheck = new BoxCheck(this, 204 + 2, _height - 27, clickHandler);

            btnCreateRoom = new BoxButton(this, _width - 196, _height - 33, 120, 26, _lang.string("mp_room_list_create_room"), 12, clickHandler);

            // Join Code
            btnJoinCode = new BoxIcon(this, _width - 68, _height - 33, 26, 26, new iconUsers(), clickHandler);
            btnJoinCode.setHoverText(_lang.string("mp_room_list_join_code"));

            btnRefreshRooms = new BoxIcon(this, _width - 34, _height - 33, 26, 26, new iconRefresh(), clickHandler);
            btnRefreshRooms.setHoverText(_lang.string("mp_room_list_refresh"));

            // Graphics
            redraw();

            // Add Room Entries
            updateList();
        }

        public function redraw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(0, 0, 0);

            // BG
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, 0, _width, _height - 49);
            this.graphics.endFill();

            // Scrollbar BG
            this.graphics.lineStyle(0, 0, 0);
            this.graphics.beginFill(0xFFFFFF, 0.05);
            this.graphics.drawRect(_width - scrollbarWidth, 1, scrollbarWidth, _height - 50);
            this.graphics.endFill();
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);

            // Scrollbar
            this.graphics.moveTo(_width - scrollbarWidth - 1, 1);
            this.graphics.lineTo(_width - scrollbarWidth - 1, _height - 49);

            // Search / Filter
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, _height - 40, _width, 40);
            this.graphics.endFill();
        }

        override public function onSelect():void
        {
            if (!refreshLockout)
            {
                refreshRoomList();
                if (!loadFirstTime)
                {
                    pane.visible = false;
                    thobber.visible = true;
                    thobber.start();
                    loadFirstTime = true;
                }
            }
        }

        private function refreshRoomList():void
        {
            if (!refreshLockout)
            {
                refreshLockout = true;
                _mp.updateRoomList();
                refreshLockoutTimer.start();
            }
        }

        public function e_onRoomList(e:MPEvent):void
        {
            pane.visible = true;
            thobber.visible = false;
            thobber.stop();
            updateList();
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

        private function e_lockoutFinish(e:TimerEvent):void
        {
            refreshLockout = false;
            refreshLockoutTimer.reset();
        }

        public function e_roomEntryClick(e:MouseEvent):void
        {
            var te:* = e.target;
            if (te is MPBrowserEntry)
            {
                var entry:MPBrowserEntry = te as MPBrowserEntry;

                if (entry.room == _mp.GAME_ROOM)
                {
                    _mp.dispatchEvent(new MPViewEvent("menu_game"));
                    return;
                }

                if (_mp.inGameRoom)
                {
                    Alert.add(_lang.string("mp_error_multiple_room_restriction"), 120, Alert.RED);
                    return;
                }

                if (entry.room.hasPassword && !_mp.currentUser.permissions.mod)
                {
                    _roomPasswordPrompt = new RoomPasswordPrompt(entry.room, stage, _lang.string("mp_room_join_password_title"), _lang.string("mp_room_join_password_join"), e_roomPasswordConfirm);
                    _roomPasswordPrompt.addEventListener(Event.CLOSE, e_roomPasswordPromptClose);
                }
                else
                {
                    setBlocker(true);
                    _mp.addEventListener(MPEvent.ROOM_JOIN_OK, e_roomJoinOK);
                    _mp.addEventListener(MPEvent.ROOM_JOIN_FAIL, e_roomJoinFail);
                    _mp.joinRoom(entry.room);
                }
            }
        }

        private function e_searchChange(e:Event):void
        {
            _search_text = search_field.text.toLowerCase();
            search_field_placeholder.visible = (_search_text.length <= 0);

            updateList();
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == showPrivateCheck)
            {
                showPrivateCheck.checked = !showPrivateCheck.checked;
                updateList();
            }
            else if (e.target == btnRefreshRooms)
            {
                refreshRoomList();
            }
            else if (e.target == btnCreateRoom)
            {
                _createRoomPrompt = new RoomCreatePrompt(this, stage);
                _createRoomPrompt.addEventListener(Event.CLOSE, e_onCreateClose);
            }
            else if (e.target == btnJoinCode)
            {
                _joinViaCodePrompt = new PromptInput(stage, _lang.string("mp_room_join_code_title"), _lang.string("mp_room_join_code_join"), e_joinCodeConfirm);
            }
        }

        private function e_roomJoinOK(e:MPRoomEvent):void
        {
            setBlocker(false);
            _mp.removeEventListener(MPEvent.ROOM_JOIN_OK, e_roomJoinOK);
            _mp.removeEventListener(MPEvent.ROOM_JOIN_FAIL, e_roomJoinFail);
        }

        private function e_roomJoinFail(e:MPEvent):void
        {
            setBlocker(false);
            _mp.removeEventListener(MPEvent.ROOM_JOIN_OK, e_roomJoinOK);
            _mp.removeEventListener(MPEvent.ROOM_JOIN_FAIL, e_roomJoinFail);
        }

        private function e_roomPasswordConfirm(password:String):void
        {
            setBlocker(true);
            _mp.addEventListener(MPEvent.ROOM_JOIN_OK, e_roomPasswordJoinOK);
            _mp.addEventListener(MPEvent.ROOM_JOIN_FAIL, e_roomPasswordJoinFail);
            _mp.joinRoom(_roomPasswordPrompt.room, password);
        }

        private function e_roomPasswordPromptClose(e:Event):void
        {
            _roomPasswordPrompt.removeEventListener(Event.CLOSE, e_roomPasswordPromptClose);
            _roomPasswordPrompt = null;
        }

        private function e_roomPasswordJoinOK(e:MPRoomEvent):void
        {
            setBlocker(false);
            _roomPasswordPrompt = null;
            _mp.removeEventListener(MPEvent.ROOM_JOIN_OK, e_roomPasswordJoinOK);
            _mp.removeEventListener(MPEvent.ROOM_JOIN_FAIL, e_roomPasswordJoinFail);
        }

        private function e_roomPasswordJoinFail(e:MPEvent):void
        {
            setBlocker(false);
            _mp.removeEventListener(MPEvent.ROOM_JOIN_OK, e_roomPasswordJoinOK);
            _mp.removeEventListener(MPEvent.ROOM_JOIN_FAIL, e_roomPasswordJoinFail);
        }

        private function e_joinCodeConfirm(code:String):void
        {
            setBlocker(true);
            _mp.addEventListener(MPEvent.ROOM_JOIN_OK, e_roomJoinOK);
            _mp.addEventListener(MPEvent.ROOM_JOIN_FAIL, e_roomJoinFail);
            _mp.sendCommand(new MPCRoomJoinCode(code));
        }

        private function updateList():void
        {
            var render_list:Array = [];
            for each (var r:MPRoom in _mp.rooms)
            {
                if (!r.isGame || Multiplayer.VALID_GAME_TYPES.indexOf(r.type) == -1)
                    continue;

                if (_search_text.length >= 1 && r.name.toLowerCase().indexOf(_search_text) == -1)
                    continue;

                if (!showPrivateCheck.checked && r.hasPassword)
                    continue;

                render_list[render_list.length] = r;
            }
            pane.setRenderList(render_list);
            updateScrollPane();
        }

        public function updateScrollPane():void
        {
            pane.scrollTo(0);
            scrollbar.scrollTo(0);

            scrollbar.draggerVisibility = pane.doScroll;
        }

        private function e_onCreateClose(e:Event):void
        {
            _createRoomPrompt.close();
            _createRoomPrompt = null;
        }

    }
}

import assets.menu.icons.fa.iconClose;
import assets.menu.icons.fa.iconEye;
import classes.Language;
import classes.mp.MPModes;
import classes.mp.Multiplayer;
import classes.mp.commands.MPCRoomCreate;
import classes.mp.events.MPEvent;
import classes.mp.events.MPRoomEvent;
import classes.mp.room.MPRoom;
import classes.mp.views.MPServerBrowserView;
import classes.ui.BoxButton;
import classes.ui.BoxCheck;
import classes.ui.BoxIcon;
import classes.ui.BoxText;
import classes.ui.Prompt;
import classes.ui.PromptInput;
import classes.ui.Text;
import com.bit101.components.ComboBox;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;

internal class RoomCreatePrompt extends Prompt
{
    private static const _gvars:GlobalVariables = GlobalVariables.instance;
    private static const _lang:Language = Language.instance;
    private static const _mp:Multiplayer = Multiplayer.instance;

    private var win:MPServerBrowserView;

    private var box:Sprite;

    private var roomName:BoxText;
    private var roomPassword:BoxText;
    private var showPassword:BoxIcon;

    private var closeButton:BoxIcon;
    private var confirmButton:BoxButton;

    private var teamModes:ComboBox;

    private var maxPlayersText:Text;
    private var maxPlayers:ComboBox;

    private var maxTeamsText:Text;
    private var maxTeams:ComboBox;
    private var maxPlayersPerTeamText:Text;
    private var maxPlayersPerTeam:ComboBox;

    public function RoomCreatePrompt(win:MPServerBrowserView, stage:Stage):void
    {
        super(stage, 460, 328);
        this.win = win;

        _content.graphics.moveTo(width / 2, 155);
        _content.graphics.lineTo(width / 2, 318);

        new Text(this, 10, 10, _lang.string("mp_room_options_create_room"), 16).setAreaParams(width - 45, 22);
        _content.graphics.moveTo(10, 40);
        _content.graphics.lineTo(width - 9, 40);

        closeButton = new BoxIcon(this, _width - 32, 10, 22, 22, new iconClose(), clickHandler);

        new Text(this, 9, 43, _lang.string("mp_room_options_name")).setAreaParams(width - 20, 22);
        roomName = new BoxText(this, 10, 67, width - 21, 22, Constant.TEXT_FORMAT_UNICODE_12);
        roomName.field.y += 1;
        roomName.field.maxChars = 30;

        new Text(this, 9, 95, _lang.string("mp_room_options_password")).setAreaParams(width - 20, 22);
        roomPassword = new BoxText(this, 10, 119, width - 50, 22, Constant.TEXT_FORMAT_UNICODE_12);
        roomPassword.displayAsPassword = true;
        roomPassword.field.y += 1;

        showPassword = new BoxIcon(this, width - 33, 119, 23, 23, new iconEye(), e_togglePassword);

        // Team Mode
        new Text(this, 9, 152, _lang.string("mp_room_options_team_mode")).setAreaParams(width / 2 - 20, 22);
        teamModes = new ComboBox(this, 10, 175, "", MPModes.getTeamModes());
        teamModes.setSize(width / 2 - 20, 25);
        teamModes.fontSize = 11;
        teamModes.selectedIndex = 0;

        // Max Players - FFA
        maxPlayersText = new Text(this, 9, 210, _lang.string("mp_room_options_max_player_count"));
        maxPlayersText.setAreaParams(width / 2 - 20, 22);
        maxPlayersText.visible = false;
        maxPlayers = new ComboBox(this, 10, 233, "", MPModes.getMaxPlayers());
        maxPlayers.setSize(width / 2 - 20, 25);
        maxPlayers.fontSize = 11;
        maxPlayers.selectedIndex = 1;
        maxPlayers.visible = false;

        // Max Teams - Team
        maxTeamsText = new Text(this, 9, 210, _lang.string("mp_room_options_max_team_count"));
        maxTeamsText.setAreaParams(width / 2 - 20, 22);
        maxTeamsText.visible = false;
        maxTeams = new ComboBox(this, 10, 233, "", MPModes.getTeams());
        maxTeams.setSize(width / 2 - 20, 25);
        maxTeams.fontSize = 11;
        maxTeams.selectedIndex = 0;
        maxTeams.visible = false;

        // Max Teams Players - Team
        maxPlayersPerTeamText = new Text(this, 9, 268, _lang.string("mp_room_options_max_team_players"));
        maxPlayersPerTeamText.setAreaParams(width / 2 - 20, 22);
        maxPlayersPerTeamText.visible = false;
        maxPlayersPerTeam = new ComboBox(this, 10, 291, "", MPModes.getTeamMaxPlayers());
        maxPlayersPerTeam.setSize(width / 2 - 20, 25);
        maxPlayersPerTeam.fontSize = 11;
        maxPlayersPerTeam.selectedIndex = 0;
        maxPlayersPerTeam.visible = false;

        // Confirm
        confirmButton = new BoxButton(this, 241, 291, 207, 24, _lang.string("mp_room_options_create"), 12, clickHandler);

        updateTeamMode();

        // Events
        teamModes.addEventListener(Event.SELECT, e_onTeamModeChange);
    }

    private function e_togglePassword(e:Event):void
    {
        roomPassword.displayAsPassword = !roomPassword.displayAsPassword;
    }

    private function e_onTeamModeChange(e:Event):void
    {
        updateTeamMode();
    }

    private function updateTeamMode():void
    {
        switch (teamModes.selectedItem.data)
        {
            case 'ffa':
                maxPlayersText.visible = maxPlayers.visible = true;
                maxTeamsText.visible = maxTeams.visible = false;
                maxPlayersPerTeamText.visible = maxPlayersPerTeam.visible = false;
                break;

            case 'team':
                maxPlayersText.visible = maxPlayers.visible = false;
                maxTeamsText.visible = maxTeams.visible = true;
                maxPlayersPerTeamText.visible = maxPlayersPerTeam.visible = true;
                break;
        }
    }

    private function clickHandler(e:MouseEvent):void
    {
        if (e.target == closeButton)
        {
            dispatchEvent(new Event(Event.CLOSE));
        }
        else if (e.target == confirmButton)
        {
            stage.focus = null;

            uiLock = true;

            _mp.addEventListener(MPEvent.ROOM_CREATE_OK, e_onRoomCreate);
            _mp.addEventListener(MPEvent.ROOM_CREATE_FAIL, e_onRoomFail);

            const cmd:MPCRoomCreate = new MPCRoomCreate();
            cmd.name = roomName.text;
            cmd.password = roomPassword.text;
            cmd.type = "ffr";

            // FFA
            if (teamModes.selectedItem.data == "ffa")
            {
                cmd.team_count = 1;
                cmd.max_players = maxPlayers.selectedItem as Number;
            }
            else if (teamModes.selectedItem.data == "team")
            {
                cmd.team_count = maxTeams.selectedItem as Number;
                cmd.max_players = maxPlayersPerTeam.selectedItem as Number;
            }

            _mp.sendCommand(cmd);
        }
    }

    private function e_onRoomCreate(e:MPRoomEvent):void
    {
        _mp.removeEventListener(MPEvent.ROOM_CREATE_OK, e_onRoomCreate);
        _mp.removeEventListener(MPEvent.ROOM_CREATE_FAIL, e_onRoomFail);
        uiLock = false;
        dispatchEvent(new Event(Event.CLOSE));
    }

    private function e_onRoomFail(e:MPEvent):void
    {
        _mp.removeEventListener(MPEvent.ROOM_CREATE_OK, e_onRoomCreate);
        _mp.removeEventListener(MPEvent.ROOM_CREATE_FAIL, e_onRoomFail);
        uiLock = false;
    }
}

internal class RoomPasswordPrompt extends PromptInput
{
    public var room:MPRoom;

    public function RoomPasswordPrompt(room:MPRoom, parent:DisplayObjectContainer = null, promptTitle:String = "", buttonText:String = "", promptFunc:Function = null)
    {
        this.room = room;
        super(parent, promptTitle, buttonText, promptFunc, true);
    }
}
