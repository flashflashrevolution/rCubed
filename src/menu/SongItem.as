/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.Box;
    import classes.Text;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class SongItem extends Sprite
    {
        private var _active:Boolean = false;
        private var _song:Array;
        private var _rank:Object;

        //- Song Details
        public var level:Number;
        public var genre:Number;
        public var index:Number;
        public var box:Box;

        private var nameText:Text;
        private var iconText:Text;
        private var diffText:Text;

        public function SongItem(sO:Array, rO:Object, isActive:Boolean = false):void
        {
            this._active = isActive;
            this._song = sO;
            this._rank = rO;

            buildBox();

            //- Set Button Mode
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            this.addEventListener(MouseEvent.ROLL_OVER, boxOver);
        }

        public function dispose():void
        {
            this.removeEventListener(MouseEvent.ROLL_OVER, boxOver);
            this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);

            //- Remove is already existed.
            if (box != null)
            {
                nameText.dispose();
                box.removeChild(nameText);
                nameText = null;
                if (iconText)
                {
                    iconText.dispose();
                    box.removeChild(iconText);
                    iconText = null;
                }
                diffText.dispose();
                box.removeChild(diffText);
                diffText = null;
                box.dispose();
                this.removeChild(box);
                box = null;
            }
        }

        private function boxOver(e:MouseEvent):void
        {
            box.boxOver();
            this.addEventListener(MouseEvent.ROLL_OUT, boxOut);
        }

        private function boxOut(e:MouseEvent):void
        {
            box.boxOut();
            this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);
        }

        private function buildBox():void
        {
            //- Remove is already existed.
            if (box != null)
            {
                this.removeChild(box);
                box = null;
            }

            //- Make Display
            box = new Box(400, 27, false);
            box.active = _active;

            //- Diff
            var SONG_ICON_TEXT:String = GlobalVariables.getSongIcon(_song, _rank);
            if (GlobalVariables.instance.activeUser.DISPLAY_SONG_FLAG && SONG_ICON_TEXT != "")
            {
                iconText = new Text(GlobalVariables.getSongIcon(_song, _rank), 14);
                iconText.x = 271;
                iconText.setAreaParams(100, 27, Text.RIGHT);
                box.addChild(iconText);
            }

            //- Name
            var songname:String = _song["name"];
            if (!_song["engine"] && _song["genre"] == Constant.LEGACY_GENRE)
                songname = '<font color="#004587">[L]</font> ' + songname;

            nameText = new Text(songname, 14);
            nameText.x = 5;
            nameText.setAreaParams(358 - (iconText ? iconText.textfield.textWidth : 0), 27);
            box.addChild(nameText);

            //- Diff
            diffText = new Text(_song["difficulty"], 14);
            diffText.x = 370;
            diffText.setAreaParams(_song["difficulty"] >= 100 ? 30 : 27, 27, Text.RIGHT);
            box.addChild(diffText);

            this.addChild(box);
        }

        public function set active(val:Boolean):void
        {
            _active = val;
            box.active = _active;
            //buildBox();
        }
    }
}
