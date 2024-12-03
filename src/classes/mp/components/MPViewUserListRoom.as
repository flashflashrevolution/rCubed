package classes.mp.components
{
    import classes.Language;
    import classes.mp.MPTeam;
    import classes.mp.MPUser;
    import classes.mp.commands.MPCRoomTeamChange;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPUserEvent;
    import classes.mp.room.MPRoom;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class MPViewUserListRoom extends Sprite
    {
        private static const _lang:Language = Language.instance;

        private var _width:Number = 200;
        private var _height:Number = 388;

        private var room:MPRoom;
        private var users:Vector.<MPUser>;

        private var pane:ScrollPane;

        private const scrollbarWidth:Number = 15;
        private var scrollbar:ScrollBar;
        private var scrollbarBG:Sprite;

        private var useTeamView:Boolean = false;

        // Team Dividers
        private const labelHeight:Number = 27;
        private var teamLabels:Vector.<TeamLabel> = new <TeamLabel>[];
        private var userLabels:Vector.<UserLabel> = new <UserLabel>[];

        public function MPViewUserListRoom(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0):void
        {
            this.x = xpos;
            this.y = ypos;

            if (parent)
                parent.addChild(this);
        }

        public function setRoom(room:MPRoom):void
        {
            this.room = room;
            this.users = room.users;

            build();
            update();
        }

        public function build():void
        {
            new Text(this, 5, 0, _lang.string("mp_user_list"), 16, "#FFFFFF").setAreaParams(_width - 60, 30);

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
            useTeamView = room.teams.length > 1;

            var my:Number = 0;

            // Mark as Stale
            teamLabels.forEach(_markStale);
            userLabels.forEach(_markStale);

            var userLabel:UserLabel;

            var team:MPTeam;
            var user:MPUser;

            // Multiple Teams
            if (room.teams.length > 1)
            {
                var teamLabel:TeamLabel;

                for each (team in room.teams)
                {
                    if (team.spectator)
                        my += labelHeight;

                    teamLabel = getTeamLabel(team);
                    teamLabel.y = my;
                    teamLabel.update();

                    my += labelHeight;

                    for each (user in team.users)
                    {
                        userLabel = getUserLabel(user);
                        userLabel.team = team;
                        userLabel.y = my;
                        userLabel.setPlayability(room.canUserPlaySong(user));
                        userLabel.update();
                        my += labelHeight;
                    }

                }
            }
            // Spectators Only
            else if (room.teams.length == 1)
            {
                for each (user in room.teams[0].users)
                {
                    userLabel = getUserLabel(user);
                    userLabel.team = team;
                    userLabel.y = my;
                    userLabel.setPlayability(room.canUserPlaySong(user));
                    userLabel.update();
                    my += labelHeight;
                }
            }

            if (room.type != "lobby")
                userLabels.forEach(_markRoomOwner);

            pane.update();

            // Check for Change in Scrollbar appearence, recalculate widths if needed.
            var oldScrollbarVisible:Boolean = scrollbar.visible;
            scrollbarBG.visible = scrollbar.visible = (pane.content.height > pane.height - 5);

            if (oldScrollbarVisible != scrollbar.visible)
            {
                teamLabels.forEach(_setSize);
                userLabels.forEach(_setSize);
            }

            // Garbage Collect
            _removeStale(teamLabels);
            _removeStale(userLabels);
        }

        private function _markStale(item:BaseLabel, index:int = 0, vector:Vector.<*> = null):void
        {
            item.isStale = true;
        }

        private function _setSize(item:BaseLabel, index:int = 0, vector:Vector.<*> = null):void
        {
            item.setSize(_width - (scrollbar.visible ? scrollbarWidth + 1 : 0), labelHeight);
        }

        private function _removeStale(vec:*):void
        {
            var _vec:Vector.<*> = vec as Vector.<*>;

            for (var i:Number = _vec.length - 1; i >= 0; i--)
            {
                var item:BaseLabel = _vec[i] as BaseLabel;

                if (item.isStale)
                {
                    item.parent.removeChild(item);
                    _vec.removeAt(i);
                }
            }
        }

        private function _markRoomOwner(item:UserLabel, index:int = 0, vector:Vector.<UserLabel> = null):void
        {
            item.setOwnerCrown(room.owner);
        }

        private function e_onUserClick(e:MouseEvent):void
        {
            if (e.target is UserLabel)
            {
                const user:MPUser = (e.target as UserLabel).user;
                if (e.ctrlKey)
                    dispatchEvent(new MPUserEvent(MPEvent.ROOM_USERLIST_SPECTATE, null, user));
                else
                    dispatchEvent(new MPUserEvent(MPEvent.ROOM_USERLIST_SELECT, null, user));
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

        public function updateGameStates():void
        {
            for each (var label:UserLabel in userLabels)
            {
                label.updateGameState();
            }
        }

        // //////
        // Object Pool
        private function getUserLabel(user:MPUser):UserLabel
        {
            for each (var label:UserLabel in userLabels)
            {
                if (user === label.user)
                {
                    label.isStale = false;
                    return label;
                }
            }

            var newLabel:UserLabel = new UserLabel(room, user);
            pane.content.addChild(newLabel);
            userLabels.push(newLabel);
            _setSize(newLabel);

            return newLabel;
        }

        private function getTeamLabel(team:MPTeam):TeamLabel
        {
            for each (var label:TeamLabel in teamLabels)
            {
                if (team === label.team)
                {
                    label.isStale = false;
                    return label;
                }
            }

            var newLabel:TeamLabel = new TeamLabel(room, team);
            pane.content.addChild(newLabel);
            teamLabels.push(newLabel);
            _setSize(newLabel);

            return newLabel;
        }
    }
}

import assets.menu.icons.fa.iconCrown;
import classes.Language;
import classes.mp.MPTeam;
import classes.mp.MPUser;
import classes.mp.Multiplayer;
import classes.mp.commands.MPCRoomTeamChange;
import classes.mp.room.MPRoom;
import classes.mp.room.MPRoomFFR;
import classes.ui.Text;
import classes.ui.Throbber;
import classes.ui.UIIcon;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

internal class BaseLabel extends Sprite
{
    protected static const _mp:Multiplayer = Multiplayer.instance;
    protected static const _lang:Language = Language.instance;

    public var isStale:Boolean = false;

    protected var _width:Number = 184;
    protected var _height:Number = 27;

    public var room:MPRoom;
    public var team:MPTeam;

    protected var nameText:Text;

    public function BaseLabel(room:MPRoom, team:MPTeam = null):void
    {
        this.room = room;
        this.team = team;

        build();
    }

    protected function build():void
    {

    }

    protected function draw():void
    {
        this.graphics.clear();
        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.moveTo(0, _height);
        this.graphics.lineTo(_width, _height);

        this.graphics.lineStyle(0, 0x000000, 0);
        this.graphics.beginFill(0, 0);
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
    }

    public function update():void
    {

    }
}

internal class TeamLabel extends BaseLabel
{
    private var joinText:Text;
    private var _throbber:Throbber;

    public function TeamLabel(room:MPRoom, team:MPTeam):void
    {
        super(room, team);
    }

    override protected function build():void
    {
        nameText = new Text(this, 5, 0, "", 11, "#c7c7c7");
        nameText.setAreaParams(_width - 55, _height);
        nameText.cacheAsBitmap = true;

        joinText = new Text(this, _width, 0, _lang.string("mp_team_join"), 11);
        joinText.setAreaParams(50, _height, "right");
        joinText.mouseEnabled = true;
        joinText.buttonMode = true;
        joinText.addEventListener(MouseEvent.CLICK, e_onTeamJoin);

        _throbber = new Throbber(12, 12, 1);
        _throbber.y = (_height / 2) - 5;
        _throbber.visible = false;
        _throbber.mouseEnabled = false;
        addChild(_throbber);
    }

    override protected function resize():void
    {
        super.resize();
        joinText.x = _width - 55;
        _throbber.x = _width - joinText.textfield.textWidth - 30;
    }

    override public function update():void
    {
        if (_throbber.visible)
        {
            _throbber.stop();
            _throbber.visible = false;
        }

        joinText.visible = team.canJoin && !team.contains(_mp.currentUser) && team.userCount < team.maxUsers;

        if (team.spectator)
            nameText.text = team.name;
        else
            nameText.text = team.name + " [" + team.users.length + " / " + team.maxUsers + "]";
    }

    private function e_onTeamJoin(e:MouseEvent):void
    {
        _mp.sendCommand(new MPCRoomTeamChange(room, team));
        _throbber.visible = true;
        _throbber.start();
    }
}

internal class UserLabel extends BaseLabel
{
    public var user:MPUser;

    private var canPlay:Boolean = false;
    private var ownerCrown:UIIcon;
    private var altText:Text;

    private var hover:Sprite;

    public function UserLabel(room:MPRoom, user:MPUser):void
    {
        this.user = user;
        this.buttonMode = true;
        this.mouseChildren = false;
        super(room);
    }

    override protected function build():void
    {
        ownerCrown = new UIIcon(this, new iconCrown(), 0, _height / 2);
        ownerCrown.setSize(_height, _height);
        ownerCrown.visible = false;
        ownerCrown.alpha = 0.125;

        nameText = new Text(this, 5, 0, user.userLabelHTML, 11, "#FFFFFF");
        nameText.setAreaParams(_width - 11, _height);
        nameText.cacheAsBitmap = true;

        altText = new Text(this, _width - 50, 0, "", 11, "#d3d3d3");
        altText.setAreaParams(40, _height, "right");
        altText.cacheAsBitmap = true;

        hover = new Sprite();
        hover.visible = false;
        addChild(hover);

        this.addEventListener(MouseEvent.ROLL_OVER, e_showHover);
        this.addEventListener(MouseEvent.ROLL_OUT, e_hideHover);
    }

    override protected function resize():void
    {
        super.resize();
        altText.x = _width - 50;
        nameText.width = altText.x - nameText.x - 5;
        ownerCrown.x = _width - 24;

        hover.graphics.clear();
        hover.graphics.beginFill(0xFFFFFF, 0.05);
        hover.graphics.drawRect(0, 0, _width, _height);
        hover.graphics.endFill();
    }

    override public function update():void
    {
        draw();
    }

    override protected function draw():void
    {
        super.draw();

        if (team && !team.spectator)
        {
            nameText.width = _width - 42;

            const barColor:uint = canPlay ? (room.isPlayerReady(user) ? 0x8eff6b : 0xfff76b) : 0xff6b6b;

            this.graphics.lineStyle(0, 0, 0);
            this.graphics.beginFill(barColor, 0.5);
            this.graphics.drawRect(_width - 8, 1, 8, _height - 1);
            this.graphics.endFill();
        }
        else
        {
            nameText.width = _width - 11;
        }
    }

    public function setOwnerCrown(owner:MPUser):void
    {
        ownerCrown.visible = owner === user;
    }

    public function setPlayability(state:Boolean):void
    {
        canPlay = state;
    }

    public function updateGameState():void
    {
        if (room is MPRoomFFR)
        {
            const castRoom:MPRoomFFR = room as MPRoomFFR;
            const playerState:String = castRoom.getPlayerState(user);

            if (playerState == "menu")
            {
                const song_rate:Number = castRoom.getPlayerSongRate(user);
                altText.text = song_rate != 1 ? "[" + song_rate + "x]" : "";
            }
            else if (playerState == "loading")
                altText.text = castRoom.getPlayerLoadingProgress(user) + "%";
            else if (playerState == "game")
                altText.text = "[Playing]";
            else if (playerState == "waiting")
                altText.text = "[Waiting]";
            else if (playerState == "results")
                altText.text = "[Results]";
            else
                altText.text = "";
        }
    }

    private function e_showHover(e:MouseEvent):void
    {
        hover.visible = true;
    }

    private function e_hideHover(e:MouseEvent):void
    {
        hover.visible = false;
    }
}
