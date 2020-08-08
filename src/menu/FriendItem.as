/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.Box;
    import classes.Text;

    public class FriendItem extends Box
    {
        private var user_data:Object;

        //- Song Details
        private var nameText:Text;
        private var statusText:Text;

        public function FriendItem(user_data:Object):void
        {
            this.user_data = user_data;
            super(577, 27, false);
        }

        override protected function init():void
        {
            //- Name
            nameText = new Text(user_data["user"], 14);
            nameText.x = 5;
            nameText.width = 350;
            nameText.height = 27;
            this.addChild(nameText);

            //- Diff
            statusText = new Text(user_data["status"], 14);
            statusText.x = 70;
            statusText.width = 500;
            statusText.height = 27;
            statusText.align = Text.RIGHT;
            this.addChild(statusText);

            super.init();
        }

        override public function dispose():void
        {
            nameText.dispose();
            statusText.dispose();

            super.dispose();
        }
    }
}
