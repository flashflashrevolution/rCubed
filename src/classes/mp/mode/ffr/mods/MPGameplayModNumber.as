package classes.mp.mode.ffr.mods
{

    public class MPGameplayModNumber
    {
        public var mod:String;
        public var enabled:Boolean = false;
        public var value:Number;

        public function MPGameplayModNumber(mod:String, enabled:Boolean = false, value:Number = 1):void
        {
            this.mod = mod;
            this.enabled = enabled;
            this.value = value;
        }
    }
}
