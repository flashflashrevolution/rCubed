package classes.mp.mode.ffr
{

    import classes.chart.Song;
    import classes.mp.mode.ffr.mods.MPGameplayModBoolean;
    import classes.mp.mode.ffr.mods.MPGameplayModNumber;
    import game.GameOptions;

    public class MPGameplayMods
    {
        public var rate:MPGameplayModNumber = new MPGameplayModNumber("rate");
        public var hidden:MPGameplayModBoolean = new MPGameplayModBoolean("hidden");
        public var sudden:MPGameplayModBoolean = new MPGameplayModBoolean("sudden");
        public var blink:MPGameplayModBoolean = new MPGameplayModBoolean("blink");
        public var rotating:MPGameplayModBoolean = new MPGameplayModBoolean("rotating");
        public var rotate_cw:MPGameplayModBoolean = new MPGameplayModBoolean("rotate_cw");
        public var rotate_ccw:MPGameplayModBoolean = new MPGameplayModBoolean("rotate_ccw");
        public var wave:MPGameplayModBoolean = new MPGameplayModBoolean("wave");
        public var drunk:MPGameplayModBoolean = new MPGameplayModBoolean("drunk");
        public var tornado:MPGameplayModBoolean = new MPGameplayModBoolean("tornado");
        public var mini_resize:MPGameplayModBoolean = new MPGameplayModBoolean("mini_resize");
        public var tap_pulse:MPGameplayModBoolean = new MPGameplayModBoolean("tap_pulse");
        public var nobackground:MPGameplayModBoolean = new MPGameplayModBoolean("nobackground");

        public function update(data:Object):void
        {
            rate.enabled = data.hasOwnProperty(rate.mod);
            rate.value = rate.enabled ? data.rate : 1;

            hidden.enabled = data.hasOwnProperty(hidden.mod);
            hidden.value = hidden.enabled ? data.hidden : false;

            sudden.enabled = data.hasOwnProperty(sudden.mod);
            sudden.value = sudden.enabled ? data.sudden : false;

            blink.enabled = data.hasOwnProperty(blink.mod);
            blink.value = blink.enabled ? data.blink : false;

            rotating.enabled = data.hasOwnProperty(rotating.mod);
            rotating.value = rotating.enabled ? data.rotating : false;

            rotate_cw.enabled = data.hasOwnProperty(rotate_cw.mod);
            rotate_cw.value = rotate_cw.enabled ? data.rotate_cw : false;

            rotate_ccw.enabled = data.hasOwnProperty(rotate_ccw.mod);
            rotate_ccw.value = rotate_ccw.enabled ? data.rotate_ccw : false;

            wave.enabled = data.hasOwnProperty(wave.mod);
            wave.value = wave.enabled ? data.wave : false;

            drunk.enabled = data.hasOwnProperty(drunk.mod);
            drunk.value = drunk.enabled ? data.drunk : false;

            tornado.enabled = data.hasOwnProperty(tornado.mod);
            tornado.value = tornado.enabled ? data.tornado : false;

            mini_resize.enabled = data.hasOwnProperty(mini_resize.mod);
            mini_resize.value = mini_resize.enabled ? data.mini_resize : false;

            tap_pulse.enabled = data.hasOwnProperty(tap_pulse.mod);
            tap_pulse.value = tap_pulse.enabled ? data.tap_pulse : false;

            nobackground.enabled = data.hasOwnProperty(nobackground.mod);
            nobackground.value = nobackground.enabled ? data.nobackground : false;
        }

        /**
         * Check if any gameplay override mod is enabled.
         * @return
         */
        public function enabled():Boolean
        {
            return rate.enabled || hidden.enabled || sudden.enabled || blink.enabled || rotating.enabled || rotate_cw.enabled || rotate_ccw.enabled || wave.enabled || drunk.enabled || tornado.enabled || mini_resize.enabled || tap_pulse.enabled || nobackground.enabled;
        }

        /**
         * Apply gameplay modifications.
         * @param options
         * @param song
         */
        public function apply(options:GameOptions, song:Song):void
        {
            if (rate.enabled && options.songRate != rate.value)
            {
                options.songRate = rate.value;
                song.isDirty = true;
                song.handleDirty(options);
            }

            if (hidden.enabled)
                options.setModBooleanState(hidden.mod, hidden.value);

            if (sudden.enabled)
                options.setModBooleanState(sudden.mod, sudden.value);

            if (blink.enabled)
                options.setModBooleanState(blink.mod, blink.value);

            if (rotating.enabled)
                options.setModBooleanState(rotating.mod, rotating.value);

            if (rotate_cw.enabled)
                options.setModBooleanState(rotate_cw.mod, rotate_cw.value);

            if (rotate_ccw.enabled)
                options.setModBooleanState(rotate_ccw.mod, rotate_ccw.value);

            if (wave.enabled)
                options.setModBooleanState(wave.mod, wave.value);

            if (drunk.enabled)
                options.setModBooleanState(drunk.mod, drunk.value);

            if (tornado.enabled)
                options.setModBooleanState(tornado.mod, tornado.value);

            if (mini_resize.enabled)
                options.setModBooleanState(mini_resize.mod, mini_resize.value);

            if (tap_pulse.enabled)
                options.setModBooleanState(tap_pulse.mod, tap_pulse.value);

            if (nobackground.enabled)
                options.setModBooleanState(nobackground.mod, nobackground.value);
        }
    }
}
