package game.results
{

    import classes.Language;
    import classes.mp.mode.ffr.MPMatchResultsFFR;
    import classes.mp.mode.ffr.MPMatchResultsTeam;
    import classes.mp.mode.ffr.MPMatchResultsUser;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class GameResultFFRScoreList extends Sprite
    {
        private static const _lang:Language = Language.instance;

        private var _width:Number = 719;
        private var _height:Number = 235;

        private var handler:Function;

        private var match:MPMatchResultsFFR;
        private var users:Vector.<MPMatchResultsUser>;

        private var pane:ScrollPane;

        private const scrollbarWidth:Number = 15;
        private var scrollbar:ScrollBar;
        private var scrollbarBG:Sprite;

        private var useTeamView:Boolean = false;

        // Team Dividers
        private const labelHeight:Number = 35;
        private var teamLabels:Vector.<TeamLabel> = new <TeamLabel>[];
        private var userLabels:Vector.<UserLabel> = new <UserLabel>[];

        public function GameResultFFRScoreList(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0):void
        {
            this.x = xpos;
            this.y = ypos;

            if (parent)
                parent.addChild(this);
        }

        public function setHandler(handler:Function):void
        {
            this.handler = handler;
        }

        public function setRoom(match:MPMatchResultsFFR):void
        {
            this.match = match;
            this.users = match.users;

            build();
            update();
        }

        public function build():void
        {
            pane = new ScrollPane(this, 0, 0, _width, _height, e_scrollMouseWheel);
            pane.content.addEventListener(MouseEvent.CLICK, e_onPaneClick);

            // Scroll Bar
            scrollbarBG = new Sprite();
            scrollbarBG.x = _width + 1;
            scrollbarBG.y = -1;
            addChild(scrollbarBG);

            scrollbar = new ScrollBar(this, _width + 1, -1, scrollbarWidth, _height + 2, null, new Sprite(), e_scrollbarUpdater);

            // Graphics
            redraw();
        }

        public function dispose():void
        {
            pane.content.removeEventListener(MouseEvent.CLICK, e_onPaneClick);
        }

        public function redraw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(0, 0, 0);

            // Scroll BG
            scrollbarBG.graphics.clear();

            scrollbarBG.graphics.lineStyle(1, 0xFFFFFF, 0.20);
            scrollbarBG.graphics.moveTo(scrollbarWidth, 0);
            scrollbarBG.graphics.lineTo(scrollbarWidth, _height + 2);
        }

        public function update():void
        {
            var my:Number = 0;

            var userLabel:UserLabel;

            var team:MPMatchResultsTeam;
            var user:MPMatchResultsUser;

            // Multiple Teams
            if (match.teamMode)
            {
                var teamLabel:TeamLabel;

                for each (team in match.teams)
                {
                    teamLabel = getTeamLabel(team);
                    teamLabel.y = my;

                    my += labelHeight;

                    for each (user in team.users)
                    {
                        userLabel = getUserLabel(user);
                        userLabel.y = my;
                        userLabel.textRank.visible = false;
                        my += labelHeight;
                    }
                }
            }
            // Single Team
            else
            {
                for each (user in match.teams[0].users)
                {
                    userLabel = getUserLabel(user);
                    userLabel.y = my;
                    my += labelHeight;
                }
            }

            pane.update();

            scrollbar.visible = (pane.content.height > pane.height - 5);
        }

        private function e_onPaneClick(e:MouseEvent):void
        {
            if (!handler)
                return;

            if (e.target is UserLabel)
                handler((e.target as UserLabel).user.index);
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
        private function getUserLabel(user:MPMatchResultsUser):UserLabel
        {
            var newLabel:UserLabel = new UserLabel(user);
            pane.content.addChild(newLabel);

            return newLabel;
        }

        private function getTeamLabel(team:MPMatchResultsTeam):TeamLabel
        {
            var newLabel:TeamLabel = new TeamLabel(team);
            pane.content.addChild(newLabel);

            return newLabel;
        }
    }
}

import classes.ImageCache;
import classes.Language;
import classes.mp.mode.ffr.MPMatchResultsTeam;
import classes.mp.mode.ffr.MPMatchResultsUser;
import classes.ui.ScrollPane;
import classes.ui.Text;
import com.flashfla.utils.NumberUtil;
import flash.display.DisplayObjectContainer;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;

internal class BaseLabel extends Sprite
{
    private static var BG_WINNER:Array = [0xD6BA00, 0xD6BA00];
    private static var BG_NORMAL:Array = [0xFFFFFF, 0xFFFFFF];
    private static var BG_ALPHA:Array = [0.10, 0.025];
    private static var BG_RATIO:Array = [0, 255];
    private static var BG_MATRIX:Matrix = new Matrix();
    {
        BG_MATRIX.createGradientBox(719, 35, 0);
    }

    protected var _width:Number = 719;
    protected var _height:Number = 35;

    private var hover:Sprite;
    public var textRank:Text;
    protected var textName:Text;
    protected var textScore:Text;

    public function BaseLabel():void
    {
        this.mouseChildren = false;

        this.addEventListener(MouseEvent.ROLL_OVER, e_showHover);
        this.addEventListener(MouseEvent.ROLL_OUT, e_hideHover);

        build();
    }

    protected function build():void
    {
        hover = new Sprite();
        hover.visible = false;
        hover.graphics.lineStyle(0, 0, 0);
        hover.graphics.beginFill(0xFFFFFF, 0.05);
        hover.graphics.drawRect(0, 0, _width, _height);
        hover.graphics.endFill();
        addChild(hover);
    }

    protected function draw(isWinner:Boolean):void
    {
        this.graphics.lineStyle(1, 0xFFFFFF, 0.15);
        this.graphics.moveTo(0, _height - 1);
        this.graphics.lineTo(_width - 1, _height - 1);

        this.graphics.lineStyle(0, 0, 0);
        this.graphics.beginGradientFill(GradientType.LINEAR, isWinner ? BG_WINNER : BG_NORMAL, BG_ALPHA, BG_RATIO, BG_MATRIX);
        this.graphics.drawRect(0, 0, _width - 1, _height - 1);
        this.graphics.endFill();
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

internal class TeamLabel extends BaseLabel
{
    private var team:MPMatchResultsTeam;

    public function TeamLabel(team:MPMatchResultsTeam):void
    {
        this.team = team;

        super();
    }

    override protected function build():void
    {
        draw(team.position == 1);

        textRank = new Text(this, 0, 0, team.position, 12, "#c7c7c7");
        textRank.setAreaParams(25, _height, "center");
        textRank.cacheAsBitmap = true;

        textName = new Text(this, 25, 0, team.name);
        textName.setAreaParams(220, _height);
        textName.cacheAsBitmap = true;

        textScore = new Text(this, 230, 0, NumberUtil.numberFormat(team.raw_score));
        textScore.setAreaParams(100, _height, "center");
        textScore.cacheAsBitmap = true;

        super.build();
    }
}

internal class UserLabel extends BaseLabel
{
    public var user:MPMatchResultsUser;

    private var avatar:Sprite;

    private var textRate:Text;

    private var textAmazing:Text;
    private var textPerfect:Text;
    private var textGood:Text;
    private var textAverage:Text;
    private var textMiss:Text;
    private var textBoo:Text;
    private var textMaxCombo:Text;

    public function UserLabel(user:MPMatchResultsUser):void
    {
        this.user = user;
        this.buttonMode = true;

        super();
    }

    override protected function build():void
    {
        draw(user.position == 1);

        textRank = new Text(this, 0, 0, user.position, 12, "#c7c7c7");
        textRank.setAreaParams(25, _height, "center");

        textName = new Text(this, 50, 0, user.userLabelHTML);
        textName.setAreaParams(185, _height);

        avatar = ImageCache.getImage(user.avatarURL, ImageCache.ALIGN_MIDDLE, 25, 25);
        avatar.x = 36 + ((25 - avatar.width) / 2);
        avatar.y = (_height / 2) + ((25 - avatar.height) / 2);
        addChild(avatar);

        textRate = new Text(this, 50, 0, "[" + NumberUtil.numberFormat(user.score.options.songRate) + "x]", 12, "#c7c7c7");
        textRate.setAreaParams(185, _height, "right");
        textRate.visible = user.score.options.songRate != 1;

        textScore = new Text(this, 230, 0, NumberUtil.numberFormat(user.score.score));
        textScore.setAreaParams(100, _height, "center");

        textPerfect = new Text(this, 330, 0, NumberUtil.numberFormat(user.score.amazing + user.score.perfect), 12, "#DCFFCB");
        textPerfect.setAreaParams(64, _height, "center");

        textGood = new Text(this, 394, 0, NumberUtil.numberFormat(user.score.good), 12, "#C1FFBD");
        textGood.setAreaParams(64, _height, "center");

        textAverage = new Text(this, 458, 0, NumberUtil.numberFormat(user.score.average), 12, "#BCE9C1");
        textAverage.setAreaParams(64, _height, "center");

        textMiss = new Text(this, 522, 0, NumberUtil.numberFormat(user.score.miss), 12, "#FFE0E0");
        textMiss.setAreaParams(64, _height, "center");

        textBoo = new Text(this, 586, 0, NumberUtil.numberFormat(user.score.boo), 12, "#E7D0B8");
        textBoo.setAreaParams(64, _height, "center");

        textMaxCombo = new Text(this, 650, 0, NumberUtil.numberFormat(user.score.max_combo), 12);
        textMaxCombo.setAreaParams(64, _height, "center");

        if (!user.alive)
        {
            textRank.alpha = avatar.alpha = textName.alpha = textScore.alpha = textPerfect.alpha = textGood.alpha = textAverage.alpha = textMiss.alpha = textBoo.alpha = textMaxCombo.alpha = 0.4;
        }

        super.build();
    }
}
