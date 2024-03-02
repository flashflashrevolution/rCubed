package classes.mp.views
{
    import assets.menu.icons.fa.iconUserAdd;
    import classes.Alert;
    import classes.Noteskins;
    import classes.mp.MPColors;
    import classes.mp.MPSong;
    import classes.mp.MPUser;
    import classes.mp.commands.MPCFFRGameStateChange;
    import classes.mp.commands.MPCFFRReadyForce;
    import classes.mp.commands.MPCFFRSongLoadProgress;
    import classes.mp.commands.MPCRoomEdit;
    import classes.mp.components.MPViewChatLogRoom;
    import classes.mp.components.MPViewUserListRoom;
    import classes.mp.components.chatlog.MPChatLogEntryMatchResults;
    import classes.mp.components.chatlog.MPChatLogEntrySong;
    import classes.mp.components.chatlog.MPChatLogEntryText;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.events.MPUserEvent;
    import classes.mp.mode.ffr.MPFFRState;
    import classes.mp.prompts.MPRoomUserInvitePrompt;
    import classes.mp.prompts.MPUserProfilePrompt;
    import classes.mp.room.MPRoomFFR;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.Text;
    import classes.ui.UIIcon;
    import com.flashfla.utils.sprintf;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import game.GameOptions;
    import menu.FileLoader;

    public class MPRoomViewFFR extends MPRoomView
    {
        private static const _noteskins:Noteskins = Noteskins.instance;

        public var room:MPRoomFFR;

        private var _width:Number = 409;
        private var _height:Number = 388;

        private var chat:MPViewChatLogRoom;
        private var userlist:MPViewUserListRoom;

        private var inviteButton:UIIcon;

        private var ownerPanel:OwnerPanel;
        private var ownerEditPanel:OwnerEditPanel;
        private var userPanel:UserPanel;

        private var _userProfilePrompt:MPUserProfilePrompt;
        private var _userInvitePrompt:MPRoomUserInvitePrompt;

        public function MPRoomViewFFR(room:MPRoomFFR, parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
        {
            this.room = room;

            super(parent, xpos, ypos);
        }

        override public function addRoomEvents():void
        {
            super.addRoomEvents();

            _mp.addEventListener(MPEvent.FFR_GAME_STATE, e_gameState);
            _mp.addEventListener(MPEvent.FFR_PLAYABLE_STATE, e_playableState);

            _mp.addEventListener(MPEvent.FFR_SONG_RATE, e_songRate);
            _mp.addEventListener(MPEvent.FFR_SONG_CHANGE, e_songUpdate);
            _mp.addEventListener(MPEvent.FFR_SONG_REQUEST, e_songRequest);
            _mp.addEventListener(MPEvent.FFR_READY_STATE, e_readyState);
            _mp.addEventListener(MPEvent.FFR_FORCE_START, e_readyState);

            _mp.addEventListener(MPEvent.FFR_LOADING_START, e_loadingStart);
            _mp.addEventListener(MPEvent.FFR_LOADING, e_loadingProgress);

            _mp.addEventListener(MPEvent.FFR_COUNTDOWN, e_countdown);
            _mp.addEventListener(MPEvent.FFR_MATCH_START, e_matchStart);
            _mp.addEventListener(MPEvent.FFR_SONG_START, e_songStart);
            _mp.addEventListener(MPEvent.FFR_MATCH_END, e_matchEnd);
        }

        override public function dispose():void
        {
            _mp.removeEventListener(MPEvent.FFR_GAME_STATE, e_gameState);
            _mp.removeEventListener(MPEvent.FFR_PLAYABLE_STATE, e_playableState);

            _mp.removeEventListener(MPEvent.FFR_SONG_RATE, e_songRate);
            _mp.removeEventListener(MPEvent.FFR_SONG_CHANGE, e_songUpdate);
            _mp.removeEventListener(MPEvent.FFR_SONG_REQUEST, e_songRequest);
            _mp.removeEventListener(MPEvent.FFR_READY_STATE, e_readyState);
            _mp.removeEventListener(MPEvent.FFR_FORCE_START, e_readyState);

            _mp.removeEventListener(MPEvent.FFR_LOADING_START, e_loadingStart);
            _mp.removeEventListener(MPEvent.FFR_LOADING, e_loadingProgress);

            _mp.removeEventListener(MPEvent.FFR_COUNTDOWN, e_countdown);
            _mp.removeEventListener(MPEvent.FFR_MATCH_START, e_matchStart);
            _mp.removeEventListener(MPEvent.FFR_SONG_START, e_songStart);
            _mp.removeEventListener(MPEvent.FFR_MATCH_END, e_matchEnd);

            userlist.removeEventListener(MPEvent.ROOM_USERLIST_SELECT, e_onUserSelect);
            userlist.removeEventListener(MPEvent.ROOM_USERLIST_SPECTATE, e_onUserSpectate);
            inviteButton.removeEventListener(MouseEvent.CLICK, e_inviteClick);

            closePrompts();

            super.dispose();
        }

        override public function build():void
        {
            super.build();

            chat = new MPViewChatLogRoom(this, 0, 192, _width, _height - 192);
            chat.setRoom(room);

            // Userlist
            userlist = new MPViewUserListRoom(this, 410, 0);
            userlist.setRoom(room);
            userlist.addEventListener(MPEvent.ROOM_USERLIST_SELECT, e_onUserSelect);
            userlist.addEventListener(MPEvent.ROOM_USERLIST_SPECTATE, e_onUserSpectate);

            inviteButton = new UIIcon(this, new iconUserAdd(), 596, 16);
            inviteButton.setSize(15, 15);
            inviteButton.buttonMode = true;
            inviteButton.addEventListener(MouseEvent.CLICK, e_inviteClick);

            // Name
            new Text(this, 5, 0, "#", 14, "#c0c0c0").setAreaParams(15, 30);

            // Owner Panel
            ownerPanel = new OwnerPanel(this, room);
            addChild(ownerPanel);

            ownerEditPanel = new OwnerEditPanel(this, room);
            addChild(ownerEditPanel);

            userPanel = new UserPanel(this, room);
            addChild(userPanel);

            if (_mp.currentUser == room.owner)
                setPanelOwner();
            else
                setPanelUser();

            // Graphics
            redraw();
        }

        public function redraw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(0, 0, 0);

            // Title BG
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, 0, _width, 30);
            this.graphics.endFill();

            // BG
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();

            // Title
            this.graphics.moveTo(1, 30);
            this.graphics.lineTo(_width, 30);

            // Chat
            this.graphics.moveTo(1, 192);
            this.graphics.lineTo(_width, 192);
        }

        override public function onKeyInput(e:KeyboardEvent):void
        {
            if (_userInvitePrompt)
            {
                _userInvitePrompt.onKeyInput(e);
                return;
            }

            if (_userProfilePrompt)
            {
                _userProfilePrompt.onKeyInput(e);
                return;
            }

            chat.onKeyInput(e);
        }

        public function onChatMessage(e:MPRoomEvent):void
        {
            if (e.room == this.room)
                chat.onChatMessage(e);
        }

        override protected function updateRoomButton():void
        {
            if (room.spectatorCount > 0)
                this.roomButton.updateText(room.name, sprintf(_lang.string("mp_btn_player_count_spectator"), {current: room.playerCount, max: room.playerCountMax, spectator: room.spectatorCount}));
            else
                this.roomButton.updateText(room.name, sprintf(_lang.string("mp_btn_player_count"), {current: room.playerCount, max: room.playerCountMax}));
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

        override protected function e_roomUpdate(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                updateRoomButton();
                updatePanelDisplay();
            }
        }

        override protected function e_roomEdit(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                updateRoomButton();
                updatePanelDisplay();
            }
        }

        override protected function e_roomMessage(e:MPRoomEvent):void
        {
            if (e.room === this.room)
                onChatMessage(e);
        }

        override protected function e_teamUpdate(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                updateRoomButton();
                updatePanelDisplay();
            }
        }

        protected function e_gameState(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.updateGameStates();
            }
        }

        protected function e_playableState(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                ownerPanel.update();
                userPanel.update();
            }
        }

        protected function e_songRate(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.updateGameStates();
            }
        }

        override protected function e_userJoin(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                chat.addItem(new MPChatLogEntryText("<font color=\"" + MPColors.USER_JOIN + "\">" + sprintf(_lang.string("mp_room_chat_user_join"), {"user": e.user.name}) + "</font>"));
                userlist.update();
                updateRoomButton();
                updatePanelDisplay();
            }
        }

        override protected function e_userLeave(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                chat.addItem(new MPChatLogEntryText("<font color=\"" + MPColors.USER_LEAVE + "\">" + sprintf(_lang.string("mp_room_chat_user_left"), {"user": e.user.name}) + "</font>"));
                userlist.update();
                updateRoomButton();
                updatePanelDisplay();
            }
        }

        protected function e_songUpdate(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                updatePanelDisplay();
            }
        }

        protected function e_songRequest(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                const info:MPSong = new MPSong();
                info.update(e.command.data);
                info.selected = false;

                chat.addItem(new MPChatLogEntrySong(e.room, e.user, info));
                userlist.update();
                updateRoomButton();
            }
        }

        protected function e_readyState(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                ownerPanel.update();
            }
        }

        protected function e_loadingStart(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                _startSongLoading();
            }
        }

        protected function e_loadingProgress(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.updateGameStates();
            }
        }

        protected function e_matchStart(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                chat.addItem(new MPChatLogEntryText("<font color=\"" + MPColors.SYSTEM_MESSAGE_COLOR + "\">" + _lang.string("mp_room_ffr_match_start") + "</font>"));
                _gameMatchStart();
            }
        }

        protected function e_songStart(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.updateGameStates();
            }
        }

        protected function e_matchEnd(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                userlist.updateGameStates();
                updateRoomButton();
                updatePanelDisplay();

                chat.addItem(new MPChatLogEntryMatchResults(room, room.lastMatch));
            }
        }

        protected function e_countdown(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                chat.addItem(new MPChatLogEntryText("<font color=\"" + MPColors.SYSTEM_MESSAGE_COLOR + "\">" + _lang.string("mp_room_countdown_" + e.command.data.value) + "</font>"));
            }
        }

        private function e_inviteClick(e:MouseEvent):void
        {
            _userInvitePrompt = new MPRoomUserInvitePrompt(this.room, this);
            _userInvitePrompt.addEventListener(Event.CLOSE, e_onInviteClose);
        }

        private function e_onInviteClose(e:Event):void
        {
            _userInvitePrompt.removeEventListener(Event.CLOSE, e_onInviteClose);
            _userInvitePrompt = null;
        }

        private function e_onUserSelect(e:MPUserEvent):void
        {
            _userProfilePrompt = new MPUserProfilePrompt(e.user, this.room, this);
            _userProfilePrompt.addEventListener(Event.CLOSE, e_onProfileClose);
            _userProfilePrompt.addEventListener(MPEvent.ROOM_USERLIST_SPECTATE, e_onUserSpectate);
        }

        private function e_onUserSpectate(e:MPUserEvent):void
        {
            _spectatePlayer(e.user);
        }

        private function e_onProfileClose(e:Event):void
        {
            _userProfilePrompt.removeEventListener(MPEvent.ROOM_USERLIST_SPECTATE, e_onUserSpectate);
            _userProfilePrompt.removeEventListener(Event.CLOSE, e_onProfileClose);
            _userProfilePrompt = null;
        }

        public function closePrompts():void
        {
            if (_userProfilePrompt)
            {
                _userProfilePrompt.close();
                e_onProfileClose(null);
            }

            if (_userInvitePrompt)
            {
                _userInvitePrompt.close();
                e_onInviteClose(null);
            }
        }

        public function updatePanelDisplay():void
        {
            ownerPanel.update();
            ownerEditPanel.update();
            userPanel.update();

            // Update User -> Owner Switch
            if (this.room.owner == _mp.currentUser && userPanel.visible)
                setPanelOwner();

            // Update Owner -> User Switch
            if (this.room.owner != _mp.currentUser && (ownerPanel.visible || ownerEditPanel.visible))
                setPanelUser();
        }

        public function setPanelOwner():void
        {
            ownerPanel.visible = true;
            ownerEditPanel.visible = false;
            userPanel.visible = false;
        }

        public function setPanelEdit():void
        {
            ownerPanel.visible = false;
            ownerEditPanel.visible = true;
            userPanel.visible = false;
        }

        public function setPanelUser():void
        {
            ownerPanel.visible = false;
            ownerEditPanel.visible = false;
            userPanel.visible = true;
        }

        private function _startSongLoading():void
        {
            if (room.songInfo == null)
            {
                if (room.isPlayer(_mp.currentUser))
                {
                    const progress_update_fail:MPCFFRSongLoadProgress = new MPCFFRSongLoadProgress(room, -1, false);
                    _mp.sendCommand(progress_update_fail);
                }
                return;
            }

            // Setup Local File
            if (room.songInfo.is_local)
                FileLoader.buildSong(room.songInfo);

            if (room.isPlayer(_mp.currentUser))
            {
                const state:MPCFFRGameStateChange = new MPCFFRGameStateChange(room, "loading");
                _mp.sendCommand(state);
            }

            room.song = _gvars.getSongFile(room.songInfo);

            if (room.isSongLoaded())
            {
                _endSongLoading();
            }
            else
            {
                room.song.addEventListener(Event.COMPLETE, e_songFileComplete);

                function e_songFileComplete(e:Event):void
                {
                    room.song.removeEventListener(Event.COMPLETE, e_songFileComplete);

                    if (room.isSongLoaded())
                        _endSongLoading();
                }

                var timer:Timer = new Timer(500);
                timer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void
                {
                    if (!room.song || room.isSongLoaded())
                        timer.stop();
                    else
                    {
                        if (room.song && room.song.loadFail)
                        {
                            _gvars.removeSongFile(room.song);
                            room.song = null;

                            if (room.isPlayer(_mp.currentUser))
                            {
                                const progress_update_fail:MPCFFRSongLoadProgress = new MPCFFRSongLoadProgress(room, -1, false);
                                _mp.sendCommand(progress_update_fail);

                                const state:MPCFFRGameStateChange = new MPCFFRGameStateChange(room, "menu");
                                _mp.sendCommand(state);
                            }

                            Alert.add(sprintf(_lang.string("mp_room_ffr_song_load_error"), {song: room.songData.name}));
                            timer.stop();
                        }

                        if (room.isPlayer(_mp.currentUser))
                        {
                            const progress_update:MPCFFRSongLoadProgress = new MPCFFRSongLoadProgress(room, room.song.progress, false);
                            _mp.sendCommand(progress_update);
                        }
                    }
                });
                timer.start();
            }
        }

        private function _endSongLoading():void
        {
            if (room.isPlayer(_mp.currentUser))
            {
                const state:MPCFFRSongLoadProgress = new MPCFFRSongLoadProgress(room, 100, true);
                _mp.sendCommand(state);
            }
        }

        private function _gameMatchStart():void
        {
            if (room.isPlayer(_mp.currentUser))
            {
                closePrompts();

                if (!room.song)
                    room.song = _gvars.getSongFile(room.songInfo);

                _gvars.options = new GameOptions();
                _gvars.options.isMultiplayer = true;
                _gvars.options.fill();
                _gvars.options.song = room.song;
                _gvars.options.judgeWindow = null;
                _gvars.options.isolationOffset = _gvars.options.isolationLength = 0;
                _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
            }
        }

        private function _spectatePlayer(user:MPUser):void
        {
            if (room.isPlayer(user) && room.getPlayerState(user) == "game")
            {
                closePrompts();

                if (!room.song)
                    room.song = _gvars.getSongFile(room.songInfo);

                if (!room.song)
                {
                    chat.addItem(new MPChatLogEntryText(_lang.string("mp_room_chat_spectate_error")));
                    return;
                }

                var vars:MPFFRState = room.getPlayerVariables(user);

                room.song.isDirty = true;
                _gvars.options = new GameOptions();
                _gvars.options.settingsDecode(vars.settings);
                _gvars.options.song = room.song;
                _gvars.options.isMultiplayer = true;
                _gvars.options.isSpectator = true;
                _gvars.options.spectatorUser = user;

                // User Custom Noteskin.
                if (vars.noteskin == null && _gvars.options.noteskin == 0)
                    _gvars.options.noteskin = 1;

                if (_gvars.options.noteskin == 0 && vars.noteskin != null)
                {
                    _gvars.options.noteskin = 9999999;
                    _noteskins.addEventListener(Noteskins.JSON_LOAD, e_onNoteskinComplete);
                    _noteskins.addEventListener(Noteskins.JSON_ERROR, e_onNoteskinCancel);
                    _noteskins.loadCustomNoteskinJSON(vars.noteskin, "9999999");
                }
                else
                {
                    _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
                }
            }
        }

        private function e_onNoteskinComplete(e:Event):void
        {
            _noteskins.removeEventListener(Noteskins.JSON_LOAD, e_onNoteskinComplete);
            _noteskins.removeEventListener(Noteskins.JSON_ERROR, e_onNoteskinCancel);
            _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
        }

        private function e_onNoteskinCancel(e:Event):void
        {
            _noteskins.removeEventListener(Noteskins.JSON_LOAD, e_onNoteskinComplete);
            _noteskins.removeEventListener(Noteskins.JSON_ERROR, e_onNoteskinCancel);
            _gvars.options.noteskin = 1;
            _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
        }
    }
}

import assets.menu.icons.fa.iconAccept;
import assets.menu.icons.fa.iconCancel;
import assets.menu.icons.fa.iconEye;
import assets.menu.icons.fa.iconGear;
import assets.menu.icons.fa.iconLeave;
import assets.menu.icons.fa.iconPlay;
import classes.Alert;
import classes.Language;
import classes.mp.MPModes;
import classes.mp.Multiplayer;
import classes.mp.commands.MPCFFRReady;
import classes.mp.commands.MPCFFRReadyForce;
import classes.mp.commands.MPCRoomEdit;
import classes.mp.commands.MPCRoomLeave;
import classes.mp.events.MPEvent;
import classes.mp.events.MPRoomEvent;
import classes.mp.room.MPRoomFFR;
import classes.mp.views.MPRoomViewFFR;
import classes.ui.BoxButton;
import classes.ui.BoxIcon;
import classes.ui.BoxText;
import classes.ui.Text;
import classes.ui.UIIcon;
import com.bit101.components.ComboBox;
import com.flashfla.utils.SystemUtil;
import com.flashfla.utils.sprintf;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import menu.MainMenu;
import menu.MenuMultiplayer;

internal class UserPanel extends Sprite
{
    private static const _mp:Multiplayer = Multiplayer.instance;
    private static const _lang:Language = Language.instance;

    private var view:MPRoomViewFFR;
    private var room:MPRoomFFR;

    private var name:Text;
    private var iconLeaveBtn:UIIcon;

    private var songName:Text;
    private var songAuthor:Text;
    private var songLength:Text;
    private var songDifficulty:Text;

    private var ready:BoxButton;
    private var selectSong:BoxButton;

    public function UserPanel(view:MPRoomViewFFR, room:MPRoomFFR)
    {
        this.view = view;
        this.room = room;

        name = new Text(this, 20, 0, room.name, 16);
        name.setAreaParams(view.width - 85, 30);

        iconLeaveBtn = new UIIcon(this, new iconLeave(), view.width - 15, 16);
        iconLeaveBtn.setSize(15, 15);
        iconLeaveBtn.buttonMode = true;
        iconLeaveBtn.addEventListener(MouseEvent.CLICK, e_leaveClick);

        new Text(this, 6, 35, _lang.string("mp_room_ffr_song_name"), 13, "#c3c3c3").setAreaParams(250, 20);
        songName = new Text(this, 6, 51, "", 11);
        songName.setAreaParams(250, 20);

        new Text(this, 6, 74, _lang.string("mp_room_ffr_song_author"), 13, "#c3c3c3").setAreaParams(250, 20);
        songAuthor = new Text(this, 6, 90, "", 11);
        songAuthor.setAreaParams(250, 20);

        new Text(this, 6, 113, _lang.string("mp_room_ffr_song_length"), 13, "#c3c3c3").setAreaParams(250, 20);
        songLength = new Text(this, 6, 129, "", 11);
        songLength.setAreaParams(250, 20);

        new Text(this, 6, 152, _lang.string("mp_room_ffr_song_difficulty"), 13, "#c3c3c3").setAreaParams(250, 20);
        songDifficulty = new Text(this, 6, 168, "", 11);
        songDifficulty.setAreaParams(250, 20);

        ready = new BoxButton(this, 275, 40, 125, 26, _lang.string("mp_room_ffr_player_ready"), 12, e_readyClick);
        selectSong = new BoxButton(this, 275, 75, 125, 26, _lang.string("mp_room_ffr_player_song_request"), 12, e_songsClick);

        update();
    }

    public function update():void
    {
        name.text = room.name ? room.name : "";

        if (room.songData.selected)
        {
            ready.enabled = true;
            songName.text = room.songData.name;
            songAuthor.text = room.songData.author;
            songLength.text = sprintf(_lang.string("mp_room_ffr_song_length_value"), {"time": room.songData.time, "note_count": room.songData.note_count});
            songDifficulty.text = room.songData.difficulty.toString();
        }
        else
        {
            ready.enabled = true;
            songName.text = _lang.string("mp_room_ffr_song_unselected");
            songAuthor.text = "---";
            songLength.text = "---";
            songDifficulty.text = "---";
        }

        if (ready.enabled && !room.canUserPlaySong(_mp.currentUser))
            ready.enabled = false;

        ready.text = _lang.string(room.isPlayerReady(_mp.currentUser) ? "mp_room_ffr_owner_unready" : "mp_room_ffr_owner_ready");
    }

    private function e_leaveClick(e:MouseEvent):void
    {
        _mp.sendCommand(new MPCRoomLeave(room));
    }

    private function e_readyClick(e:MouseEvent):void
    {
        _mp.sendCommand(new MPCFFRReady(room));
    }

    private function e_songsClick(e:MouseEvent):void
    {
        (this.view.parent as MenuMultiplayer).switchTo(MainMenu.MENU_SONGSELECTION);
    }
}

internal class OwnerPanel extends Sprite
{
    private static const _gvars:GlobalVariables = GlobalVariables.instance;
    private static const _mp:Multiplayer = Multiplayer.instance;
    private static const _lang:Language = Language.instance;

    private var view:MPRoomViewFFR;
    private var room:MPRoomFFR;

    private var name:Text;
    private var iconEditBtn:UIIcon;
    private var iconLeaveBtn:UIIcon;

    private var songName:Text;
    private var songAuthor:Text;
    private var songLength:Text;
    private var songDifficulty:Text;

    private var ready:BoxButton;
    private var forceStart:BoxIcon;
    private var selectSong:BoxButton;
    private var selectMods:BoxButton;

    public function OwnerPanel(view:MPRoomViewFFR, room:MPRoomFFR)
    {
        this.view = view;
        this.room = room;

        name = new Text(this, 20, 0, "", 16);
        name.setAreaParams(view.width - 85, 30);

        iconEditBtn = new UIIcon(this, new iconGear(), view.width - 45, 16);
        iconEditBtn.setSize(15, 15);
        iconEditBtn.buttonMode = true;
        iconEditBtn.addEventListener(MouseEvent.CLICK, e_editClick);

        iconLeaveBtn = new UIIcon(this, new iconLeave(), view.width - 15, 16);
        iconLeaveBtn.setSize(15, 15);
        iconLeaveBtn.buttonMode = true;
        iconLeaveBtn.addEventListener(MouseEvent.CLICK, e_leaveClick);

        new Text(this, 6, 35, _lang.string("mp_room_ffr_song_name"), 13, "#c3c3c3").setAreaParams(250, 20);
        songName = new Text(this, 6, 51, "", 11);
        songName.setAreaParams(250, 20);

        new Text(this, 6, 74, _lang.string("mp_room_ffr_song_author"), 13, "#c3c3c3").setAreaParams(250, 20);
        songAuthor = new Text(this, 6, 90, "", 11);
        songAuthor.setAreaParams(250, 20);

        new Text(this, 6, 113, _lang.string("mp_room_ffr_song_length"), 13, "#c3c3c3").setAreaParams(250, 20);
        songLength = new Text(this, 6, 129, "", 11);
        songLength.setAreaParams(250, 20);

        new Text(this, 6, 152, _lang.string("mp_room_ffr_song_difficulty"), 13, "#c3c3c3").setAreaParams(250, 20);
        songDifficulty = new Text(this, 6, 168, "", 11);
        songDifficulty.setAreaParams(250, 20);

        ready = new BoxButton(this, 275, 40, 94, 26, _lang.string("mp_room_ffr_owner_ready"), 12, e_readyClick);

        forceStart = new BoxIcon(this, 374, 40, 26, 26, new iconPlay(), e_forceStartClick);
        forceStart.padding = 16;
        forceStart.setHoverText(_lang.string("mp_room_ffr_owner_force_start"));

        selectSong = new BoxButton(this, 275, 75, 125, 26, _lang.string("mp_room_ffr_owner_song_select"), 12, e_songsClick);

        selectMods = new BoxButton(this, 275, 110, 125, 26, _lang.string("mp_room_ffr_owner_mod_select"), 12, e_modsClick);
        selectMods.visible = false;

        update();
    }

    public function update():void
    {
        name.text = room.name ? room.name : "";

        if (room.songData.selected)
        {
            ready.enabled = forceStart.enabled = true;
            songName.text = room.songData.name;
            songAuthor.text = room.songData.author;
            songLength.text = sprintf(_lang.string("mp_room_ffr_song_length_value"), {"time": room.songData.time, "note_count": room.songData.note_count});
            songDifficulty.text = room.songData.difficulty.toString();
        }
        else
        {
            ready.enabled = forceStart.enabled = false;
            songName.text = _lang.string("mp_room_ffr_song_unselected");
            songAuthor.text = "---";
            songLength.text = "---";
            songDifficulty.text = "---";
        }

        if (ready.enabled && !room.canUserPlaySong(_mp.currentUser))
            ready.enabled = false;

        ready.text = _lang.string(room.isPlayerReady(_mp.currentUser) ? "mp_room_ffr_owner_unready" : "mp_room_ffr_owner_ready");
    }

    private function e_editClick(e:MouseEvent):void
    {
        view.setPanelEdit();
    }

    private function e_leaveClick(e:MouseEvent):void
    {
        _mp.sendCommand(new MPCRoomLeave(room));
    }

    private function e_readyClick(e:MouseEvent):void
    {
        _mp.sendCommand(new MPCFFRReady(room));
    }

    private function e_forceStartClick(e:MouseEvent):void
    {
        _mp.sendCommand(new MPCFFRReadyForce(room));
    }

    private function e_songsClick(e:MouseEvent):void
    {
        (this.view.parent as MenuMultiplayer).switchTo(MainMenu.MENU_SONGSELECTION);
    }

    private function e_modsClick(e:MouseEvent):void
    {

    }
}

internal class OwnerEditPanel extends Sprite
{
    private static const _mp:Multiplayer = Multiplayer.instance;
    private static const _lang:Language = Language.instance;

    private var view:MPRoomViewFFR;
    private var room:MPRoomFFR;

    private var name:BoxText;
    private var iconCancelBtn:UIIcon;
    private var iconSaveBtn:UIIcon;

    private var roomPassword:BoxText;
    private var showPassword:BoxIcon;
    private var joinCode:Text;

    private var teamModes:ComboBox;

    private var maxPlayersText:Text;
    private var maxPlayers:ComboBox;

    private var maxTeamsText:Text;
    private var maxTeams:ComboBox;
    private var maxPlayersPerTeamText:Text;
    private var maxPlayersPerTeam:ComboBox;

    public function OwnerEditPanel(view:MPRoomViewFFR, room:MPRoomFFR)
    {
        this.view = view;
        this.room = room;

        name = new BoxText(this, 20, 1, 280, 28);
        name.field.y += 1;
        name.borderAlpha = 0;
        name.borderActiveAlpha = 0;

        iconCancelBtn = new UIIcon(this, new iconCancel(), view.width - 45, 16);
        iconCancelBtn.setSize(15, 15);
        iconCancelBtn.setColor("#eda8a8");
        iconCancelBtn.buttonMode = true;
        iconCancelBtn.addEventListener(MouseEvent.CLICK, e_cancelClick);

        iconSaveBtn = new UIIcon(this, new iconAccept(), view.width - 15, 16);
        iconSaveBtn.setSize(15, 15);
        iconSaveBtn.setColor("#bdeda8");
        iconSaveBtn.buttonMode = true;
        iconSaveBtn.addEventListener(MouseEvent.CLICK, e_saveClick);

        new Text(this, 9, 35, _lang.string("mp_room_options_password"), 12, "#c3c3c3").setAreaParams(185, 22);

        roomPassword = new BoxText(this, 10, 58, 160, 21, Constant.TEXT_FORMAT_UNICODE_12);
        roomPassword.displayAsPassword = true;
        roomPassword.field.y += 1;

        showPassword = new BoxIcon(this, 175, 58, 21, 21, new iconEye(), e_togglePassword);

        new Text(this, 9, 85, _lang.string("mp_room_options_join_code"), 12, "#c3c3c3").setAreaParams(185, 22);

        joinCode = new Text(this, 9, 108);
        joinCode.mouseEnabled = true;
        joinCode.buttonMode = true;
        joinCode.addEventListener(MouseEvent.CLICK, e_onJoinClick);

        // Team Mode
        new Text(this, 214, 35, _lang.string("mp_room_options_team_mode")).setAreaParams(185, 22);

        teamModes = new ComboBox(this, 215, 58, "", MPModes.getTeamModes());
        teamModes.setSize(185, 24);
        teamModes.fontSize = 11;
        teamModes.selectedIndex = 0;

        // Max Players - FFA
        maxPlayersText = new Text(this, 214, 85, _lang.string("mp_room_options_max_player_count"), 12, "#c3c3c3");
        maxPlayersText.setAreaParams(185, 22);
        maxPlayersText.visible = false;

        maxPlayers = new ComboBox(this, 215, 108, "", MPModes.getMaxPlayers());
        maxPlayers.setSize(185, 24);
        maxPlayers.fontSize = 11;
        maxPlayers.selectedIndex = 1;
        maxPlayers.visible = false;

        // Max Teams - Team
        maxTeamsText = new Text(this, 215, 85, _lang.string("mp_room_options_max_team_count"), 12, "#c3c3c3");
        maxTeamsText.setAreaParams(185, 22);
        maxTeamsText.visible = false;

        maxTeams = new ComboBox(this, 215, 108, "", MPModes.getTeams());
        maxTeams.setSize(185, 24);
        maxTeams.fontSize = 11;
        maxTeams.selectedIndex = 0;
        maxTeams.visible = false;

        // Max Teams Players - Team
        maxPlayersPerTeamText = new Text(this, 215, 135, _lang.string("mp_room_options_max_team_players"), 12, "#c3c3c3");
        maxPlayersPerTeamText.setAreaParams(185, 22);
        maxPlayersPerTeamText.visible = false;

        maxPlayersPerTeam = new ComboBox(this, 215, 158, "", MPModes.getTeamMaxPlayers());
        maxPlayersPerTeam.setSize(185, 24);
        maxPlayersPerTeam.fontSize = 11;
        maxPlayersPerTeam.selectedIndex = 0;
        maxPlayersPerTeam.visible = false;

        // Events
        teamModes.addEventListener(Event.SELECT, e_onTeamModeChange);

        // Draw
        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.moveTo(name.x, 1);
        this.graphics.lineTo(name.x, name.height + 1);
        this.graphics.moveTo(name.x + name.width, 1);
        this.graphics.lineTo(name.x + name.width, name.height + 1);

        update();
    }

    public function update():void
    {
        name.text = room.name ? room.name : "";
        roomPassword.text = room.password ? room.password : "";
        joinCode.text = room.joinCode ? room.joinCode : "";

        if ((room.teamCount - 1) > 1)
        {
            teamModes.selectedItemByData = "team";
            maxTeams.selectedItemByData = (room.teamCount - 1);
            maxPlayersPerTeam.selectedItemByData = room.maxPlayers;
        }
        else
        {
            teamModes.selectedItemByData = "ffr";
            maxPlayers.selectedItemByData = room.maxPlayers;
        }

        updateTeamMode();
    }

    private function e_cancelClick(e:MouseEvent):void
    {
        view.setPanelOwner();
    }

    private function e_onJoinClick(e:MouseEvent):void
    {
        const success:Boolean = SystemUtil.setClipboard(room.joinCode);

        if (success)
            Alert.add(_lang.string("clipboard_success"), 120, Alert.GREEN);

        else
            Alert.add(_lang.string("clipboard_failure"), 120, Alert.RED);
    }

    private function e_saveClick(e:MouseEvent):void
    {
        _mp.addEventListener(MPEvent.ROOM_EDIT_OK, e_onEditOK);
        _mp.addEventListener(MPEvent.ROOM_EDIT_FAIL, e_onEditFail);

        const cmd:MPCRoomEdit = new MPCRoomEdit(room);
        cmd.name = name.text;
        cmd.password = roomPassword.text;

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

    private function e_onEditOK(e:MPRoomEvent):void
    {
        _mp.removeEventListener(MPEvent.ROOM_EDIT_OK, e_onEditOK);
        _mp.removeEventListener(MPEvent.ROOM_EDIT_FAIL, e_onEditFail);

        view.setPanelOwner();
    }

    private function e_onEditFail(e:MPEvent):void
    {
        _mp.removeEventListener(MPEvent.ROOM_EDIT_OK, e_onEditOK);
        _mp.removeEventListener(MPEvent.ROOM_EDIT_FAIL, e_onEditFail);
    }

    private function e_onTeamModeChange(e:Event):void
    {
        updateTeamMode();
    }

    private function e_togglePassword(e:Event):void
    {
        roomPassword.displayAsPassword = !roomPassword.displayAsPassword;
    }

    private function updateTeamMode():void
    {
        switch (teamModes.selectedIndex)
        {
            case 0:
                maxPlayersText.visible = maxPlayers.visible = true;
                maxTeamsText.visible = maxTeams.visible = false;
                maxPlayersPerTeamText.visible = maxPlayersPerTeam.visible = false;
                break;

            case 1:
                maxPlayersText.visible = maxPlayers.visible = false;
                maxTeamsText.visible = maxTeams.visible = true;
                maxPlayersPerTeamText.visible = maxPlayersPerTeam.visible = true;
                break;
        }
    }

}
