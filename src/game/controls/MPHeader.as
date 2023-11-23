package game.controls
{
    import classes.mp.MPUser;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class MPHeader extends Sprite
    {
        public static const ALIGN_LEFT:String = TextFieldAutoSize.LEFT;
        public static const ALIGN_RIGHT:String = TextFieldAutoSize.RIGHT;

        public var user:MPUser;

        public var avatar:Loader;
        public var field:TextField;

        public function MPHeader(user:MPUser)
        {
            this.user = user;

            field = new TextField();
            field.defaultTextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 18, 0xFFFFFF, true);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.x = 0;
            field.y = 0;
            field.height = 20;
            field.autoSize = TextFieldAutoSize.LEFT;
            field.text = user.name;
            addChild(field);

            avatar = new Loader();
            avatar.contentLoaderInfo.addEventListener(Event.COMPLETE, onAvatarComplete);
            var request:URLRequest = new URLRequest(user.avatarURL);
            avatar.load(request);
        }

        private function onAvatarComplete(event:Event):void
        {
            addChild(avatar);
            position();
        }

        public function set alignment(value:String):void
        {
            field.x = 0;
            field.width = 100;
            field.autoSize = value;
            position();
        }

        private function position():void
        {
            avatar.x = 50 - avatar.width / 2;
            avatar.y = -avatar.height + 25;
            if (field.textWidth < 100)
                field.x = 50 - field.textWidth / 2;
            field.y = -avatar.height - 5;
        }
    }
}
