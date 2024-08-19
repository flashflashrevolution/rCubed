package classes.mp.events
{
    import classes.mp.MPSocketDataText;
    import flash.events.Event;

    public class MPEvent extends Event
    {
        // Multiplayer Events
        public static const SOCKET_CONNECT:String = "socket_connect";
        public static const SOCKET_DISCONNECT:String = "socket_disconnect";
        public static const SOCKET_ERROR:String = "socket_disconnect";

        public static const SYS_LOGIN_OK:String = "sys_login_ok";
        public static const SYS_LOGIN_FAIL:String = "sys_login_fail";
        public static const SYS_GENERAL_ERROR:String = "sys_error";
        public static const SYS_ROOM_ERROR:String = "sys_room_error";
        public static const SYS_USER_ERROR:String = "sys_user_error";
        public static const SYS_ROOM_LIST:String = "sys_room_list";
        public static const SYS_USER_LIST:String = "sys_user_list";

        public static const ROOM_UPDATE:String = "room_update";
        public static const ROOM_CREATE_OK:String = "room_create_ok";
        public static const ROOM_CREATE_FAIL:String = "room_create_fail";
        public static const ROOM_DELETE_OK:String = "room_delete_ok";
        public static const ROOM_DELETE_FAIL:String = "room_delete_fail";
        public static const ROOM_JOIN_OK:String = "room_join_ok";
        public static const ROOM_JOIN_FAIL:String = "room_join_fail";
        public static const ROOM_LEAVE_OK:String = "room_leave_ok";
        public static const ROOM_LEAVE_FAIL:String = "room_leave_fail";
        public static const ROOM_EDIT_OK:String = "room_edit_ok";
        public static const ROOM_EDIT_FAIL:String = "room_edit_fail";
        public static const ROOM_USER_JOIN:String = "room_user_join";
        public static const ROOM_USER_LEAVE:String = "room_user_leave";
        public static const ROOM_TEAM_ADD:String = "room_team_add";
        public static const ROOM_TEAM_REMOVE:String = "room_team_remove";
        public static const ROOM_TEAM_CAPTAIN:String = "room_team_captain";
        public static const ROOM_TEAM_UPDATE:String = "room_team_update";
        public static const ROOM_MESSAGE:String = "room_message";

        public static const USER_UPDATE:String = "user_update";
        public static const USER_EDIT_OK:String = "user_edit_ok";
        public static const USER_EDIT_FAIL:String = "user_edit_fail";
        public static const USER_MESSAGE:String = "user_message";
        public static const USER_MESSAGE_READ:String = "user_message_read";
        public static const USER_ROOM_INVITE:String = "user_room_invite";
        public static const USER_BLOCK_UPDATE:String = "user_block_update";

        public static const FFR_GAME_STATE:String = "ffr_game_state";
        public static const FFR_PLAYABLE_STATE:String = "ffr_playable_state";
        public static const FFR_READY_STATE:String = "ffr_ready_state";
        public static const FFR_FORCE_START:String = "ffr_force_start";
        public static const FFR_SONG_RATE:String = "ffr_song_rate";
        public static const FFR_SONG_CHANGE:String = "ffr_song_change";
        public static const FFR_SONG_REQUEST:String = "ffr_song_request";
        public static const FFR_LOADING_START:String = "ffr_loading_start";
        public static const FFR_LOADING:String = "ffr_loading";
        public static const FFR_LOADING_ABORT:String = "ffr_loading_abort";
        public static const FFR_COUNTDOWN:String = "ffr_countdown";
        public static const FFR_MATCH_START:String = "ffr_match_start";
        public static const FFR_SONG_START:String = "ffr_song_start";
        public static const FFR_SCORE_UPDATE:String = "ffr_score_update";
        public static const FFR_GET_PLAYBACK:String = "ffr_get_playback";
        public static const FFR_MATCH_END:String = "ffr_match_end";

        public static const FFR_RAW_APPEND_PLAYBACK:int = 0;
        public static const FFR_RAW_REQUEST_PLAYBACK:int = 1;

        public static const RAW_TYPE_SYS:int = 1;
        public static const RAW_TYPE_USER:int = 2;
        public static const RAW_TYPE_ROOM:int = 3;
        public static const RAW_TYPE_MODE:int = 4;

        // UI Events
        public static const ROOM_USERLIST_SELECT:String = "ROOM_USERLIST_SELECT";
        public static const ROOM_USERLIST_SPECTATE:String = "ROOM_USERLIST_SPECTATE";

        public var command:MPSocketDataText;

        public function MPEvent(type:String, command:MPSocketDataText)
        {
            super(type, false, false);

            this.command = command;
        }

        override public function toString():String
        {
            return "---------------------------------\n[MPEvent type=" + type + "]" + "\n" + command;
        }
    }
}
