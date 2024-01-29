package game.controls
{
    import classes.mp.MPTeam;
    import classes.mp.MPUser;
    import classes.mp.room.MPRoomFFR;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import game.GameOptions;
    import classes.mp.mode.ffr.MPMatchFFR;
    import classes.mp.mode.ffr.MPMatchFFRTeam;
    import classes.mp.mode.ffr.MPMatchFFRUser;

    public class MPFFRScoreCompare extends Sprite
    {
        private var options:GameOptions;

        private var room:MPRoomFFR;
        private var labels:Vector.<PlayerLabel> = new <PlayerLabel>[];
        private var labelCount:int = 0;
        private var startY:Number = 0;

        private var match:MPMatchFFR;
        private var useTeamView:Boolean;
        private var isSpectator:Boolean;

        public function MPFFRScoreCompare(options:GameOptions, parent:DisplayObjectContainer, room:MPRoomFFR)
        {
            if (parent)
                parent.addChild(this);

            this.options = options;
            this.match = room.activeMatch;

            useTeamView = match.teams.length > 1;
            isSpectator = options.isSpectator;

            for each (var team:MPMatchFFRTeam in match.teams)
            {
                for each (var user:MPMatchFFRUser in team.users)
                {
                    const text:PlayerLabel = new PlayerLabel(room, user);
                    addChild(text);
                    labels.push(text);

                    if (isSpectator)
                        text.buttonMode = true;

                }
            }

            labelCount = labels.length;

            startY = (Main.GAME_HEIGHT / 2) - ((labelCount / 2) * 40);

            update();
        }

        public function update():void
        {
            labels.sort(sort);

            for (var i:int = 0; i < labelCount; i++)
            {
                labels[i].update();
                labels[i].y = startY + (i * 40);
            }
        }

        public static function sort(a:PlayerLabel, b:PlayerLabel):int
        {
            if (a.data.raw_score > b.data.raw_score)
                return 1;

            return -1;
        }
    }
}

import classes.mp.MPUser;
import classes.mp.Multiplayer;
import classes.mp.mode.ffr.MPMatchFFRUser;
import classes.mp.room.MPRoom;
import classes.mp.room.MPRoomFFR;
import classes.ui.Text;
import flash.display.Sprite;

internal class PlayerLabel extends Sprite
{
    private static const _mp:Multiplayer = Multiplayer.instance;

    public var room:MPRoom;
    public var user:MPUser;
    public var data:MPMatchFFRUser;

    public var isSelf:Boolean = false;

    public var position:Text;
    public var username:Text;
    public var score:Text;

    private var _lastPosition:int = 0;
    private var _lastScore:int = -1;

    public function PlayerLabel(room:MPRoomFFR, data:MPMatchFFRUser):void
    {
        this.room = room;
        this.data = data;
        this.user = data.user;

        isSelf = _mp.currentUser == this.user;

        this.graphics.lineStyle(0, 0, 0);
        this.graphics.beginFill(0x000000, 0.75);
        this.graphics.drawRect(0, 0, 152, 41);
        this.graphics.endFill();

        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.beginFill(isSelf ? 0x91ff89 : 0xFFFFFF, 0.1);
        this.graphics.drawRect(0, 0, 151, 40);
        this.graphics.endFill();

        position = new Text(this, 5, 5, "", 20, "#DBDBDB");
        position.setAreaParams(30, 30, "right");

        username = new Text(this, 40, 2, user.name);

        score = new Text(this, 40, 18, "", 10, "#EAEAEA");
    }

    public function update():void
    {
        if (_lastPosition != data.position)
        {
            position.text = data.position.toString();
            _lastPosition = data.position;
        }

        if (_lastScore != data.raw_score)
        {
            score.text = data.raw_score + " / " + data.good + "-" + data.average + "-" + data.miss + "-" + data.boo;
            _lastScore = data.raw_score;
        }
    }
}
