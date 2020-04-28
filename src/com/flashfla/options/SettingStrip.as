/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.options
{
    import assets.options.optionsBracket;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class SettingStrip extends Sprite
    {
        public static const VALUE_CHANGED:String = "ValueChanged";

        private var _settings:Object;
        private var _selIndex:uint;
        private var _deselect:Boolean;
        private var _spacing:int;

        private var _settingClips:Array;

        private var _selBox:Sprite;
        private var _selBoxI:Sprite;
        private var _selBoxL:optionsBracket;
        private var _selBoxR:optionsBracket;

        public var setting:String;

        ///- Constructor
        public function SettingStrip(setting:String, settings:Array, selIndex:uint = -1, canDeselect:Boolean = false, spacing:int = 31)
        {
            this._deselect = canDeselect;
            this._settings = settings;
            this._spacing = spacing;
            this._selIndex = selIndex;

            this.setting = setting;

            init();
        }

        private function init():void
        {
            var curX:int = 0;
            _settingClips = new Array();

            // Draw Box
            if (_selIndex > -1 && _selBox == null)
            {
                drawSelectedBox();
                this.addChild(_selBox);
            }

            // Draw Settings
            for (var x:int = 0; x < _settings.length; x++)
            {
                // Build Text
                var settingTF:TextField = new TextField();
                settingTF.height = 22;
                settingTF.selectable = false;
                settingTF.embedFonts = true;
                settingTF.antiAliasType = AntiAliasType.ADVANCED;
                settingTF.autoSize = TextFieldAutoSize.LEFT;
                settingTF.text = _settings[x];
                settingTF.setTextFormat(txF);

                // Build container
                var settingMC:Sprite = new Sprite();
                settingMC.x = curX;
                settingMC.index = x;
                settingMC.mouseEnabled = true;
                settingMC.mouseChildren = false;
                settingMC.addChild(settingTF);
                settingMC.addEventListener(MouseEvent.CLICK, settingClicked);

                this.addChild(settingMC);
                this._settingClips.push(settingMC);

                // Update X Position
                curX += settingMC.width + this._spacing;
            }

            if (_selIndex > -1 && _selBox != null)
            {
                setSelected(_selIndex);
            }
        }

        private function settingClicked(e:MouseEvent = null):void
        {
            setSelected(e.target.index == this._selIndex && this._deselect == true ? -1 : e.target.index);
            dispatchEvent(new Event(Event.CHANGE));
        }

        private function setSelected(index:int):void
        {
            _selIndex = index;

            var indexDims:Object = this.getIndexDimensions(_selIndex);

            // Draw Box if missing
            if (_selBox == null)
            {
                drawSelectedBox();
                this.addChild(_selBox);
            }

            if (index == -1)
                _selBox.visible = false;
            else
                _selBox.visible = true;

            // Adjust Properties
            _selBox.x = indexDims.x - 13;
            _selBox.y = indexDims.y - 4;
            _selBoxI.width = indexDims.width + 27;
            _selBoxR.x = indexDims.width + 27;
        }

        private function getIndexDimensions(index:int):Object
        {
            if (index > -1 && index < _settingClips.length)
                return {x: _settingClips[index].x, y: _settingClips[index].y, width: _settingClips[index].width, height: 44};
            else
                return {x: 0, y: 0, width: 0, height: 0};
        }

        private function drawSelectedBox():void
        {
            // Create new Container
            _selBox = new Sprite();

            // Draw White Background
            _selBoxI = new Sprite();
            _selBoxI.graphics.beginFill(0xFFFFFF, 0.35);
            _selBoxI.graphics.drawRect(0, 0, 70, 44);
            _selBoxI.graphics.endFill();

            // Draw Brackets
            _selBoxL = new optionsBracket();
            _selBoxL.x = 0;
            _selBoxL.y = 0;

            _selBoxR = new optionsBracket();
            _selBoxR.x = 70;
            _selBoxR.y = 44;
            _selBoxR.rotation = 180;

            _selBox.addChild(_selBoxI);
            _selBox.addChild(_selBoxL);
            _selBox.addChild(_selBoxR);
        }

        ///- Public Accessors
        public function get selected():int
        {
            return _selIndex;
        }

        public function set selected(index:int):void
        {
            this.setSelected(index);
        }
    }
}
