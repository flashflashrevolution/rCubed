package classes.mp
{
    import classes.Language;

    public class MPModes
    {
        private static const _lang:Language = Language.instance;

        public static function getTeamModes():Array
        {
            return [{"data": "ffa", "label": _lang.stringSimple("mp_room_team_type_ffa")},
                {"data": "team", "label": _lang.stringSimple("mp_room_team_type_team")}];
        }

        public static function getMaxPlayers():Array
        {
            const out:Array = [];
            for (var i:Number = 1; i <= 10; i++)
                out[out.length] = i;
            return out;
        }

        public static function getTeams():Array
        {
            const out:Array = [];
            for (var i:Number = 2; i <= 5; i++)
                out[out.length] = i;
            return out;
        }

        public static function getTeamMaxPlayers():Array
        {
            const out:Array = [];
            for (var i:Number = 1; i <= 5; i++)
                out[out.length] = i;
            return out;
        }

    }
}
