/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.Box;
    import classes.Text;
    import com.flashfla.utils.NumberUtil;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class StatItem extends Sprite
    {
        //- Song Details
        private var nameText:Text;
        private var scoreText:Text;
        private var resultsText:Text;
        private var rankText:Text;
        public var index:Number;
        public var box:Box;

        public function StatItem(sO:Object, pO:Object):void
        {
            //- Make Display
            box = new Box(577, 52, false);

            //- Name
            nameText = new Text(pO["name"], 14);
            nameText.x = 5;
            nameText.setAreaParams(350, 27);
            box.addChild(nameText);

            //- Score
            scoreText = new Text(NumberUtil.numberFormat(sO["score"]), 14);
            scoreText.x = 70;
            scoreText.setAreaParams(500, 27, Text.RIGHT);
            box.addChild(scoreText);

            //- Results
            resultsText = new Text(sO["results"], 12);
            resultsText.x = 5;
            resultsText.y = 27;
            resultsText.setAreaParams(350, 27);
            box.addChild(resultsText);

            //- Rank
            rankText = new Text("Rank: " + NumberUtil.numberFormat(sO["rank"]), 14);
            rankText.x = 70;
            rankText.y = 27;
            rankText.setAreaParams(500, 27, Text.RIGHT);
            box.addChild(rankText);

            this.addChild(box);
        }

        public function dispose():void
        {
            //- Remove is already existed.
            if (box != null)
            {
                nameText.dispose();
                box.removeChild(nameText);
                nameText = null;
                scoreText.dispose();
                box.removeChild(scoreText);
                scoreText = null;
                resultsText.dispose();
                box.removeChild(resultsText);
                resultsText = null;
                rankText.dispose();
                box.removeChild(rankText);
                rankText = null;
                box.dispose();
                this.removeChild(box);
                box = null;
            }
        }

        override public function get height():Number
        {
            return 52;
        }
    }
}
