package classes.mp
{

    public class MPUser
    {
        private static const _gvars:GlobalVariables = GlobalVariables.instance;

        public var isStale:Boolean = false;

        public var uid:uint;
        public var variables:Object = {};
        public var permissions:MPUserPermissions = new MPUserPermissions();

        public var sid:uint;
        public var name:String;
        public var avatarURL:String;
        public var skillRating:Number = 0;

        // Private Variables
        public var blockList:Array = [];

        private var _nameHTML:String;
        private var _userLabel:String;
        private var _userLabelHTML:String;


        public function update(data:Object):void
        {
            if (data.uid != null)
                this.uid = data.uid;

            if (data.sid != null)
                this.sid = data.sid;

            if (data.permissions != null)
            {
                this.permissions.admin = data.permissions.admin;
                this.permissions.mod = data.permissions.mod;
            }

            if (data.name != null)
                this.name = data.name;

            if (data.avatar != null)
                this.avatarURL = data.avatar;

            if (data.variables != null)
                this.variables = data.variables;

            if (data.skillRating != null)
                this.skillRating = data.skillRating;

            if (data.blockList != null)
                this.blockList = data.blockList;

            buildUserLabels();

            this.isStale = false;
        }

        /**
         * Messy, but works.
         */
        private function buildUserLabels():void
        {
            var prefixS:String = "";
            var prefixH:String = "";

            var suffixS:String = "";
            var suffixH:String = "";

            if (skillRating >= 255)
            {
                prefixS += "[DEV] ";
                prefixH += "<font color=\"#d85454\">[DEV]</font> ";
            }
            else
            {
                prefixS += "[" + skillRating + "] ";
                prefixH += "<font color=\"" + _gvars.getDivisionColor(skillRating) + "\">[" + skillRating + "]</font> ";
            }

            if (permissions.admin)
            {
                prefixH += "<font color=\"" + MPColors.NAME_ADMIN + "\">";
                suffixH += "</font>";
                _nameHTML = "<font color=\"" + MPColors.NAME_ADMIN + "\">" + name + "</font>";
            }
            else if (permissions.mod)
            {
                prefixH += "<font color=\"" + MPColors.NAME_MOD + "\">";
                suffixH += "</font>";
                _nameHTML = "<font color=\"" + MPColors.NAME_MOD + "\">" + name + "</font>";
            }
            else
            {
                _nameHTML = "<font color=\"" + MPColors.NAME_USER + "\">" + name + "</font>";
            }

            // suffixS += " [" + uid + "]";
            // suffixH += " [" + uid + "]";

            _userLabel = prefixS + name + suffixS;
            _userLabelHTML = prefixH + name + suffixH;
        }


        public function get nameHTML():String
        {
            return _nameHTML;
        }

        public function get userLabel():String
        {
            return _userLabel;
        }

        public function get userLabelHTML():String
        {
            return _userLabelHTML;
        }

        public function getVariable(key:String):*
        {
            return variables[key];
        }

        /**
         * Sort Users compare function based on permissions, skill ratings, then name.
         */
        public static function sort(a:MPUser, b:MPUser):int
        {
            // Admins First
            if (a.permissions.admin && b.permissions.admin)
                return b.skillRating - a.skillRating;
            else if (a.permissions.admin && !b.permissions.admin)
                return -1;
            else if (!a.permissions.admin && b.permissions.admin)
                return 1;

            // Mod Second
            if (a.permissions.mod && b.permissions.mod)
                return b.skillRating - a.skillRating;
            else if (a.permissions.mod && !b.permissions.mod)
                return -1;
            else if (!a.permissions.mod && b.permissions.mod)
                return 1;

            // User Third
            if (b.skillRating == a.skillRating)
                return b.name.localeCompare(a.name);

            return b.skillRating - a.skillRating;
        }

        public function toString():String
        {
            return "[MPUser uid=" + uid + ", name=" + name + ", _userLabel=" + _userLabel + "]";
        }
    }
}
