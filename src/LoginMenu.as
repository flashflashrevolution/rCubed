package
{
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxCheck;
    import classes.BoxText;
    import classes.Language;
    import classes.Playlist;
    import classes.SimpleBoxButton;
    import classes.Text;
    import com.flashfla.utils.Crypt;
    import com.flashfla.utils.SpriteUtil;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.net.navigateToURL;
    import flash.ui.Keyboard;
    import menu.MenuPanel;

    public class LoginMenu extends MenuPanel
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _loader:URLLoader;

        private const STORED_NONE:int = 0;
        private const STORED_PASSWORD:int = 1;
        private const STORED_SESSION:int = 2;

        private var savedInfos:Object;

        private var box:Box;
        private var panel_login:Sprite;
        private var panel_session:Sprite;

        private var input_user:BoxText;
        private var input_pass:BoxText;
        private var saveDetails:BoxCheck;

        private var isLoading:Boolean = false;

        public function LoginMenu(myParent:MenuPanel)
        {
            super(myParent);

            savedInfos = loadLoginDetails();
        }

        override public function dispose():void
        {
            if (stage)
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, loginKeyDown);
            super.stageRemove();
        }

        override public function stageAdd():void
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, loginKeyDown);

            //- BG
            box = new Box(300, 140, false);
            box.x = (Main.GAME_WIDTH / 2) - (box.width / 2);
            box.y = (Main.GAME_HEIGHT / 2) - (box.height / 2);
            this.addChild(box);

            // Register Button
            var register_online_btn:BoxButton = new BoxButton(300, 30, _lang.string("register_online"), 12);
            register_online_btn.x = box.x;
            register_online_btn.y = box.y + box.height + 10;
            register_online_btn.addEventListener(MouseEvent.CLICK, registerOnline);
            this.addChild(register_online_btn);

            /// 
            panel_session = new Sprite();

            var draw_pane:Sprite = new Sprite();
            draw_pane.graphics.lineStyle(1, 0xffffff, 0);

            draw_pane.graphics.beginFill(0xffffff, 0.1);
            draw_pane.graphics.drawRect(6, 6, 87, 87);
            draw_pane.graphics.endFill();

            draw_pane.graphics.lineStyle(1, 0xffffff, 0.3);
            draw_pane.graphics.moveTo(100, 50);
            draw_pane.graphics.lineTo(265, 50);
            draw_pane.graphics.moveTo(1, 98);
            draw_pane.graphics.lineTo(box.width, 98);
            panel_session.addChild(draw_pane);

            if (savedInfos.avatar != null)
            {
                try
                {
                    var avatarLoader:Loader = new Loader();
                    avatarLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, displayAvatarComplete);
                    avatarLoader.loadBytes(savedInfos.avatar, AirContext.getLoaderContext());

                    function displayAvatarComplete(e:Event):void
                    {
                        avatarLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, displayAvatarComplete);

                        var userAvatar:DisplayObject = avatarLoader;
                        if (userAvatar && userAvatar.height > 0 && userAvatar.width > 0)
                        {
                            SpriteUtil.scaleTo(userAvatar, 77, 77);
                            userAvatar.x = 11 + ((77 - userAvatar.width) / 2);
                            userAvatar.y = 11 + ((77 - userAvatar.height) / 2);
                            panel_session.addChildAt(userAvatar, 1);
                        }
                    }
                }
                catch (e:Error)
                {

                }
            }

            // Username
            var session_label_user:Text = new Text(_lang.string("login_continue_as"));
            session_label_user.x = 100;
            session_label_user.y = 30;
            panel_session.addChild(session_label_user);

            var session_txt_username:Text = new Text(savedInfos.username ? savedInfos.username : "----", 16, "#F3FAFF");
            session_txt_username.x = 100;
            session_txt_username.y = 50;
            panel_session.addChild(session_txt_username);

            //- Buttons
            var session_continueAsbtn:SimpleBoxButton = new SimpleBoxButton(box.width, 98);
            session_continueAsbtn.addEventListener(MouseEvent.CLICK, attemptLoginSession);
            panel_session.addChild(session_continueAsbtn);

            var session_guestbtn:BoxButton = new BoxButton(120, 30, _lang.string("login_guest"), 12);
            session_guestbtn.x = 6;
            session_guestbtn.y = box.height - 36;
            session_guestbtn.addEventListener(MouseEvent.CLICK, playAsGuest);
            panel_session.addChild(session_guestbtn);

            var session_changeusertbtn:BoxButton = new BoxButton(120, 30, _lang.string("login_change_user"), 12);
            session_changeusertbtn.x = box.width - 126;
            session_changeusertbtn.y = box.height - 36;
            session_changeusertbtn.addEventListener(MouseEvent.CLICK, changeUserEvent);
            panel_session.addChild(session_changeusertbtn);


            /// Login Screen
            panel_login = new Sprite();

            //- Text
            // Username
            var txt_user:Text = new Text(_lang.string("login_name"));
            txt_user.x = 5;
            txt_user.y = 5;
            panel_login.addChild(txt_user);

            input_user = new BoxText(290, 20);
            input_user.x = 5;
            input_user.y = 25;
            panel_login.addChild(input_user);

            // Password
            var txt_pass:Text = new Text(_lang.string("login_pass"));
            txt_pass.x = 5;
            txt_pass.y = 55
            panel_login.addChild(txt_pass);

            input_pass = new BoxText(290, 20);
            input_pass.x = 5;
            input_pass.y = 75;
            input_pass.displayAsPassword = true;
            panel_login.addChild(input_pass);

            saveDetails = new BoxCheck();
            saveDetails.x = 92;
            saveDetails.y = 113;
            saveDetails.addEventListener(MouseEvent.CLICK, toggleDetailsSave);
            panel_login.addChild(saveDetails);

            var txt_save:Text = new Text(_lang.string("login_remember"));
            txt_save.x = 110;
            txt_save.y = 111;
            panel_login.addChild(txt_save);

            //- Buttons
            var login_guestbtn:BoxButton = new BoxButton(75, 30, _lang.string("login_guest"), 12);
            login_guestbtn.x = 6;
            login_guestbtn.y = box.height - 36;
            login_guestbtn.addEventListener(MouseEvent.CLICK, playAsGuest);
            panel_login.addChild(login_guestbtn);

            var loginbtn:BoxButton = new BoxButton(75, 30, _lang.string("login_text"), 12);
            loginbtn.x = box.width - 81;
            loginbtn.y = box.height - 36;
            loginbtn.addEventListener(MouseEvent.CLICK, attemptLogin);
            panel_login.addChild(loginbtn);

            // Set Values
            if (savedInfos.state == STORED_SESSION)
            {

            }
            else if (savedInfos.state == STORED_PASSWORD)
            {
                input_user.text = savedInfos.username;
                input_pass.text = savedInfos.password;
                saveDetails.checked = true;
            }

            // Set Focus when at textboxes
            if (savedInfos.state == STORED_SESSION)
            {
                box.addChild(panel_session);
            }
            else if (savedInfos.state == STORED_NONE || savedInfos.state == STORED_PASSWORD)
            {
                box.addChild(panel_login);
                stage.focus = input_user.field;
                input_user.field.setSelection(input_user.text.length, input_user.text.length);
            }
        }


        private function get rememberPassword():Boolean
        {
            return saveDetails.checked;
        }

        public function toggleDetailsSave(e:Event):void
        {
            saveDetails.checked = !saveDetails.checked;
        }

        public function playAsGuest(e:Event = null):void
        {
            switchTo(Main.GAME_MENU_PANEL);
        }

        public function registerOnline(e:Event = null):void
        {
            navigateToURL(new URLRequest(Constant.USER_REGISTER_URL), "_blank");
        }

        private function changeUserEvent(e:Event):void
        {
            saveLoginDetails(false);

            if (box.contains(panel_session))
                box.removeChild(panel_session);

            box.addChild(panel_login);

            if (savedInfos.username != null)
                input_user.text = savedInfos.username;

            stage.focus = input_user.field;
            input_user.field.setSelection(input_user.text.length, input_user.text.length);
        }

        public function attemptLoginSession(e:Event = null):void
        {
            if (isLoading)
                return;

            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(Constant.USER_LOGIN_URL);
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.username = savedInfos.username;
            requestVars.token = savedInfos.token;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);

            isLoading = true;
        }

        public function attemptLogin(e:Event = null):void
        {
            if (isLoading)
                return;

            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(Constant.USER_LOGIN_URL);
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.username = input_user.text;
            requestVars.password = input_pass.text;
            requestVars.rememberPassword = (this.rememberPassword ? 'true' : 'false');
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);

            setFields(true);
        }

        private function loginKeyDown(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.ENTER)
            {
                // Session Screen
                if (panel_session.stage != null)
                {
                    attemptLoginSession(event);
                }
                // Login Screen
                else
                {
                    if (input_user.text.length > 0)
                        attemptLogin(event);
                    else
                        playAsGuest(event);
                }
            }
        }

        private function loginLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            var _data:Object = JSON.parse(e.target.data);
            if (_data.result == 4)
            {
                isLoading = false;
                _gvars.gameMain.addAlert(_lang.string("login_invalid_session"));
                changeUserEvent(e);
            }
            else if (_data.result >= 1 && _data.result <= 3)
            {
                if (_data.result == 1 || _data.result == 2)
                    saveLoginDetails(this.rememberPassword, _data.session);
                _gvars.userSession = _data.session;
                _gvars.gameMain.loadComplete = false;
                Playlist.clearCanon();
                switchTo("none");
            }
            else
            {
                setFields(false, true);
            }
        }

        private function loginLoadError(e:Event = null):void
        {
            removeLoaderListeners();
            setFields(false);
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, loginLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, loginLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loginLoadError);
        }

        private function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, loginLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, loginLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loginLoadError);
        }

        private function setFields(val:Boolean, isError:Boolean = false):void
        {
            if (val)
            {
                isLoading = true;
                input_user.type = "dynamic";
                input_pass.type = "dynamic";
                input_user.selectable = false;
                input_pass.selectable = false;
                input_user.textColor = 0xD6D6D6;
                input_pass.textColor = 0xD6D6D6;
                input_pass.color = 0xD6D6D6;
                input_pass.borderColor = 0xFFFFFF;
            }
            else
            {
                isLoading = false;
                input_user.type = "input";
                input_pass.type = "input";
                input_user.selectable = true;
                input_pass.selectable = true;
                input_user.textColor = 0xFFFFFF;
                input_pass.textColor = 0xFFFFFF;
                input_pass.color = 0xFFFFFF;
                input_pass.borderColor = 0xFFFFFF;
            }

            if (isError)
            {
                input_pass.text = "";
                input_pass.textColor = 0xFFDBDB;
                input_pass.color = 0xFF0000;
                input_pass.borderColor = 0xFF0000;
            }
        }

        public function saveLoginDetails(saveLogin:Boolean = false, session:String = ""):void
        {
            if (saveLogin && session != "")
            {
                LocalStore.setVariable("uUsername", Crypt.Encode(input_user.text));
                LocalStore.setVariable("uSessionToken", Crypt.Encode(session));
            }
            else
            {
                LocalStore.deleteVariable("uPassword");
                LocalStore.deleteVariable("uUsername");
                LocalStore.deleteVariable("uSessionToken");
                LocalStore.deleteVariable("uAvatar");

                LocalStore.flush();
            }
        }

        public function loadLoginDetails():Object
        {
            var out:Object = {"state": STORED_NONE};

            var username:String = LocalStore.getVariable("uUsername", '');
            var sessionToken:String = LocalStore.getVariable("uSessionToken", '');

            if (sessionToken != '')
            {
                out["state"] = STORED_SESSION;
                out["username"] = Crypt.Decode(username);
                out["token"] = Crypt.Decode(sessionToken);
                out["avatar"] = LocalStore.getVariable("uAvatar", null);
            }
            else if (username != '')
            {
                var password:String = LocalStore.getVariable("uPassword", '');

                out["state"] = STORED_PASSWORD;
                out["username"] = Crypt.Decode(username);
                out["password"] = Crypt.Decode(password);
            }

            return out;
        }

    }
}
