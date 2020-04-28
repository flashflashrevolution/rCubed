package com.flashfla.utils
{
    import flash.events.EventDispatcher;
    import it.gotoandplay.smartfoxserver.SmartFoxClient
    import it.gotoandplay.smartfoxserver.SFSEvent
    import it.gotoandplay.smartfoxserver.data.Room
    import it.gotoandplay.smartfoxserver.data.User

    public class SmartFox extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:SmartFox = null;
        private var _sfs:SmartFoxClient;

        // Connection constants
        private const extensionName:String = "ffr_MPZoneExt";
        private const serverZone:String = "ffr_mp";
        //private const extensionName:String = "ffr_MPZoneExtVelo";
        //private const serverZone:String = "ffr_mp_velocity"
        private const serverIp:String = "96.30.8.143"
        private const serverPort:int = 8082

        private var myUsername:String;
        private var myUserID:int;
        private var mySiteID:int;
        private var myMPLevel:int;
        private var myMPClass:int;

        public var roomList:Object;
        public var roomUsers:Array;
        public var isConnected:Boolean = false;

        public function init(forceNew:Boolean = false):void
        {
            if (_sfs == null || forceNew)
            {
                // Create server instance
                _sfs = new SmartFoxClient(false);

                // Add event listeners
                // IRRFUSCATOR_ignorebegin
                _sfs.addEventListener(SFSEvent.onConnection, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onConnectionLost, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onExtensionResponse, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onRoomListUpdate, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onJoinRoom, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onJoinRoomError, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onRoomAdded, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onRoomDeleted, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onCreateRoomError, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onPublicMessage, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onPrivateMessage, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onUserCountChange, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onUserEnterRoom, onSFSEvent);
                _sfs.addEventListener(SFSEvent.onUserLeaveRoom, onSFSEvent);
                // IRRFUSCATOR_ignoreend

                // Connect to server
                connect();
            }
        }

        /*
         * Establish connection with the server
         */
        public function connect():void
        {
            _sfs.connect(serverIp, serverPort);
        }

        /*
         * Login into the server using the provided details
         */
        public function login(user:String, pass:String):void
        {
            _sfs.login(serverZone, user, pass);
        }

        //---------------------------------------------------------------------
        // SmartFoxClient Event Handlers
        //---------------------------------------------------------------------

        private function onSFSEvent(evt:SFSEvent):void
        {
            switch (evt.type)
            {
                case SFSEvent.onConnection:
                    onConnection(evt);
                    break;

                case SFSEvent.onExtensionResponse:
                    onExtension(evt);
                    break;

                case SFSEvent.onRoomListUpdate:
                    onRoomListUpdate(evt);
                    break;

                case SFSEvent.onJoinRoom:
                    onJoinRoom(evt);
                    break;

                case SFSEvent.onJoinRoomError:
                    onJoinRoomError(evt);
                    break;

                case SFSEvent.onConnectionLost:
                    onConnectionLost(evt);
                    break;

                case SFSEvent.onRoomAdded:
                    onRoomAdded(evt);
                    break;

                case SFSEvent.onRoomDeleted:
                    onRoomDeleted(evt);
                    break;

                case SFSEvent.onCreateRoomError:
                    onCreateRoomError(evt);
                    break;

                case SFSEvent.onPublicMessage:
                    onPublicMessage(evt);
                    break;

                case SFSEvent.onPrivateMessage:
                    onPrivateMessage(evt);
                    break;

                case SFSEvent.onUserCountChange:
                    onUserCountChange(evt);
                    break;

                case SFSEvent.onUserEnterRoom:
                    onUserEnterRoom(evt);
                    break;

                case SFSEvent.onUserEnterRoom:
                    onUserLeaveRoom(evt);
                    break;
            }
            trace(evt);
            trace("1:" + ObjectUtil.print_r(evt.params));
            trace("--------");
            this.dispatchEvent(evt);
        }

        /*
         * Handler Server connection
         */
        private function onConnection(evt:SFSEvent):void
        {
            isConnected = evt.params.success;
        }

        /*
         * Handler login event
         */
        private function onLogin(evt:SFSEvent):void
        {
            var obj:Object = evt.params.dataObj;
            var ok:Boolean = obj._cmd == "logOK";
            if (ok)
            {
                _sfs.myUserName = myUsername = obj.name;
                _sfs.myUserId = myUserID = obj.userID;
                mySiteID = obj.siteID;
                myMPLevel = obj.userlevel;
                myMPClass = obj.userclass;
                _sfs.getRoomList();
            }
        }

        private function onRoomListUpdate(evt:SFSEvent):void
        {
            // Dump the names of the available rooms in the current zone
            roomList = evt.params.roomList;
            //for (var r:String in evt.params.roomList)
            //trace(evt.params.roomList[r].getName())

            if (_sfs.activeRoomId == -1)
            {
                _sfs.autoJoin();
            }
            this.dispatchEvent(evt);
        }

        /*
         * Handler a join room event
         */
        private function onJoinRoom(evt:SFSEvent):void
        {
            var room:Room = evt.params.room as Room;
            roomUsers = room.getUserList();
        }

        /*
         * Handle error while joining a room
         */
        private function onJoinRoomError(evt:SFSEvent):void
        {
            trace(evt);
        }

        /*
         * Handle disconnection
         */
        private function onConnectionLost(evt:SFSEvent):void
        {
            trace(ObjectUtil.print_r(evt.params));
        }

        private function onRoomAdded(e:SFSEvent):void
        {

        }

        private function onRoomDeleted(e:SFSEvent):void
        {

        }

        private function onCreateRoomError(e:SFSEvent):void
        {

        }

        private function onPublicMessage(e:SFSEvent):void
        {

        }

        private function onPrivateMessage(e:SFSEvent):void
        {

        }

        private function onUserCountChange(e:SFSEvent):void
        {

        }

        private function onUserEnterRoom(e:SFSEvent):void
        {
            addUser(e.params.user as User);
        }

        private function onUserLeaveRoom(e:SFSEvent):void
        {
            removeUser(e.params.userId);
        }

        /*
         * Handles Extension events
         */
        private function onExtension(evt:SFSEvent):void
        {
            var obj:Object = evt.params.dataObj;
            var _cmd:String = obj._cmd;
            if (obj != null)
            {
                if (_cmd == "logOK" || _cmd == "logKO")
                {
                    onLogin(evt);
                }
            }
        }

        private function addUser(user:User):void
        {
            var isFound:Boolean = false;
            for each (var u:User in roomUsers)
            {
                if (u.getId() == user.getId())
                {
                    isFound = true;
                }
            }
            if (!isFound)
            {
                roomUsers.push(user);
            }
        }

        private function removeUser(uid:int):void
        {
            if (roomUsers.length < uid)
                return;
            if (roomUsers[uid] == null)
                return;
            roomUsers.splice(uid, 1);
        }

        //---------------------------------------------------------------------
        // SmartFox Class
        //---------------------------------------------------------------------
        ///- Constructor
        public function SmartFox(en:SingletonEnforcer)
        {
            if (en == null)
            {
                throw Error("Multi-Instance Blocked");
            }
        }

        public static function get instance():SmartFox
        {
            if (_instance == null)
            {
                _instance = new SmartFox(new SingletonEnforcer());
            }
            return _instance;
        }

        public function get sfs():SmartFoxClient
        {
            return _sfs;
        }
    }
}

class SingletonEnforcer
{
}
