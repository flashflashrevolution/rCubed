/**
 * PushButton.as
 * Keith Peters
 * version 0.9.10
 *
 * A basic button component with a label.
 *
 * Copyright (c) 2011 Keith Peters
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package com.bit101.components
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class PushButton extends Component
    {
        protected var _label:Label;
        protected var _labelText:String = "";
        protected var _over:Boolean = false;
        protected var _down:Boolean = false;
        protected var _selected:Boolean = false;
        protected var _toggle:Boolean = false;
        protected var _align:String = "left";

        /**
         * Constructor
         * @param parent The parent DisplayObjectContainer on which to add this PushButton.
         * @param xpos The x position to place this component.
         * @param ypos The y position to place this component.
         * @param label The string to use for the initial label of this component.
         * @param defaultHandler The event handling function to handle the default event for this component (click in this case).
         */
        public function PushButton(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, label:String = "", defaultHandler:Function = null)
        {
            super(parent, xpos, ypos);
            if (defaultHandler != null)
            {
                addEventListener(MouseEvent.CLICK, defaultHandler);
            }
            this.label = label;
        }

        /**
         * Initializes the component.
         */
        override protected function init():void
        {
            super.init();
            buttonMode = true;
            useHandCursor = true;
            setSize(100, 20);
        }

        /**
         * Creates and adds the child display objects of this component.
         */
        override protected function addChildren():void
        {
            _label = new Label();
            addChild(_label);

            addEventListener(MouseEvent.MOUSE_DOWN, onMouseGoDown);
            addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
        }

        /**
         * Draws the face of the button, color based on state.
         */
        protected function drawFace():void
        {
            this.graphics.clear();
            if (_down)
            {
                this.graphics.lineStyle(1, 0xFFFFFF, 0.55, true);
                this.graphics.beginFill(0xFFFFFF, 0.1225);
            }
            else
            {
                this.graphics.lineStyle(1, 0xFFFFFF, 0.35, true);
                this.graphics.beginFill(0xFFFFFF, 0.07);
            }
            this.graphics.drawRect(0, 0, _width - 1, _height - 1);
            this.graphics.endFill();
        }


        ///////////////////////////////////
        // public methods
        ///////////////////////////////////

        /**
         * Draws the visual ui of the component.
         */
        override public function draw():void
        {
            super.draw();

            drawFace();

            _label.text = _labelText;
            _label.autoSize = true;
            _label.draw();
            if (_label.width > _width - 4)
            {
                _label.autoSize = false;
                _label.width = _width - 4;
            }
            else
            {
                _label.autoSize = true;
            }
            _label.draw();

            if (_align == "center")
                _label.move(_width / 2 - _label.width / 2, _height / 2 - _label.height / 2 - 1);
            else
                _label.move(5, _height / 2 - _label.height / 2 - 1);
        }




        ///////////////////////////////////
        // event handlers
        ///////////////////////////////////

        /**
         * Internal mouseOver handler.
         * @param event The MouseEvent passed by the system.
         */
        protected function onMouseOver(event:MouseEvent):void
        {
            _over = true;
            addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
        }

        /**
         * Internal mouseOut handler.
         * @param event The MouseEvent passed by the system.
         */
        protected function onMouseOut(event:MouseEvent):void
        {
            _over = false;
            removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
        }

        /**
         * Internal mouseOut handler.
         * @param event The MouseEvent passed by the system.
         */
        protected function onMouseGoDown(event:MouseEvent):void
        {
            _down = true;
            drawFace();
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseGoUp);
        }

        /**
         * Internal mouseUp handler.
         * @param event The MouseEvent passed by the system.
         */
        protected function onMouseGoUp(event:MouseEvent):void
        {
            if (_toggle && _over)
            {
                _selected = !_selected;
            }
            _down = _selected;
            drawFace();
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseGoUp);
        }




        ///////////////////////////////////
        // getter/setters
        ///////////////////////////////////

        /**
         * Sets / gets the label text shown on this Pushbutton.
         */
        public function set label(str:String):void
        {
            _labelText = str;
            draw();
        }

        public function get label():String
        {
            return _labelText;
        }

        public function set selected(value:Boolean):void
        {
            if (!_toggle)
            {
                value = false;
            }

            _selected = value;
            _down = _selected;
            drawFace();
        }

        public function get selected():Boolean
        {
            return _selected;
        }

        public function set toggle(value:Boolean):void
        {
            _toggle = value;
        }

        public function get toggle():Boolean
        {
            return _toggle;
        }

        public function set fontSize(val:int):void
        {
            _label.fontSize = val;
        }

        public function set align(dir:String):void
        {
            _align = dir;
            draw();
        }

    }
}
