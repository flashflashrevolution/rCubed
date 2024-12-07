package classes.mp.mode.ffr.mods
{

    public class MPGameplayModBoolean
    {
        public var mod:String;
        public var enabled:Boolean = false;
        public var value:Boolean;

        public function MPGameplayModBoolean(mod:String, enabled:Boolean = false, value:Boolean = false):void
        {
            this.mod = mod;
            this.enabled = enabled;
            this.value = value;
        }
    }
}
