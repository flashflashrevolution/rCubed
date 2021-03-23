package it.gotoandplay.smartfoxserver.handlers
{
    import it.gotoandplay.smartfoxserver.SmartFoxClient;
    import it.gotoandplay.smartfoxserver.util.Entities;
    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.AdminMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.LoginSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.LeftRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.SpectatorSwitchedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PlayerSwitchedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ConnectionLostSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ConnectionSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.LogoutSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomVariablesUpdateSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomAddedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomDeletedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomListUpdateSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserCountChangeSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.JoinedRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.JoinRoomErrorSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserEnterRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserLeftRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PublicMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PrivateMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ModerationMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserVariablesUpdateSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.CreateRoomErrorSFSEvent;
    import classes.User;
    import classes.Room;

    /**
     * SysHandler class: handles "sys" type messages.
     *
     * @version	1.3.0
     *
     * @author	The gotoAndPlay() Team
     * 			{@link http://www.smartfoxserver.com}
     * 			{@link http://www.gotoandplay.it}
     *
     * @exclude
     */
    public class SysHandler implements IMessageHandler
    {
        private var sfs:SmartFoxClient
        private var handlersTable:Array

        function SysHandler(sfs:SmartFoxClient)
        {
            this.sfs = sfs
            handlersTable = []

            handlersTable["apiOK"] = this.handleApiOK
            handlersTable["apiKO"] = this.handleApiKO
            handlersTable["logOK"] = this.handleLoginOk
            handlersTable["logKO"] = this.handleLoginKo
            handlersTable["logout"] = this.handleLogout
            handlersTable["rmList"] = this.handleRoomList
            handlersTable["uCount"] = this.handleUserCountChange
            handlersTable["joinOK"] = this.handleJoinOk
            handlersTable["joinKO"] = this.handleJoinKo
            handlersTable["uER"] = this.handleUserEnterRoom
            handlersTable["userGone"] = this.handleUserLeaveRoom
            handlersTable["pubMsg"] = this.handlePublicMessage
            handlersTable["prvMsg"] = this.handlePrivateMessage
            handlersTable["dmnMsg"] = this.handleAdminMessage
            handlersTable["modMsg"] = this.handleModMessage
            handlersTable["rVarsUpdate"] = this.handleRoomVarsUpdate
            handlersTable["roomAdd"] = this.handleRoomAdded
            handlersTable["roomDel"] = this.handleRoomDeleted
            handlersTable["uVarsUpdate"] = this.handleUserVarsUpdate
            handlersTable["createRmKO"] = this.handleCreateRoomError
            handlersTable["leaveRoom"] = this.handleLeaveRoom
            handlersTable["swSpec"] = this.handleSpectatorSwitched
            handlersTable["swPl"] = this.handlePlayerSwitched
        }

        /**
         * Handle messages
         */
        public function handleMessage(msgObj:Object, type:String):void
        {
            var xmlData:XML = msgObj as XML
            var action:String = xmlData.body.@action

            // Get handler table
            var fn:Function = handlersTable[action]

            if (fn != null)
            {
                fn.apply(this, [msgObj])
            }

            else
            {
                trace("Unknown sys command: " + action)
            }
        }

        // Handle correct API
        public function handleApiOK(o:Object):void
        {
            sfs.isConnected = true
            var params:Object = {}
            params.success = true

            var evt:TypedSFSEvent = new ConnectionSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        // Handle obsolete API
        public function handleApiKO(o:Object):void
        {
            var params:Object = {}
            params.success = false
            params.error = "API are obsolete, please upgrade"

            var evt:TypedSFSEvent = new ConnectionSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        // Handle successfull login
        public function handleLoginOk(o:Object):void
        {
            var uid:int = int(o.body.login.@id)
            var mod:int = int(o.body.login.@mod)
            var name:String = o.body.login.@n

            sfs.amIModerator = (mod == 1)
            sfs.myUserId = uid
            sfs.myUserName = name
            sfs.playerId = -1

            var params:Object = {}
            params.success = true
            params.name = name
            params.error = ""

            var evt:TypedSFSEvent = new LoginSFSEvent(params)
            sfs.dispatchEvent(evt)

            // Request room list
            sfs.getRoomList()
        }

        // Handle successfull login
        public function handleLoginKo(o:Object):void
        {
            var params:Object = {}
            params.success = false
            params.error = o.body.login.@e

            var evt:TypedSFSEvent = new LoginSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        // Handle successful logout
        public function handleLogout(o:Object):void
        {
            sfs.__logout()

            var evt:TypedSFSEvent = new LogoutSFSEvent()
            sfs.dispatchEvent(evt)
        }

        // Populate the room list for this zone and fire the event
        public function handleRoomList(o:Object):void
        {
            var roomList:Vector.<Room> = new <Room>[]

            for each (var roomXml:XML in o.body.rmList.rm)
            {
                var room:Room = new Room(roomXml.@id, roomXml.n, int(roomXml.@maxu), int(roomXml.@maxs), (roomXml.@game == "1"), (roomXml.@priv == "1"), int(roomXml.@ucnt), int(roomXml.@scnt))

                if (roomXml.vars.toString().length > 0)
                    populateVariables(room.variables, roomXml)

                roomList.push(room)
            }

            var params:Object = {}
            params.roomList = roomList

            var evt:TypedSFSEvent = new RoomListUpdateSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        // Handle the user count change in a room
        public function handleUserCountChange(o:Object):void
        {
            var uCount:int = int(o.body.@u)
            var sCount:int = int(o.body.@s)
            var roomId:int = int(o.body.@r)

            var params:Object = {}
            params.room = roomId
            params.userCount = uCount
            params.specCount = sCount

            var evt:TypedSFSEvent = new UserCountChangeSFSEvent(params)
            sfs.dispatchEvent(evt)
        }


        // Successfull room Join
        public function handleJoinOk(o:Object):void
        {
            var roomId:int = int(o.body.@r)
            var roomVarsXml:XMLList = o.body
            var userListXml:XMLList = o.body.uLs.u
            var playerId:int = int(o.body.pid.@id)

            // Set current active room
            sfs.activeRoomId = roomId

            var room:Room = new Room(roomId)

            // Handle Room Variables
            if (roomVarsXml.vars.toString().length > 0)
                populateVariables(room.variables, roomVarsXml)

            // Populate params user list
            var userVec:Vector.<User> = new <User>[]
            for each (var usr:XML in userListXml)
            {
                // grab the user properties
                var id:int = int(usr.@i)
                var name:String = usr.n
                var isMod:Boolean = usr.@m == "1" ? true : false
                var isSpec:Boolean = usr.@s == "1" ? true : false
                var pId:int = usr.@p == null ? -1 : int(usr.@p)

                // Create and populate User
                var user:User = new User()
                user.id = id
                user.name = name
                user.isModerator = isMod
                user.isSpec = isSpec
                user.playerIdx = pId

                // Handle user variables
                if (usr.vars.toString().length > 0)
                    populateVariables(user.variables, usr)

                // Add user
                userVec.push(user)
            }

            // operation completed, release lock
            sfs.changingRoom = false

            var params:Object = {}
            params.room = room
            params.users = userVec

            var evt:TypedSFSEvent = new JoinedRoomSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        // Failed room Join
        public function handleJoinKo(o:Object):void
        {
            sfs.changingRoom = false

            var params:Object = {}
            params.error = o.body.error.@msg

            var evt:TypedSFSEvent = new JoinRoomErrorSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        // New user enters the room
        public function handleUserEnterRoom(o:Object):void
        {
            var roomId:int = int(o.body.@r)

            // Get params
            var usrId:int = int(o.body.u.@i)
            var usrName:String = o.body.u.n
            var isMod:Boolean = (o.body.u.@m == "1")
            var isSpec:Boolean = (o.body.u.@s == "1")
            var pid:int = o.body.u.@p != null ? int(o.body.u.@p) : -1

            var varList:XMLList = o.body.u.vars["var"]

            // Create new user object
            var newUser:User = new User()
            newUser.id = usrId
            newUser.name = usrName
            newUser.isModerator = isMod
            newUser.isSpec = isSpec
            newUser.playerIdx = pid

            // Populate user vars
            if (o.body.u.vars.toString().length > 0)
                populateVariables(newUser.variables, o.body.u)

            var params:Object = {}
            params.roomId = roomId
            params.user = newUser

            var evt:TypedSFSEvent = new UserEnterRoomSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        // User leaves a room
        public function handleUserLeaveRoom(o:Object):void
        {
            var userId:int = int(o.body.user.@id)
            var roomId:int = int(o.body.@r)

            var params:Object = {}
            params.roomId = roomId
            params.userId = userId

            var evt:TypedSFSEvent = new UserLeftRoomSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        public function handlePublicMessage(o:Object):void
        {
            var roomId:int = int(o.body.@r)
            var userId:int = int(o.body.user.@id)
            var message:String = o.body.txt

            var params:Object = {}
            params.message = Entities.decodeEntities(message)
            params.userId = userId
            params.roomId = roomId

            var evt:TypedSFSEvent = new PublicMessageSFSEvent(params)
            sfs.dispatchEvent(evt)

        }

        public function handlePrivateMessage(o:Object):void
        {
            var roomId:int = int(o.body.@r)
            var userId:int = int(o.body.user.@id)
            var message:String = o.body.txt

            var params:Object = {}
            params.message = Entities.decodeEntities(message)
            params.userId = userId
            params.roomId = roomId

            var evt:TypedSFSEvent = new PrivateMessageSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        public function handleAdminMessage(o:Object):void
        {
            var roomId:int = int(o.body.@r)
            var userId:int = int(o.body.user.@id)
            var message:String = o.body.txt

            var params:Object = {}
            params.message = Entities.decodeEntities(message)
            params.userId = userId
            params.roomId = roomId

            var evt:TypedSFSEvent = new AdminMessageSFSEvent(params)
            sfs.dispatchEvent(evt)

        }

        public function handleModMessage(o:Object):void
        {
            var roomId:int = int(o.body.@r)
            var userId:int = int(o.body.user.@id)
            var message:String = o.body.txt

            var params:Object = {}
            params.message = Entities.decodeEntities(message)
            params.userId = userId
            params.roomId = roomId

            var evt:TypedSFSEvent = new ModerationMessageSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        public function handleRoomVarsUpdate(o:Object):void
        {
            var roomId:int = int(o.body.@r)

            var room:Room = new Room(roomId)
            var changedVars:Array = []

            // Handle Room Variables
            if (o.body.vars.toString().length > 0)
            {
                populateVariables(room.variables, o.body)

                var params:Object = {}
                params.room = room

                var evt:TypedSFSEvent = new RoomVariablesUpdateSFSEvent(params)
                sfs.dispatchEvent(evt)
            }
        }

        public function handleUserVarsUpdate(o:Object):void
        {
            var userId:int = int(o.body.user.@id)
            var changedVars:Array = []

            var user:User = new User(false, false, userId)

            // First, we check if there's actual variables data available
            if (o.body.vars.toString().length > 0)
            {
                populateVariables(user.variables, o.body, changedVars)

                var params:Object = {}
                params.user = user
                params.changedVars = changedVars

                var evt:TypedSFSEvent = new UserVariablesUpdateSFSEvent(params)
                sfs.dispatchEvent(evt)
            }
        }

        private function handleRoomAdded(o:Object):void
        {
            var rId:int = int(o.body.rm.@id)
            var rName:String = o.body.rm.name
            var rMax:int = int(o.body.rm.@max)
            var rSpec:int = int(o.body.rm.@spec)
            var isTemp:Boolean = o.body.rm.@temp == "1"
            var isGame:Boolean = o.body.rm.@game == "1"
            var isPriv:Boolean = o.body.rm.@priv == "1"
            var isLimbo:Boolean = o.body.rm.@limbo == "1"

            // Create room obj
            var room:Room = new Room(rId, rName, rMax, rSpec, isGame, isPriv)

            // Handle Room Variables
            if (o.body.rm.vars.toString().length > 0)
                populateVariables(room.variables, o.body.rm)

            var params:Object = {}
            params.room = room

            var evt:TypedSFSEvent = new RoomAddedSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        private function handleRoomDeleted(o:Object):void
        {
            var roomId:int = int(o.body.rm.@id)

            var params:Object = {}
            params.roomId = roomId

            var evt:TypedSFSEvent = new RoomDeletedSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        private function handleCreateRoomError(o:Object):void
        {
            var errMsg:String = o.body.room.@e

            var params:Object = {}
            params.error = errMsg

            var evt:TypedSFSEvent = new CreateRoomErrorSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        private function handleLeaveRoom(o:Object):void
        {
            var roomId:int = int(o.body.rm.@id)

            var params:Object = {}
            params.roomId = roomId

            var evt:TypedSFSEvent = new LeftRoomSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        private function handleSpectatorSwitched(o:Object):void
        {
            var roomId:int = int(o.body.@r)
            var playerId:int = int(o.body.pid.@id)
            var userId:int

            if (o.body.pid.@u != undefined)
                userId = int(o.body.pid.@u)

            var params:Object = {}
            params.playerId = playerId
            params.roomId = roomId
            params.userId = userId

            var evt:TypedSFSEvent = new SpectatorSwitchedSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        private function handlePlayerSwitched(o:Object):void
        {
            var roomId:int = int(o.body.@r)
            var playerId:int = int(o.body.pid.@id)
            var userId:int

            if (o.body.pid.@u != undefined)
                userId = int(o.body.pid.@u)

            var params:Object = {}
            params.playerId = playerId
            params.roomId = roomId
            params.userId = userId

            var evt:TypedSFSEvent = new PlayerSwitchedSFSEvent(params)
            sfs.dispatchEvent(evt)
        }

        //=======================================================================
        // Other class methods
        //=======================================================================
        /**
         * Takes an SFS variables XML node and store it in an array
         * Usage: for parsing room and user variables
         *
         * @xmlData	 	xmlData		the XML variables node
         */
        private function populateVariables(variables:Object, xmlData:Object, changedVars:Array = null):void
        {
            for each (var v:XML in xmlData.vars["var"])
            {
                var vName:String = v.@n
                var vType:String = v.@t
                var vValue:String = v.toString();
                var value:Object = vValue;

                if (vType == "b")
                    value = (vValue == "1");
                else if (vType == "n")
                    value = Number(vValue);
                else if (vType == "x")
                    value = null;

                if (variables[vName] != value)
                {
                    if (changedVars != null)
                    {
                        changedVars.push(vName);
                        changedVars[vName] = true;
                    }
                    if (value == null)
                        delete variables[vName];
                    else
                        variables[vName] = value;
                }
            }
        }

        public function dispatchDisconnection():void
        {
            var evt:TypedSFSEvent = new ConnectionLostSFSEvent()
            sfs.dispatchEvent(evt)
        }
    }
}
