package game.controls
{
    import classes.User;
    import flash.events.Event;
    import flash.display.Loader;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import flash.text.AntiAliasType;
    import classes.Language;

    public class MPHeader extends Sprite
    {
        public static const ALIGN_LEFT:String = TextFieldAutoSize.LEFT;
        public static const ALIGN_RIGHT:String = TextFieldAutoSize.RIGHT;

        public var user:Object;
        public var userData:User;

        public var avatar:Loader;
        public var field:TextField;

        public function MPHeader(user:Object)
        {
            this.user = user;

            field = new TextField();
            field.defaultTextFormat = new TextFormat(Language.UNI_FONT_NAME, 18, 0xFFFFFF, true);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.x = 0;
            field.y = 0;
            field.height = 20;
            field.autoSize = TextFieldAutoSize.LEFT;
            field.text = user.userName;
            addChild(field);

            avatar = new Loader();
            avatar.contentLoaderInfo.addEventListener(Event.COMPLETE, onAvatarComplete);
            var request:URLRequest = new URLRequest(Constant.USER_AVATAR_URL);
            var vars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(vars);
            vars["cHeight"] = 100;
            vars["cWidth"] = 100;
            if (user.siteID)
                vars["uid"] = user.siteID;
            else
                vars["uname"] = user.userName;
            request.data = vars;
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
            field.y = -avatar.height;
        }
    }
}
