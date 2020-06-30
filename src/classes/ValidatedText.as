package classes
{
    import flash.events.Event;
    import flash.text.TextFormat;

    public class ValidatedText extends BoxText
    {
        private var m_validator:RegExp;

        public function ValidatedText(width:int = 100, height:int = 20, textformat:TextFormat = null)
        {
            super(width, height, textformat, false);

            super._input.addEventListener(Event.CHANGE, Validate, false, 0, true);
        }

        public override function dispose():void
        {
            super.dispose();

            super._input.removeEventListener(Event.CHANGE, Validate, false);
        }

        public function set validator(expression:RegExp):void
        {
            m_validator = expression;
        }

        private function Validate(e:Event):void
        {
            if (m_validator.test(_input.text))
            {
                super.dispatchEvent(e);
                RenderValid();
            }
            else
            {
                RenderInvalid();
            }
        }

        private function RenderValid():void
        {
            super.color = 0xFFFFFF;
            super.borderColor = 0xFFFFFF;
            super.activeAlpha = 0.35;
            super.borderAlpha = 0.55;
        }

        private function RenderInvalid():void
        {
            super.color = 0xFF0000;
            super.borderColor = 0xFF0000;
            super.activeAlpha = 0.90;
            super.borderAlpha = 0.90;
        }
    }
}
