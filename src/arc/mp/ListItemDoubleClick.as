package arc.mp
{
    import com.bit101.components.ListItem;
    import flash.display.DisplayObjectContainer;

    public class ListItemDoubleClick extends ListItem
    {
        public function ListItemDoubleClick(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, data:Object = null)
        {
            super(parent, xpos, ypos, data);
            doubleClickEnabled = true;
        }

        public override function draw():void
        {
            super.draw();
            if (_data && _data.hasOwnProperty("labelhtml") && _data.labelhtml)
                _label.html = true;
        }
    }
}
