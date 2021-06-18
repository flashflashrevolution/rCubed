package
{
    import classes.Alert;
    import classes.Language;
    import classes.Playlist;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.BoxCheck;
    import classes.ui.BoxText;
    import classes.ui.SimpleBoxButton;
    import classes.ui.Text;
    import com.flashfla.utils.Crypt;
    import com.flashfla.utils.SpriteUtil;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.ErrorEvent;
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
            saveDetails.dispose();
            super.stageRemove();
        }

        override public function stageAdd():void
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, loginKeyDown);

            //- BG
            box = new Box(this, (Main.GAME_WIDTH - 300) / 2, (Main.GAME_HEIGHT - 140) / 2, false);
            box.setSize(300, 140);

            // Register Button
            var register_online_btn:BoxButton = new BoxButton(this, box.x, box.y + box.height + 10, 300, 30, _lang.string("register_online"), 12, registerOnline);

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
            var session_label_user:Text = new Text(panel_session, 100, 30, _lang.string("login_continue_as"));
            var session_txt_username:Text = new Text(panel_session, 100, 50, savedInfos.username ? savedInfos.username : "----", 16, "#F3FAFF");

            //- Buttons
            var session_continueAsbtn:SimpleBoxButton = new SimpleBoxButton(box.width, 98);
            session_continueAsbtn.addEventListener(MouseEvent.CLICK, attemptLoginSession);
            panel_session.addChild(session_continueAsbtn);

            var session_guestbtn:BoxButton = new BoxButton(panel_session, 6, box.height - 36, 120, 30, _lang.string("login_guest"), 12, playAsGuest);
            var session_changeusertbtn:BoxButton = new BoxButton(panel_session, box.width - 126, box.height - 36, 120, 30, _lang.string("login_change_user"), 12, changeUserEvent);

            /// Login Screen
            panel_login = new Sprite();

            //- Text
            // Username
            var txt_user:Text = new Text(panel_login, 5, 5, _lang.string("login_name"));
            input_user = new BoxText(panel_login, 5, 25, 290, 20);

            // Password
            var txt_pass:Text = new Text(panel_login, 5, 55, _lang.string("login_pass"));
            input_pass = new BoxText(panel_login, 5, 75, 290, 20);
            input_pass.displayAsPassword = true;

            // Save Details
            saveDetails = new BoxCheck(panel_login, 92, 113, toggleDetailsSave);
            var txt_save:Text = new Text(panel_login, 110, 111, _lang.string("login_remember"));

            //- Buttons
            var login_guestbtn:BoxButton = new BoxButton(panel_login, 6, box.height - 36, 75, 30, _lang.string("login_guest"), 12, playAsGuest);
            var loginbtn:BoxButton = new BoxButton(panel_login, box.width - 81, box.height - 36, 75, 30, _lang.string("login_text"), 12, attemptLogin);

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

            Logger.info(this, "Attempting session login for: " + requestVars.username.substr(0, 4) + "..." + requestVars.token.substr(-4));

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

            Logger.info(this, "Attempting login for: " + requestVars.username.substr(0, 4) + "...");

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

            // Parse Response
            var _data:Object;
            var siteDataString:String = e.target.data;
            try
            {
                _data = JSON.parse(siteDataString);
            }
            catch (err:Error)
            {
                Logger.error(this, "Parse Failure: " + Logger.exception_error(err));
                Logger.error(this, "Wrote invalid response data to log folder. [logs/login.txt]");
                AirContext.writeText("logs/login.txt", siteDataString);

                Alert.add(_lang.string("login_connection_error"));
                setFields(false);
                return;
            }

            // Has Response
            if (_data.result == 4)
            {
                Logger.error(this, "Invalid User/Session");
                isLoading = false;
                Alert.add(_lang.string("login_invalid_session"));
                changeUserEvent(e);
            }
            else if (_data.result >= 1 && _data.result <= 3)
            {
                Logger.info(this, "Login Success!");
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

        private function loginLoadError(e:ErrorEvent = null):void
        {
            Logger.error(this, "Login Load Error: " + Logger.event_error(e));
            Alert.add(_lang.string("login_connection_error"));
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
