package menu
{
    import assets.menu.icons.fa.iconLeft;
    import classes.Alert;
    import classes.Language;
    import classes.mp.MPView;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCLogin;
    import classes.mp.components.MPMenuRoomButton;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.room.MPRoom;
    import classes.mp.room.MPRoomFFR;
    import classes.mp.views.MPRoomView;
    import classes.mp.views.MPRoomViewFFR;
    import classes.mp.views.MPRoomViewLobby;
    import classes.mp.views.MPServerBrowserView;
    import classes.mp.views.MPUserMessagesView;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;

    public class MenuMultiplayer extends MenuPanel
    {
        private static const _gvars:GlobalVariables = GlobalVariables.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;
        private static const _lang:Language = Language.instance;

        private var userMessages:MPUserMessagesView;
        private var roomBrowser:MPServerBrowserView;
        private var lobbyView:MPRoomView;
        private var gameView:MPRoomView;

        private var btnPrivateMessages:BoxButton;
        private var btnServerBrowser:BoxButton;
        private var btnLobbyView:MPMenuRoomButton;
        private var btnGameView:MPMenuRoomButton;
        private var btnConnect:BoxButton;

        private var activeView:MPView;

        private var roomIndicator:iconLeft;

        private var pmAlert:Sprite;
        private var throbber:Throbber;
        private var guestWarning:Text;

        public function MenuMultiplayer(myParent:MenuPanel)
        {
            super(myParent);

            // UI
            btnPrivateMessages = new BoxButton(this, 7, 115, 125, 29, _lang.string("mp_private_messages"), 11, e_onSelectPrivateMessages);
            btnPrivateMessages.visible = false;

            btnServerBrowser = new BoxButton(this, 7, 155, 125, 29, _lang.string("mp_room_browser"), 11, e_onSelectServerBrowser);
            btnServerBrowser.visible = false;

            btnLobbyView = new MPMenuRoomButton(this, 7, 195, 125, 44, e_onSelectLobby);
            btnLobbyView.visible = false;

            btnGameView = new MPMenuRoomButton(this, 7, 250, 125, 44, e_onSelectGame);
            btnGameView.visible = false;

            btnConnect = new BoxButton(this, 7, Main.GAME_HEIGHT - 29, 128, 30, _lang.string("mp_connect"), 12, e_mpToggle);

            guestWarning = new Text(this, 5, 100, _lang.string("mp_error_guest"), 14);
            guestWarning.setAreaParams(Main.GAME_WIDTH - 10, 300, "center");

            throbber = new Throbber();
            throbber.x = Main.GAME_WIDTH / 2;
            throbber.y = Main.GAME_HEIGHT / 2;
            throbber.visible = false;
            addChild(throbber);

            roomIndicator = new iconLeft();
            roomIndicator.scaleX = roomIndicator.scaleY = 0.15;
            roomIndicator.visible = false;
            addChild(roomIndicator);

            pmAlert = new Sprite();
            pmAlert.graphics.beginFill(0xffaa42);
            pmAlert.graphics.drawCircle(0, 0, 4);
            pmAlert.graphics.endFill();
            pmAlert.visible = false;
            pmAlert.x = 118;
            pmAlert.y = 7;
            btnPrivateMessages.addChild(pmAlert);

            // Connect to MP
            if (!Flags.VALUES[Flags.MP_INITAL_LOAD] && !_gvars.playerUser.isGuest)
            {
                Flags.VALUES[Flags.MP_INITAL_LOAD] = true;

                if (!_mp.connected)
                    e_mpToggle();
            }
        }

        override public function stageAdd():void
        {
            if (stage)
            {
                stage.addEventListener(KeyboardEvent.KEY_DOWN, e_onKeyDown);
                btnConnect.enabled = !_gvars.playerUser.isGuest;
                guestWarning.visible = _gvars.playerUser.isGuest;
            }
        }

        override public function stageRemove():void
        {
            if (stage)
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, e_onKeyDown);
        }

        private function e_onKeyDown(e:KeyboardEvent):void
        {
            if (activeView)
                activeView.onKeyInput(e);
        }

        ////////////////////////////////////////////////////////////////

        private function e_onSelectPrivateMessages(e:Event):void
        {
            setActiveView(userMessages, btnPrivateMessages);
            pmAlert.visible = false;
        }

        private function e_onSelectServerBrowser(e:Event):void
        {
            setActiveView(roomBrowser, btnServerBrowser);
        }

        private function e_onSelectLobby(e:Event):void
        {
            setActiveView(lobbyView, btnLobbyView);
        }

        private function e_onSelectGame(e:Event):void
        {
            setActiveView(gameView, btnGameView);
        }

        private function e_mpToggle(event:Event = null):void
        {
            if (!_mp.connected)
            {
                _mp.clearEvents();

                // Setup MP Events
                _mp.addEventListener(MPEvent.SOCKET_CONNECT, e_onSocketConnect);
                _mp.addEventListener(MPEvent.SOCKET_DISCONNECT, e_onSocketDisconnect);
                _mp.addEventListener(MPEvent.SOCKET_ERROR, e_onSocketDisconnect);

                _mp.addEventListener(MPEvent.SYS_LOGIN_OK, e_onSysLoginOK);

                _mp.addEventListener(MPEvent.ROOM_JOIN_OK, e_onRoomJoinOK);
                _mp.addEventListener(MPEvent.ROOM_CREATE_OK, e_onRoomCreateOK);
                _mp.addEventListener(MPEvent.ROOM_LEAVE_OK, e_onRoomLeaveOK);
                _mp.addEventListener(MPEvent.ROOM_DELETE_OK, e_onRoomDeleteOK);

                _mp.addEventListener(MPEvent.USER_MESSAGE, e_onChatUpdate);
                _mp.addEventListener(MPEvent.USER_ROOM_INVITE, e_onChatUpdate);

                _mp.connect();
                btnConnect.text = _lang.string("mp_disconnect");
                showThrobber();
            }
            else
            {
                _mp.disconnect();
            }
        }

        private function e_onSocketConnect(e:MPEvent):void
        {
            _mp.sendCommand(new MPCLogin(Multiplayer.SERVER_VERSION, _gvars.activeUser));
        }

        private function e_onSocketDisconnect(e:MPEvent):void
        {
            clearMPViews();
            setNavigation(false);
            pmAlert.visible = false;
            throbber.visible = false;
            throbber.stop();

            if (e.command.type == "error")
                Alert.add(_lang.string("mp_error") + " " + e.command.action);
        }

        private function e_onSysLoginOK(e:MPEvent):void
        {
            _mp.updateLobby();
        }

        private function e_onRoomJoinOK(e:MPRoomEvent):void
        {
            if (e.room)
                onRoomJoined(e.room);
        }

        private function e_onRoomCreateOK(e:MPRoomEvent):void
        {
            if (e.room)
                onRoomJoined(e.room);
        }

        private function onRoomJoined(room:MPRoom):void
        {
            switch (room.type)
            {
                case 'lobby':
                    setNavigation(true);
                    buildMPViews();

                    lobbyView = new MPRoomViewLobby(room, this, 145, 52);
                    lobbyView.setRoomButton(btnLobbyView);
                    setActiveView(lobbyView, btnLobbyView);

                    hideThrobber();
                    return;

                case 'ffr':
                    clearGameView();
                    gameView = new MPRoomViewFFR(room as MPRoomFFR, this, 145, 52);
                    gameView.setRoomButton(btnGameView);
                    setActiveView(gameView, btnGameView);
                    hideThrobber();
                    btnGameView.visible = true;
                    return;

                case 'bingo':
                    clearGameView();
                    //gameView = new MPRoomViewBingo(room as MPRoomBingo, this, 145, 52);
                    //setView(gameView);
                    hideThrobber();
                    return;

                default:
                    trace("unknown room type for created room:", room.type);
                    return;
            }
        }

        private function e_onRoomLeaveOK(e:MPRoomEvent):void
        {
            if (_mp.GAME_ROOM == null)
            {
                clearGameView();
            }
        }


        private function e_onRoomDeleteOK(e:MPRoomEvent):void
        {
            if (_mp.GAME_ROOM == null)
            {
                clearGameView();
            }
        }

        private function buildMPViews():void
        {
            userMessages = new MPUserMessagesView(this, 145, 52);
            userMessages.visible = false;

            roomBrowser = new MPServerBrowserView(this, 145, 52);
            roomBrowser.visible = false;
        }

        private function clearMPViews():void
        {
            if (activeView)
            {
                activeView.onExit();
                activeView = null;
            }

            if (lobbyView)
            {
                lobbyView.dispose();
                removeChild(lobbyView);
                lobbyView = null;
            }

            if (gameView)
            {
                gameView.dispose();
                removeChild(gameView);
                gameView = null;
                btnGameView.visible = false;
            }

            if (userMessages)
            {
                userMessages.removeEventListener(Event.CHANGE, e_onChatUpdate);
                userMessages.dispose();
                removeChild(userMessages);
                userMessages = null;
            }

            if (roomBrowser)
            {
                roomBrowser.dispose();
                removeChild(roomBrowser);
                roomBrowser = null;
            }

            btnConnect.text = _lang.string("mp_connect");
        }

        private function clearGameView():void
        {
            if (activeView == gameView)
                setActiveView(lobbyView, btnLobbyView);

            if (gameView != null)
            {
                removeChild(gameView);
                gameView.dispose();
                gameView = null;
            }
            btnGameView.visible = false;
        }

        private function setActiveView(active:MPView, btn:Sprite):void
        {
            if (!active)
                return;

            if (activeView)
            {
                activeView.visible = false;
                activeView.onExit();
            }
            active.visible = true;
            activeView = active;
            activeView.onSelect();
            roomIndicator.x = btn.x + btn.width + 7;
            roomIndicator.y = btn.y + btn.height / 2;
        }

        private function setNavigation(state:Boolean):void
        {
            btnPrivateMessages.visible = state;
            btnServerBrowser.visible = state;
            roomIndicator.visible = state;
            btnLobbyView.visible = state;
        }

        private function showThrobber():void
        {
            throbber.visible = true;
            throbber.start();
        }

        private function hideThrobber():void
        {
            throbber.visible = false;
            throbber.stop();
        }

        private function e_onChatUpdate(e:Event):void
        {
            pmAlert.visible = _mp.hasUnreadPM();
        }
    }
}
