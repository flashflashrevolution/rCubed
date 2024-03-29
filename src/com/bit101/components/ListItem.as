/**
 * ListItem.as
 * Keith Peters
 * version 0.9.10
 *
 * A single item in a list.
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
    import flash.events.MouseEvent;

    public class ListItem extends Component
    {
        protected var _data:Object;
        protected var _label:Label;
        protected var _selected:Boolean;
        protected var _mouseOver:Boolean = false;

        /**
         * Constructor
         * @param parent The parent DisplayObjectContainer on which to add this ListItem.
         * @param xpos The x position to place this component.
         * @param ypos The y position to place this component.
         * @param data The string to display as a label or object with a label property.
         */
        public function ListItem(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, data:Object = null)
        {
            _data = data;
            buttonMode = true;
            super(parent, xpos, ypos);
        }

        /**
         * Initilizes the component.
         */
        protected override function init():void
        {
            super.init();
            addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
            setSize(100, 20);
        }

        /**
         * Creates and adds the child display objects of this component.
         */
        protected override function addChildren():void
        {
            super.addChildren();
            _label = new Label(this, 5, 0);
            _label.fontSize = 11;
            _label.draw();
        }

        ///////////////////////////////////
        // public methods
        ///////////////////////////////////

        /**
         * Draws the visual ui of the component.
         */
        public override function draw():void
        {
            super.draw();
            graphics.clear();

            if (_selected && _mouseOver)
            {
                graphics.beginFill(0xFFFFFF, 0.45);
            }
            else if (_selected)
            {
                graphics.beginFill(0xFFFFFF, 0.35);
            }
            else if (_mouseOver)
            {
                graphics.beginFill(0xFFFFFF, 0.25);
            }
            else
            {
                graphics.beginFill(0xFFFFFF, 0.1);
            }
            graphics.drawRect(0, 0, width, height);
            graphics.endFill();

            if (_data == null)
                return;

            if (_data is String)
            {
                _label.text = _data as String;
            }
            else if (_data.hasOwnProperty("label") && _data.label is String)
            {
                _label.text = _data.label;
            }
            else
            {
                _label.text = _data.toString();
            }
        }




        ///////////////////////////////////
        // event handlers
        ///////////////////////////////////

        /**
         * Called when the user rolls the mouse over the item. Changes the background color.
         */
        protected function onMouseOver(event:MouseEvent):void
        {
            addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            _mouseOver = true;
            invalidate();
        }

        /**
         * Called when the user rolls the mouse off the item. Changes the background color.
         */
        protected function onMouseOut(event:MouseEvent):void
        {
            removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            _mouseOver = false;
            invalidate();
        }



        ///////////////////////////////////
        // getter/setters
        ///////////////////////////////////

        /**
         * Sets/gets the string that appears in this item.
         */
        public function set data(value:Object):void
        {
            _data = value;
            invalidate();
        }

        public function get data():Object
        {
            return _data;
        }

        /**
         * Sets/gets whether or not this item is selected.
         */
        public function set selected(value:Boolean):void
        {
            _selected = value;
            invalidate();
        }

        public function get selected():Boolean
        {
            return _selected;
        }

    }
}
