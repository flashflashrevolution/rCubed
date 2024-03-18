package classes.mp.views
{
    import classes.mp.MPView;
    import classes.mp.components.MPMenuRoomButton;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import flash.display.DisplayObjectContainer;

    public class MPRoomView extends MPView
    {
        protected var roomButton:MPMenuRoomButton;

        public function MPRoomView(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0):void
        {
            super(parent, xpos, ypos);

            addRoomEvents();
            build();
        }

        public function addRoomEvents():void
        {
            _mp.addEventListener(MPEvent.ROOM_EDIT_OK, e_roomEdit);
            _mp.addEventListener(MPEvent.ROOM_UPDATE, e_roomUpdate);
            _mp.addEventListener(MPEvent.ROOM_MESSAGE, e_roomMessage);

            _mp.addEventListener(MPEvent.ROOM_TEAM_UPDATE, e_teamUpdate);
            _mp.addEventListener(MPEvent.ROOM_TEAM_ADD, e_teamUpdate);
            _mp.addEventListener(MPEvent.ROOM_TEAM_REMOVE, e_teamUpdate);
            _mp.addEventListener(MPEvent.ROOM_TEAM_CAPTAIN, e_teamUpdate);

            _mp.addEventListener(MPEvent.ROOM_USER_JOIN, e_userJoin);
            _mp.addEventListener(MPEvent.ROOM_USER_LEAVE, e_userLeave);
        }

        override public function dispose():void
        {
            _mp.removeEventListener(MPEvent.ROOM_EDIT_OK, e_roomEdit);
            _mp.removeEventListener(MPEvent.ROOM_UPDATE, e_roomUpdate);
            _mp.removeEventListener(MPEvent.ROOM_MESSAGE, e_roomMessage);

            _mp.removeEventListener(MPEvent.ROOM_TEAM_UPDATE, e_teamUpdate);
            _mp.removeEventListener(MPEvent.ROOM_TEAM_ADD, e_teamUpdate);
            _mp.removeEventListener(MPEvent.ROOM_TEAM_REMOVE, e_teamUpdate);
            _mp.removeEventListener(MPEvent.ROOM_TEAM_CAPTAIN, e_teamUpdate);

            _mp.removeEventListener(MPEvent.ROOM_USER_JOIN, e_userJoin);
            _mp.removeEventListener(MPEvent.ROOM_USER_LEAVE, e_userLeave);

            onExit()
        }

        public function setRoomButton(btn:MPMenuRoomButton):void
        {
            this.roomButton = btn;
            updateRoomButton();
        }

        protected function updateRoomButton():void
        {

        }

        protected function e_roomEdit(e:MPRoomEvent):void
        {

        }

        protected function e_roomUpdate(e:MPRoomEvent):void
        {

        }

        protected function e_roomMessage(e:MPRoomEvent):void
        {

        }

        protected function e_teamUpdate(e:MPRoomEvent):void
        {

        }

        protected function e_userLeave(e:MPRoomEvent):void
        {

        }

        protected function e_userJoin(e:MPRoomEvent):void
        {

        }
    }
}
