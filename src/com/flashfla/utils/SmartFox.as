package com.flashfla.utils
{
    import flash.events.EventDispatcher;
    import it.gotoandplay.smartfoxserver.SmartFoxClient
    import it.gotoandplay.smartfoxserver.SFSEvent
    import it.gotoandplay.smartfoxserver.data.Room
    import it.gotoandplay.smartfoxserver.data.User
    import it.gotoandplay.smartfoxserver.SFSEvents.ExtensionResponseEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ConnectionEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ConnectionLostEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomAddedEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomDeletedEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.CreateRoomErrorEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PublicMessageEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PrivateMessageEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserCountChangeEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserEnterRoomEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserLeaveRoomEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomListUpdateEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.JoinRoomEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.JoinRoomErrorEvent;

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
                _sfs.addEventListener(SFSEvent.onConnection, onConnection);
                _sfs.addEventListener(SFSEvent.onConnectionLost, onConnectionLost);
                _sfs.addEventListener(SFSEvent.onExtensionResponse, onExtension);
                _sfs.addEventListener(SFSEvent.onRoomListUpdate, onRoomListUpdate);
                _sfs.addEventListener(SFSEvent.onJoinRoom, onJoinRoom);
                _sfs.addEventListener(SFSEvent.onJoinRoomError, onJoinRoomError);
                _sfs.addEventListener(SFSEvent.onRoomAdded, onRoomAdded);
                _sfs.addEventListener(SFSEvent.onRoomDeleted, onRoomDeleted);
                _sfs.addEventListener(SFSEvent.onCreateRoomError, onCreateRoomError);
                _sfs.addEventListener(SFSEvent.onPublicMessage, onPublicMessage);
                _sfs.addEventListener(SFSEvent.onPrivateMessage, onPrivateMessage);
                _sfs.addEventListener(SFSEvent.onUserCountChange, onUserCountChange);
                _sfs.addEventListener(SFSEvent.onUserEnterRoom, onUserEnterRoom);
                _sfs.addEventListener(SFSEvent.onUserLeaveRoom, onUserLeaveRoom);
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

        /*
         * Handler Server connection
         */
        private function onConnection(evt:ConnectionEvent):void
        {
            isConnected = evt.success;

            this.dispatchEvent(evt);
        }

        /*
         * Handler login event
         */
        private function onLogin(evt:ExtensionResponseEvent):void
        {
            var obj:Object = evt.dataObj;
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

        private function onRoomListUpdate(evt:RoomListUpdateEvent):void
        {
            // Dump the names of the available rooms in the current zone
            roomList = evt.roomList;
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
        private function onJoinRoom(evt:JoinRoomEvent):void
        {
            var room:Room = evt.room;
            roomUsers = room.getUserList();

            this.dispatchEvent(evt);
        }

        /*
         * Handle error while joining a room
         */
        private function onJoinRoomError(evt:JoinRoomErrorEvent):void
        {
            trace(evt);
            this.dispatchEvent(evt);
        }

        /*
         * Handle disconnection
         */
        private function onConnectionLost(evt:ConnectionLostEvent):void
        {
            trace(ObjectUtil.print_r(evt));
            this.dispatchEvent(evt);
        }

        private function onRoomAdded(e:RoomAddedEvent):void
        {
            this.dispatchEvent(e);
        }

        private function onRoomDeleted(e:RoomDeletedEvent):void
        {
            this.dispatchEvent(e);
        }

        private function onCreateRoomError(e:CreateRoomErrorEvent):void
        {
            this.dispatchEvent(e);
        }

        private function onPublicMessage(e:PublicMessageEvent):void
        {
            this.dispatchEvent(e);
        }

        private function onPrivateMessage(e:PrivateMessageEvent):void
        {
            this.dispatchEvent(e);
        }

        private function onUserCountChange(e:UserCountChangeEvent):void
        {
            this.dispatchEvent(e);
        }

        private function onUserEnterRoom(e:UserEnterRoomEvent):void
        {
            addUser(e.user);
            this.dispatchEvent(e);
        }

        private function onUserLeaveRoom(e:UserLeaveRoomEvent):void
        {
            removeUser(e.userId);
            this.dispatchEvent(e);
        }

        /*
         * Handles Extension events
         */
        private function onExtension(evt:ExtensionResponseEvent):void
        {
            var obj:Object = evt.dataObj;
            var _cmd:String = obj._cmd;
            if (obj != null)
            {
                if (_cmd == "logOK" || _cmd == "logKO")
                {
                    onLogin(evt);
                }
            }
            this.dispatchEvent(evt);
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
