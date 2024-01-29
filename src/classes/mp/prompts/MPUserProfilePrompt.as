package classes.mp.prompts
{
    import assets.menu.icons.fa.iconClose;
    import assets.menu.icons.fa.iconEye;
    import assets.menu.icons.fa.iconPlus;
    import assets.menu.icons.fa.iconUserX;
    import classes.Alert;
    import classes.ImageCache;
    import classes.Language;
    import classes.mp.MPUser;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCRoomInvite;
    import classes.mp.commands.MPCRoomUserBlock;
    import classes.mp.commands.MPCUserBlock;
    import classes.mp.commands.MPCUserMessage;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.events.MPUserEvent;
    import classes.mp.room.MPRoom;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.BoxText;
    import classes.ui.Prompt;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import classes.user.UserStats;
    import com.flashfla.utils.sprintf;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;

    public class MPUserProfilePrompt extends Prompt
    {
        private static const _mp:Multiplayer = Multiplayer.instance;
        private static const _lang:Language = Language.instance;

        public var user:MPUser;
        public var room:MPRoom;

        private var roomName:BoxText;

        private var btnBlock:BoxIcon;
        private var btnUnBlock:BoxIcon;
        private var btnRoomInvite:BoxIcon;
        private var btnRoomSpectate:BoxIcon;

        private var btnTabProfile:BoxButton;
        private var btnTabRoom:BoxButton;
        private var btnTabModerator:BoxButton;

        private var selectedTab:Sprite;
        private var tabProfile:TabProfile;
        private var tabRoom:TabRoom;
        private var tabModerator:TabModerator;

        private var closeButton:BoxIcon;

        private var messagePlaceholderLeft:Text;
        private var messagePlaceholderRight:Text;
        private var messageText:BoxText;
        private var _last_message_text:String = "";

        private var throbber:Throbber;

        public function MPUserProfilePrompt(user:MPUser, room:MPRoom, parent:DisplayObject):void
        {
            this.user = user;
            this.room = room;

            _mp.addEventListener(MPEvent.USER_BLOCK_UPDATE, e_onBlockUpdate);
            _mp.addEventListener(MPEvent.ROOM_UPDATE, e_onRoomUpdate);

            super(parent.stage, 650, 394);

            _content.graphics.moveTo(20, 140);
            _content.graphics.lineTo(_width - 20, 140);

            //_content.graphics.moveTo(20, 340);
            //_content.graphics.lineTo(_width - 20, 340);

            closeButton = new BoxIcon(this, _width - 32, 10, 22, 22, new iconClose(), clickHandler);

            // Name
            new Text(this, 136, 18, user.nameHTML, 24).setAreaParams(width - 145, 22);

            // Skill Rating
            if (user.skillRating >= 255)
            {
                new Text(this, 136, 46, GlobalVariables.getDivisionTitle(user.skillRating), 16, GlobalVariables.getDivisionColor(user.skillRating)).setAreaParams(width - 145, 22);
            }
            else
            {
                new Text(this, 136, 46, sprintf(_lang.string("mp_profile_skill_level"), {level: user.skillRating,
                        division: GlobalVariables.getDivisionNumber(user.skillRating) + 1,
                        title: GlobalVariables.getDivisionTitle(user.skillRating)}), 16, GlobalVariables.getDivisionColor(user.skillRating)).setAreaParams(width - 145, 22);
            }

            // Avatar
            var avatar:Sprite = ImageCache.getImage(user.avatarURL, 0, 100, 100);
            avatar.x = 26;
            avatar.y = 25;
            addChild(avatar);
            _content.graphics.lineStyle(2, 0xFFFFFF, 0.35);
            _content.graphics.beginFill(0xFFFFFF, 0.1);
            _content.graphics.drawRect(21, 20, 110, 110);
            _content.graphics.endFill();

            // Profile Actions
            btnBlock = new BoxIcon(this, 139, 71, 26, 26, new iconUserX(), e_blockUser);
            btnBlock.setHoverText(_lang.string("mp_user_block_add"));
            btnBlock.setIconColor("#ff8989");
            btnBlock.visible = _mp.currentUser.blockList.indexOf(user.sid) == -1;

            btnUnBlock = new BoxIcon(this, 139, 71, 26, 26, new iconUserX(), e_blockUser);
            btnUnBlock.setHoverText(_lang.string("mp_user_block_remove"));
            btnUnBlock.setIconColor("#89ffa5");
            btnUnBlock.visible = !btnBlock.visible;

            btnBlock.enabled = btnUnBlock.enabled = (user != _mp.currentUser && !user.permissions.admin);

            btnRoomInvite = new BoxIcon(this, 168, 71, 26, 26, new iconPlus(), e_inviteUser);
            btnRoomInvite.setHoverText(_lang.string("mp_user_room_invite"));
            btnRoomInvite.setIconColor("#89ffa5");
            btnRoomInvite.enabled = _mp.GAME_ROOM != null;

            btnRoomSpectate = new BoxIcon(this, 197, 71, 26, 26, new iconEye(), e_spectateUser);
            btnRoomSpectate.setHoverText(_lang.string("mp_user_room_spectate"));
            btnRoomSpectate.enabled = (room != null && room.type == "ffr");

            // Actions
            btnTabProfile = new BoxButton(this, 139, 104, 129, 26, _lang.string("mp_profile_action_general"), 12, clickHandler);
            btnTabRoom = new BoxButton(this, 273, 104, 129, 26, _lang.string("mp_profile_action_owner"), 12, clickHandler);
            btnTabModerator = new BoxButton(this, 407, 104, 129, 26, _lang.string("mp_profile_action_mod"), 12, clickHandler);

            // Tabs
            tabProfile = new TabProfile(this, 20, 150, user, room);
            tabRoom = new TabRoom(this, 20, 150, user, room);
            tabModerator = new TabModerator(this, 20, 150, user, room);

            selectedTab = tabProfile;

            // Loading Indicator
            throbber = new Throbber(32, 32, 3);
            throbber.x = _width / 2 - 16;
            throbber.y = 140 - 16 + (_height - 140) / 2;
            addChild(throbber);
            throbber.start();

            // Setup Navigation
            updateNavigation();

            // Get Profile Data
            if (user.sid > 1)
                UserStats.load(user.sid, e_onProfileLoad);

            // Messaging
            messagePlaceholderRight = new Text(this, _width - 175, _height - 50, _lang.string("mp_room_chat_message_hint"));
            messagePlaceholderRight.setAreaParams(150, 30, "right");
            messagePlaceholderRight.alpha = 0.35;

            messagePlaceholderLeft = new Text(this, 25, _height - 50, sprintf(_lang.string("mp_room_chat_message_user"), {"name": user.name}));
            messagePlaceholderLeft.setAreaParams(_width - messagePlaceholderRight.textfield.textWidth - 20, 30, "left");
            messagePlaceholderLeft.alpha = 0.35;

            messageText = new BoxText(this, 20, _height - 50, _width - 42, 29);
            messageText.field.y += 2;
            messageText.field.maxChars = 500;
            messageText.addEventListener(Event.CHANGE, e_onMessageType, false, 0, true);

            // System User
            if (user.sid == 1)
            {
                var devText:Text = new Text(this, 20, 150, "\"beep boop, i'm a computer\"");
                devText.alpha = 0.1;
                devText.setAreaParams(610, 225, "center");

                btnTabProfile.visible = btnTabRoom.visible = btnTabModerator.visible = false;
                tabProfile.visible = tabRoom.visible = tabModerator.visible = false;
                messagePlaceholderRight.visible = messagePlaceholderLeft.visible = messageText.visible = false;

                throbber.stop();
                removeChild(throbber);
                throbber = null;
            }
        }

        private function updateNavigation():void
        {
            if (!_mp.currentUser.permissions.mod)
                btnTabModerator.visible = false;

            if (room == null || room.type == "lobby")
                btnTabRoom.visible = false;

            else if (room.owner != _mp.currentUser)
            {
                btnTabRoom.enabled = false;

                if (selectedTab == tabRoom)
                {
                    selectTab(tabProfile);
                }
            }

            if (btnTabRoom.visible == false && btnTabModerator.visible == false)
                btnTabProfile.visible = false;
        }

        private function selectTab(tab:Sprite):void
        {
            selectedTab.visible = false;
            selectedTab = tab;
            selectedTab.visible = true;
        }

        private function e_onProfileLoad(data:UserStats):void
        {
            throbber.stop();
            removeChild(throbber);
            throbber = null;

            if (stage)
            {
                tabProfile.update(data);

                if (selectedTab == tabProfile)
                    tabProfile.visible = true;
            }
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == btnTabProfile)
            {
                selectTab(tabProfile);
            }
            else if (e.target == btnTabRoom)
            {
                selectTab(tabRoom);
            }
            else if (e.target == btnTabModerator)
            {
                selectTab(tabModerator);
            }
            if (e.target == closeButton)
            {
                close();
                dispatchEvent(new Event(Event.CLOSE));
            }
        }

        override public function close():void
        {
            if (throbber)
            {
                throbber.stop();
                removeChild(throbber);
                throbber = null;
            }

            _mp.removeEventListener(MPEvent.USER_BLOCK_UPDATE, e_onBlockUpdate);
            _mp.removeEventListener(MPEvent.ROOM_UPDATE, e_onRoomUpdate);

            super.close();
        }

        public function onKeyInput(e:KeyboardEvent):void
        {
            if (e.keyCode == Keyboard.ENTER && e.target == messageText.field)
            {
                sendChatMessage(0);
            }
        }

        private function e_inviteUser(e:Event):void
        {
            _mp.sendCommand(new MPCRoomInvite(user, _mp.GAME_ROOM));
        }

        private function e_spectateUser(e:Event):void
        {
            dispatchEvent(new MPUserEvent(MPEvent.ROOM_USERLIST_SPECTATE, null, user));
        }

        private function e_blockUser(e:Event):void
        {
            _mp.sendCommand(new MPCUserBlock(user));
        }

        private function e_onBlockUpdate(e:MPEvent):void
        {
            var target:int = e.command.data.sid;
            if (target == user.sid)
            {
                if (_mp.currentUser.blockList.indexOf(target) == -1)
                    Alert.add(sprintf(_lang.string("mp_user_block_unblocked"), {name: user.name}), 120, Alert.GREEN);
                else
                    Alert.add(sprintf(_lang.string("mp_user_block_blocked"), {name: user.name}), 120, Alert.RED);

                btnBlock.visible = _mp.currentUser.blockList.indexOf(user.sid) == -1;
                btnUnBlock.visible = !btnBlock.visible;
            }
        }

        private function e_onRoomUpdate(e:MPRoomEvent):void
        {
            if (e.room != room)
                return;

            updateNavigation();
        }

        private function e_onMessageType(e:Event):void
        {
            _last_message_text = messageText.text;
            messagePlaceholderRight.visible = messagePlaceholderLeft.visible = (_last_message_text.length <= 0);
        }

        public function sendChatMessage(type:int):void
        {
            if (_last_message_text.length > 0)
            {
                _mp.sendCommand(new MPCUserMessage(user, _last_message_text, type));
                _last_message_text = "";
                messageText.text = "";
                messagePlaceholderRight.visible = messagePlaceholderLeft.visible = true;
            }
        }

    }
}

import classes.Language;
import classes.Playlist;
import classes.SongInfo;
import classes.mp.MPUser;
import classes.mp.Multiplayer;
import classes.mp.commands.MPCModBanUser;
import classes.mp.commands.MPCModMuteUser;
import classes.mp.commands.MPCRoomUserBlock;
import classes.mp.commands.MPCRoomUserOwner;
import classes.mp.prompts.MPUserProfilePrompt;
import classes.mp.room.MPRoom;
import classes.ui.BoxButton;
import classes.ui.BoxText;
import classes.ui.Text;
import classes.user.UserStats;
import classes.user.UserStatsScore;
import com.bit101.components.ComboBox;
import com.flashfla.utils.DateUtil;
import com.flashfla.utils.NumberUtil;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;

internal class TabProfile extends Sprite
{
    private static const _lang:Language = Language.instance;

    private var prompt:MPUserProfilePrompt;

    public function TabProfile(parent:MPUserProfilePrompt, xpos:Number, ypos:Number, user:MPUser, room:MPRoom):void
    {
        this.prompt = parent;
        this.x = xpos;
        this.y = ypos;
        this.visible = false;

        parent.addChild(this);
    }

    public function update(data:UserStats):void
    {
        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.moveTo(315, 11);
        this.graphics.lineTo(315, 175);

        // Display Scores
        new Text(this, 0, 0, _lang.string("mp_profile_top_5_scores"), 15).setAreaParams(295, 22);
        var len:int = Math.min(5, data.equiv_scores.length);
        for (var i:int = 0; i < len; i++)
        {
            var entry:ProfileScoreEntry = new ProfileScoreEntry(data.equiv_scores[i]);
            entry.y = 30 + (30 * i);
            addChild(entry);
        }

        // Progress Bars
        new Text(this, 335, 0, _lang.string("mp_profile_stats"), 15).setAreaParams(295, 22);
        statProgressBar(335, 30, data.aaa, data.total_songs, 0xeae2b9, "AAAs", "#eae2b9");
        statProgressBar(335, 60, data.fc, data.total_songs, 0xbdedbb, "FCs", "#bdedbb");
        statProgressBar(335, 90, data.tier_total, data.total_tier_points, 0xb9c1ea, "Tier Points", "#b9c1ea");
    }

    private function statProgressBar(ox:Number, oy:Number, value:Number, total:Number, color:Number, label:String, textColor:String):void
    {
        this.graphics.lineStyle(1, color, 0.35);
        this.graphics.beginFill(0, 0);
        this.graphics.drawRect(ox, oy, 274, 25);
        this.graphics.endFill();

        this.graphics.lineStyle(0, 0, 0);
        this.graphics.beginFill(color, 0.1);
        this.graphics.drawRect(ox + 1, oy + 1, (value / total) * (274 - 2), 24);
        this.graphics.endFill();

        new Text(this, ox + 5, oy, label, 12, textColor).setAreaParams(264, 26);
        new Text(this, ox + 5, oy, value + " / " + total, 12, textColor).setAreaParams(264, 26, "right");
    }
}

internal class TabRoom extends Sprite
{
    private static const _mp:Multiplayer = Multiplayer.instance;
    private static const _lang:Language = Language.instance;

    private var prompt:MPUserProfilePrompt;
    private var room:MPRoom;

    private var btnOwner:BoxButton;
    private var btnKick:BoxButton;
    private var btnBan:BoxButton;

    public function TabRoom(parent:MPUserProfilePrompt, xpos:Number, ypos:Number, user:MPUser, room:MPRoom):void
    {
        this.prompt = parent;
        this.room = room;
        this.x = xpos;
        this.y = ypos;
        this.visible = false;

        parent.addChild(this);

        btnOwner = new BoxButton(this, 0, 0, 200, 24, 'Promote to Room Owner', 12, e_onPromoteOwner);
        btnBan = new BoxButton(this, 0, 35, 200, 24, '<font color="#ff9b9b">Ban User</font>', 12, e_onBan);
        btnKick = new BoxButton(this, 0, 70, 200, 24, "Kick User", 12, e_onKick);
    }

    private function e_onPromoteOwner(e:Event):void
    {
        _mp.sendCommand(new MPCRoomUserOwner(room, prompt.user));
    }

    private function e_onBan(e:Event):void
    {
        _mp.sendCommand(new MPCRoomUserBlock(room, prompt.user, 1));
    }

    private function e_onKick(e:Event):void
    {
        _mp.sendCommand(new MPCRoomUserBlock(room, prompt.user, 0));
    }
}

internal class TabModerator extends Sprite
{
    private static const BAN_LENGTHS:Vector.<int> = new <int>[2, 5, 30, 60, 1440, 2880, 10080, 20160, 40320, 241920, 525600, 1051200, 52560000];

    private static const _mp:Multiplayer = Multiplayer.instance;
    private static const _lang:Language = Language.instance;

    private var prompt:MPUserProfilePrompt;

    private var inputLength:BoxText;
    private var inputPremade:ComboBox;

    private var btnBan:BoxButton;
    private var btnMute:BoxButton;
    private var btnKick:BoxButton;

    private var messageMod:BoxButton;
    private var messageAdmin:BoxButton;

    public function TabModerator(parent:MPUserProfilePrompt, xpos:Number, ypos:Number, user:MPUser, room:MPRoom):void
    {
        this.prompt = parent;
        this.x = xpos;
        this.y = ypos;
        this.visible = false;

        parent.addChild(this);

        new Text(this, 0, 0, "Ban/Mute Length (minutes):");
        inputLength = new BoxText(this, 0, 30, 149, 23);

        inputPremade = new ComboBox(this, 161, 30, "---", buildDurationLength());
        inputPremade.setSize(151, 25);
        inputPremade.fontSize = 11;
        inputPremade.addEventListener(Event.SELECT, e_durationChange);

        btnMute = new BoxButton(this, 0, 65, 150, 24, '<font color="#ffd6d6">Mute User</font>', 12, e_onMute);
        btnBan = new BoxButton(this, 161, 65, 150, 24, '<font color="#ff9b9b">Ban User</font>', 12, e_onBan);
        btnKick = new BoxButton(this, 322, 65, 150, 24, "Kick User", 12, e_onKick);

        messageMod = new BoxButton(this, 0, 163, 150, 24, '<font color="#A6F968">Message as Mod</font>', 12, e_sendAsMod);
        messageAdmin = new BoxButton(this, 161, 163, 150, 24, '<font color="#F25C5C">Message as Admin</font>', 12, e_sendAsAdmin);
    }

    private function e_onMute(e:Event):void
    {
        var duration:int = parseInt(inputLength.text);
        if (isNaN(duration) || duration <= 0)
            return;

        _mp.sendCommand(new MPCModMuteUser(prompt.user, duration));
    }

    private function e_onBan(e:Event):void
    {
        var duration:int = parseInt(inputLength.text);
        if (isNaN(duration) || duration <= 0)
            return;

        _mp.sendCommand(new MPCModBanUser(prompt.user, duration));
    }

    private function e_onKick(e:Event):void
    {
        _mp.sendCommand(new MPCModBanUser(prompt.user, 0));
    }

    private function e_durationChange(e:Event):void
    {
        inputLength.text = inputPremade.selectedItem.data.toString();
    }

    private function e_sendAsMod(e:Event):void
    {
        prompt.sendChatMessage(1);
    }

    private function e_sendAsAdmin(e:Event):void
    {
        prompt.sendChatMessage(2);
    }

    private function buildDurationLength():Array
    {
        var out:Array = [];

        for (var i:int = 0; i < BAN_LENGTHS.length; i++)
            out.push({"data": BAN_LENGTHS[i], "label": DateUtil.minutesToString(BAN_LENGTHS[i])});

        return out;
    }
}

internal class ProfileScoreEntry extends Sprite
{
    private static const _playlist:Playlist = Playlist.instanceCanon;

    public var score:UserStatsScore;

    public function ProfileScoreEntry(score:UserStatsScore):void
    {
        this.score = score;

        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.beginFill(0xFFFFFF, 0.1);
        this.graphics.drawRect(0, 0, 295, 25);
        this.graphics.endFill();

        var song:SongInfo = _playlist.playList[score.level_id];

        new Text(this, 5, 0, song.name, 11).setAreaParams(245, 26);
        new Text(this, 5, 0, NumberUtil.numberFormat(score.weight, 2, true), 11, "#cccccc").setAreaParams(285, 26, "right");
    }
}
