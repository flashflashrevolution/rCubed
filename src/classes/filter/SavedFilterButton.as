package classes.filter
{
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxCheck;
    import classes.Language;
    import classes.Text;
    import com.flashfla.utils.ArrayUtil;
    import com.flashfla.utils.SystemUtil;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import popups.PopupFilterManager;

    public class SavedFilterButton extends Box
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private static var hover_message:Sprite;

        private var updater:PopupFilterManager;
        public var filter:EngineLevelFilter;
        public var filterName:Text;
        public var exportButton:BoxButton;
        public var editButton:BoxButton;
        public var deleteButton:BoxButton;
        public var defaultCheckbox:BoxCheck;

        public function SavedFilterButton(parent:DisplayObjectContainer, xpos:Number, ypos:Number, filter:EngineLevelFilter, updater:PopupFilterManager)
        {
            this.filter = filter;
            this.updater = updater;
            super(parent, xpos, ypos, false, false);
            super.setSize(704, 35);

            init();
        }

        protected function init():void
        {
            defaultCheckbox = new BoxCheck();
            defaultCheckbox.x = 7;
            defaultCheckbox.y = 11;
            defaultCheckbox.checked = filter.is_default;
            defaultCheckbox.addEventListener(MouseEvent.CLICK, e_defaultClick);
            defaultCheckbox.addEventListener(MouseEvent.MOUSE_OVER, e_defaultMouseOver);
            addChild(defaultCheckbox);

            filterName = new Text(filter.name);
            filterName.x = 25;
            filterName.height = 35;
            addChild(filterName);

            deleteButton = new BoxButton(this, width - 105, 5, 100, 23, _lang.string("filter_editor_delete"));
            deleteButton.addEventListener(MouseEvent.CLICK, e_deleteClick);

            editButton = new BoxButton(this, deleteButton.x - 105, 5, 100, 23, _lang.string("filter_editor_select_edit"));
            editButton.addEventListener(MouseEvent.CLICK, e_editClick);

            exportButton = new BoxButton(this, editButton.x - 105, 5, 100, 23, _lang.string("popup_filter_filter_single_export"));
            exportButton.addEventListener(MouseEvent.CLICK, e_exportClick);
        }

        override public function dispose():void
        {
            defaultCheckbox.removeEventListener(MouseEvent.CLICK, e_defaultClick);
            defaultCheckbox.removeEventListener(MouseEvent.MOUSE_OVER, e_defaultMouseOver);
            defaultCheckbox.removeEventListener(MouseEvent.MOUSE_OUT, e_defaultMouseOut);

            filterName.dispose();

            deleteButton.removeEventListener(MouseEvent.CLICK, e_deleteClick);
            deleteButton.dispose();

            editButton.removeEventListener(MouseEvent.CLICK, e_editClick);
            editButton.dispose();

            exportButton.removeEventListener(MouseEvent.CLICK, e_exportClick);
            exportButton.dispose();

            super.dispose();
        }

        private function e_defaultMouseOver(e:Event):void
        {
            defaultCheckbox.addEventListener(MouseEvent.MOUSE_OUT, e_defaultMouseOut);
            if (!hover_message)
            {
                hover_message = new Sprite();
                var msg:Text = new Text(_lang.string("popup_filter_default_filter"));
                msg.height = 23;
                msg.x = 5;
                hover_message.graphics.lineStyle(1, 0xffffff, 0.75);
                hover_message.graphics.beginFill(GameBackgroundColor.BG_POPUP, 1);
                hover_message.graphics.drawRect(0, 0, msg.width + 10, 23);
                hover_message.graphics.endFill();
                hover_message.addChild(msg);
            }

            hover_message.x = defaultCheckbox.x + 19;
            hover_message.y = 5;

            addChild(hover_message)
        }

        private function e_defaultMouseOut(e:Event):void
        {
            defaultCheckbox.removeEventListener(MouseEvent.MOUSE_OUT, e_defaultMouseOut);
            removeChild(hover_message);
        }

        private function e_defaultClick(e:Event):void
        {
            if (!filter.is_default)
                for each (var item:EngineLevelFilter in _gvars.activeUser.filters)
                    item.is_default = false;

            filter.is_default = !filter.is_default;
            defaultCheckbox.checked = filter.is_default;
            updater.draw();
        }

        private function e_editClick(e:Event):void
        {
            _gvars.activeFilter = filter;
            updater.DRAW_TAB = PopupFilterManager.TAB_FILTER;
            updater.draw();
        }

        private function e_deleteClick(e:Event):void
        {
            if (ArrayUtil.remove(filter, _gvars.activeUser.filters))
                updater.draw();
        }

        private function e_exportClick(e:Event):void
        {
            var filterString:String = JSON.stringify(filter.export());
            var success:Boolean = SystemUtil.setClipboard(filterString);
            if (success)
            {
                _gvars.gameMain.addAlert(_lang.string("clipboard_success"), 120, Alert.GREEN);
            }
            else
            {
                _gvars.gameMain.addAlert(_lang.string("clipboard_failure"), 120, Alert.RED);
            }
        }
    }
}
