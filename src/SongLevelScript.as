package
{
    import classes.chart.ILevelScript;
    import classes.chart.ILevelScriptRuntime;

    public class SongLevelScript implements ILevelScript
    {
        private var runtime:ILevelScriptRuntime;
        private var _frameFunctions:Array;

        ////////////////////////////////////////////////////////////////////////////////////////////////////
        public function init(runtime:ILevelScriptRuntime):void
        {
            this.runtime = runtime;
        }

        public function hasFrameScript(frame:int):Boolean
        {
            return (_frameFunctions[frame] != null);
        }

        public function doFrameEvent(frame:int):void
        {
            if (_frameFunctions[frame] != null)
                _frameFunctions[frame]();
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////

        private function clearArrowEffects():void
        {
            runtime.removeMod("dizzy");
            runtime.removeMod("tornado");
        }

        private function arrowEffectTornado():void
        {
            runtime.addMod("tornado");
        }

        private function arrowEffectDizzy():void
        {
            runtime.addMod("dizzy");
        }


        ////////////////////////////////////////////////////////////////////////////////////////////////////

        private function clearArrowVisibility():void
        {
            runtime.removeMod("sudden");
            runtime.removeMod("blink");
        }

        private function arrowVisibilityBlink():void
        {
            runtime.addMod("blink");
        }

        private function arrowVisibilitySudden():void
        {
            runtime.addMod("sudden");
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////

        private function setNoteskin1():void
        {
            runtime.setNoteskin(1);
        }

        private function setNoteskin2():void
        {
            runtime.setNoteskin(2);
        }

        private function setNoteskin3():void
        {
            runtime.setNoteskin(6);
        }

        private function setNoteskin4():void
        {
            runtime.setNoteskin(4);
        }

        private function setNoteskin5():void
        {
            runtime.setNoteskin(9);
        }

        private function setNoteskin6():void
        {
            runtime.setNoteskin(3);
        }

        private function setNoteskin7():void
        {
            runtime.setNoteskin(5);
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////
        // AUTO-MERGED FUNCTIONS
        private function mergeEffectDizzyVisibleSudden():void
        {
            runtime.addMod("dizzy");
            runtime.addMod("sudden");
        }

        private function mergeEffectDizzyVisibleVisible():void
        {
            runtime.addMod("dizzy");
            clearArrowVisibility();
        }

        private function mergeEffectNoneVisibleVisible():void
        {
            clearArrowEffects();
            clearArrowVisibility();
        }

        private function mergeNoteskin1EffectNone():void
        {
            setNoteskin1();
            clearArrowEffects();
        }

        private function mergeNoteskin2EffectNone():void
        {
            setNoteskin2();
            clearArrowEffects();
        }

        private function mergeNoteskin3DarkEffectNoneVisibleSudden():void
        {
            setNoteskin3();
            runtime.addMod("dark");
            runtime.addMod("sudden");
            clearArrowEffects();
        }

        private function mergeNoteskin3VisibleSudden():void
        {
            setNoteskin3();
            runtime.addMod("sudden");
        }

        private function mergeNoteskin4EffectTornado():void
        {
            setNoteskin4();
            runtime.addMod("tornado");
        }

        private function mergeNoteskin4EffectDizzy():void
        {
            setNoteskin4();
            runtime.addMod("tornado");
        }

        private function mergeNoteskin4VisibleVisible():void
        {
            setNoteskin4();
            clearArrowVisibility();
        }

        private function mergeNoteskin6EffectTornado():void
        {
            setNoteskin6();
            runtime.addMod("tornado");
        }

        private function mergeNoteskin6EffectDizzy():void
        {
            setNoteskin6();
            runtime.addMod("tornado");
        }

        private function mergeNoteSkin7EffectNone():void
        {
            setNoteskin7();
            clearArrowEffects();
        }

        private function mergeNoteskin7EffectDizzy():void
        {
            setNoteskin7();
            runtime.addMod("tornado");
        }

        private function mergeNoteskin7EffectDizzyVisibleBlink():void
        {
            setNoteskin7();
            runtime.addMod("tornado");
            runtime.addMod("blink");
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////

        public function SongLevelScript()
        {
            _frameFunctions = [];

            // Frame 1, Basic Setup
            _frameFunctions[1] = function():void
            {
                clearArrowVisibility();
                clearArrowEffects();
                runtime.addMod("_spawn_noteskin_data_rotation");
                runtime.addMod("sudden");
                runtime.setNoteskin(6);
                runtime.setNotePool(false);
            }
            // Everything Else
            _frameFunctions[63] = mergeEffectDizzyVisibleSudden;
            _frameFunctions[77] = clearArrowEffects;
            _frameFunctions[89] = arrowEffectDizzy;
            _frameFunctions[103] = clearArrowEffects;
            _frameFunctions[114] = arrowEffectDizzy;
            _frameFunctions[127] = clearArrowEffects;
            _frameFunctions[137] = arrowEffectDizzy;
            _frameFunctions[151] = clearArrowEffects;
            _frameFunctions[152] = clearArrowEffects;
            _frameFunctions[162] = arrowEffectDizzy;
            _frameFunctions[175] = clearArrowEffects;
            _frameFunctions[185] = arrowEffectDizzy;
            _frameFunctions[198] = clearArrowEffects;
            _frameFunctions[208] = arrowEffectDizzy;
            _frameFunctions[222] = clearArrowEffects;
            _frameFunctions[232] = arrowEffectDizzy;
            _frameFunctions[245] = clearArrowEffects;
            _frameFunctions[255] = arrowEffectDizzy;
            _frameFunctions[267] = clearArrowEffects;
            _frameFunctions[277] = arrowEffectDizzy;
            _frameFunctions[290] = clearArrowEffects;
            _frameFunctions[300] = arrowEffectDizzy;
            _frameFunctions[312] = clearArrowEffects;
            _frameFunctions[322] = arrowEffectDizzy;
            _frameFunctions[334] = clearArrowEffects;
            _frameFunctions[344] = arrowEffectDizzy;
            _frameFunctions[356] = clearArrowEffects;
            _frameFunctions[366] = arrowEffectDizzy;
            _frameFunctions[378] = clearArrowEffects;
            _frameFunctions[388] = arrowEffectDizzy;
            _frameFunctions[399] = clearArrowEffects;
            _frameFunctions[409] = arrowEffectDizzy;
            _frameFunctions[420] = clearArrowEffects;
            _frameFunctions[430] = arrowEffectDizzy;
            _frameFunctions[441] = clearArrowEffects;
            _frameFunctions[451] = arrowEffectDizzy;
            _frameFunctions[462] = clearArrowEffects;
            _frameFunctions[471] = arrowEffectDizzy;
            _frameFunctions[482] = clearArrowEffects;
            _frameFunctions[491] = arrowEffectDizzy;
            _frameFunctions[502] = clearArrowEffects;
            _frameFunctions[512] = arrowEffectDizzy;
            _frameFunctions[523] = clearArrowEffects;
            _frameFunctions[532] = arrowEffectDizzy;
            _frameFunctions[542] = clearArrowEffects;
            _frameFunctions[551] = arrowEffectDizzy;
            _frameFunctions[562] = clearArrowEffects;
            _frameFunctions[571] = arrowEffectDizzy;
            _frameFunctions[582] = clearArrowEffects;
            _frameFunctions[591] = arrowEffectDizzy;
            _frameFunctions[601] = clearArrowEffects;
            _frameFunctions[610] = arrowEffectDizzy;
            _frameFunctions[620] = clearArrowEffects;
            _frameFunctions[629] = arrowEffectDizzy;
            _frameFunctions[639] = clearArrowEffects;
            _frameFunctions[648] = arrowEffectDizzy;
            _frameFunctions[658] = clearArrowEffects;
            _frameFunctions[667] = arrowEffectDizzy;
            _frameFunctions[677] = clearArrowEffects;
            _frameFunctions[686] = arrowEffectDizzy;
            _frameFunctions[696] = clearArrowEffects;
            _frameFunctions[705] = arrowEffectDizzy;
            _frameFunctions[714] = clearArrowEffects;
            _frameFunctions[723] = arrowEffectDizzy;
            _frameFunctions[732] = clearArrowEffects;
            _frameFunctions[741] = arrowEffectDizzy;
            _frameFunctions[750] = clearArrowEffects;
            _frameFunctions[758] = arrowEffectDizzy;
            _frameFunctions[767] = clearArrowEffects;
            _frameFunctions[776] = arrowEffectDizzy;
            _frameFunctions[785] = clearArrowEffects;
            _frameFunctions[794] = arrowEffectDizzy;
            _frameFunctions[803] = clearArrowEffects;
            _frameFunctions[811] = arrowEffectDizzy;
            _frameFunctions[820] = clearArrowEffects;
            _frameFunctions[828] = arrowEffectDizzy;
            _frameFunctions[837] = clearArrowEffects;
            _frameFunctions[845] = arrowEffectDizzy;
            _frameFunctions[854] = clearArrowEffects;
            _frameFunctions[862] = arrowEffectDizzy;
            _frameFunctions[871] = clearArrowEffects;
            _frameFunctions[879] = arrowEffectDizzy;
            _frameFunctions[888] = clearArrowEffects;
            _frameFunctions[896] = arrowEffectDizzy;
            _frameFunctions[905] = clearArrowEffects;
            _frameFunctions[913] = arrowEffectDizzy;
            _frameFunctions[921] = clearArrowEffects;
            _frameFunctions[929] = arrowEffectDizzy;
            _frameFunctions[938] = clearArrowEffects;
            _frameFunctions[946] = arrowEffectDizzy;
            _frameFunctions[954] = clearArrowEffects;
            _frameFunctions[962] = arrowEffectDizzy;
            _frameFunctions[970] = clearArrowEffects;
            _frameFunctions[978] = arrowEffectDizzy;
            _frameFunctions[986] = clearArrowEffects;
            _frameFunctions[994] = arrowEffectDizzy;
            _frameFunctions[1002] = clearArrowEffects;
            _frameFunctions[1010] = arrowEffectDizzy;
            _frameFunctions[1018] = clearArrowEffects;
            _frameFunctions[1026] = arrowEffectDizzy;
            _frameFunctions[1034] = clearArrowEffects;
            _frameFunctions[1041] = arrowEffectDizzy;
            _frameFunctions[1049] = clearArrowEffects;
            _frameFunctions[1057] = arrowEffectDizzy;
            _frameFunctions[1065] = clearArrowEffects;
            _frameFunctions[1072] = arrowEffectDizzy;
            _frameFunctions[1080] = clearArrowEffects;
            _frameFunctions[1087] = arrowEffectDizzy;
            _frameFunctions[1095] = clearArrowEffects;
            _frameFunctions[1102] = arrowEffectDizzy;
            _frameFunctions[1110] = clearArrowEffects;
            _frameFunctions[1117] = arrowEffectDizzy;
            _frameFunctions[1125] = clearArrowEffects;
            _frameFunctions[1132] = arrowEffectDizzy;
            _frameFunctions[1140] = clearArrowEffects;
            _frameFunctions[1147] = arrowEffectDizzy;
            _frameFunctions[1155] = clearArrowEffects;
            _frameFunctions[1162] = arrowEffectDizzy;
            _frameFunctions[1170] = clearArrowEffects;
            _frameFunctions[1177] = arrowEffectDizzy;
            _frameFunctions[1184] = clearArrowEffects;
            _frameFunctions[1191] = arrowEffectDizzy;
            _frameFunctions[1198] = clearArrowEffects;
            _frameFunctions[1205] = arrowEffectDizzy;
            _frameFunctions[1213] = clearArrowEffects;
            _frameFunctions[1220] = arrowEffectDizzy;
            _frameFunctions[1227] = clearArrowEffects;
            _frameFunctions[1234] = arrowEffectDizzy;
            _frameFunctions[1241] = clearArrowEffects;
            _frameFunctions[1248] = arrowEffectDizzy;
            _frameFunctions[1255] = clearArrowEffects;
            _frameFunctions[1262] = arrowEffectDizzy;
            _frameFunctions[1269] = clearArrowEffects;
            _frameFunctions[1276] = arrowEffectDizzy;
            _frameFunctions[1283] = clearArrowEffects;
            _frameFunctions[1290] = arrowEffectDizzy;
            _frameFunctions[1297] = clearArrowEffects;
            _frameFunctions[1304] = arrowEffectDizzy;
            _frameFunctions[1310] = clearArrowEffects;
            _frameFunctions[1317] = arrowEffectDizzy;
            _frameFunctions[1324] = clearArrowEffects;
            _frameFunctions[1331] = arrowEffectDizzy;
            _frameFunctions[1338] = clearArrowEffects;
            _frameFunctions[1345] = arrowEffectDizzy;
            _frameFunctions[1351] = clearArrowEffects;
            _frameFunctions[1358] = arrowEffectDizzy;
            _frameFunctions[1364] = clearArrowEffects;
            _frameFunctions[1371] = arrowEffectDizzy;
            _frameFunctions[1378] = clearArrowEffects;
            _frameFunctions[1385] = arrowEffectDizzy;
            _frameFunctions[1391] = clearArrowEffects;
            _frameFunctions[1398] = arrowEffectDizzy;
            _frameFunctions[1404] = clearArrowEffects;
            _frameFunctions[1411] = mergeEffectDizzyVisibleVisible;
            _frameFunctions[1417] = clearArrowEffects;
            _frameFunctions[1418] = setNoteskin4;
            _frameFunctions[1443] = arrowEffectDizzy;
            _frameFunctions[1822] = setNoteskin3;
            _frameFunctions[2328] = mergeNoteSkin7EffectNone;
            _frameFunctions[2338] = arrowVisibilityBlink;
            _frameFunctions[2453] = mergeNoteskin4VisibleVisible;
            _frameFunctions[2481] = setNoteskin7;
            _frameFunctions[2556] = setNoteskin4;
            _frameFunctions[2584] = setNoteskin7;
            _frameFunctions[2608] = setNoteskin4;
            _frameFunctions[2622] = mergeNoteskin6EffectTornado;
            _frameFunctions[2634] = mergeNoteSkin7EffectNone;
            _frameFunctions[2659] = setNoteskin4;
            _frameFunctions[2687] = setNoteskin7;
            _frameFunctions[2763] = setNoteskin4;
            _frameFunctions[2789] = setNoteskin7;
            _frameFunctions[2842] = arrowVisibilityBlink;
            _frameFunctions[2942] = clearArrowVisibility;
            _frameFunctions[2967] = setNoteskin4;
            _frameFunctions[2986] = setNoteskin7;
            _frameFunctions[3070] = setNoteskin4;
            _frameFunctions[3096] = setNoteskin7;
            _frameFunctions[3122] = setNoteskin4;
            _frameFunctions[3135] = mergeNoteskin6EffectTornado;
            _frameFunctions[3148] = mergeNoteSkin7EffectNone;
            _frameFunctions[3173] = setNoteskin4;
            _frameFunctions[3201] = setNoteskin7;
            _frameFunctions[3276] = setNoteskin4;
            _frameFunctions[3305] = mergeNoteskin6EffectDizzy;
            _frameFunctions[3352] = mergeNoteskin3DarkEffectNoneVisibleSudden;
            _frameFunctions[3404] = setNoteskin1;
            _frameFunctions[3417] = setNoteskin2;
            _frameFunctions[3430] = setNoteskin5;
            _frameFunctions[3436] = setNoteskin7;
            _frameFunctions[3455] = setNoteskin3;
            _frameFunctions[3507] = setNoteskin1;
            _frameFunctions[3520] = setNoteskin2;
            _frameFunctions[3533] = setNoteskin5;
            _frameFunctions[3539] = setNoteskin7;
            _frameFunctions[3558] = setNoteskin3;
            _frameFunctions[3610] = setNoteskin1;
            _frameFunctions[3623] = setNoteskin2;
            _frameFunctions[3636] = setNoteskin5;
            _frameFunctions[3642] = setNoteskin7;
            _frameFunctions[3661] = mergeNoteskin4EffectDizzy;
            _frameFunctions[3667] = mergeNoteskin1EffectNone;
            _frameFunctions[3712] = mergeNoteskin7EffectDizzyVisibleBlink;
            _frameFunctions[3719] = setNoteskin3;
            _frameFunctions[3725] = setNoteskin2;
            _frameFunctions[3732] = setNoteskin1;
            _frameFunctions[3738] = setNoteskin2;
            _frameFunctions[3745] = setNoteskin3;
            _frameFunctions[3751] = setNoteskin7;
            _frameFunctions[3760] = mergeEffectNoneVisibleVisible;
            _frameFunctions[3818] = setNoteskin7;
            _frameFunctions[5110] = mergeNoteskin3VisibleSudden;
            _frameFunctions[5162] = setNoteskin1;
            _frameFunctions[5175] = setNoteskin2;
            _frameFunctions[5188] = setNoteskin5;
            _frameFunctions[5194] = setNoteskin7;
            _frameFunctions[5213] = setNoteskin3;
            _frameFunctions[5265] = setNoteskin1;
            _frameFunctions[5278] = setNoteskin2;
            _frameFunctions[5291] = setNoteskin5;
            _frameFunctions[5297] = setNoteskin7;
            _frameFunctions[5316] = setNoteskin3;
            _frameFunctions[5368] = setNoteskin1;
            _frameFunctions[5381] = setNoteskin2;
            _frameFunctions[5394] = setNoteskin5;
            _frameFunctions[5400] = setNoteskin7;
            _frameFunctions[5419] = setNoteskin4;
            _frameFunctions[5425] = setNoteskin1;
            _frameFunctions[5470] = mergeNoteskin7EffectDizzyVisibleBlink;
            _frameFunctions[5477] = setNoteskin3;
            _frameFunctions[5483] = setNoteskin2;
            _frameFunctions[5490] = setNoteskin1;
            _frameFunctions[5496] = setNoteskin2;
            _frameFunctions[5503] = setNoteskin3;
            _frameFunctions[5509] = setNoteskin7;
            _frameFunctions[5518] = mergeEffectNoneVisibleVisible;
            _frameFunctions[5726] = mergeNoteskin4EffectTornado;
            _frameFunctions[5771] = mergeNoteskin2EffectNone;
            _frameFunctions[5821] = setNoteskin3;
            _frameFunctions[5872] = setNoteskin6;
            _frameFunctions[5924] = mergeNoteskin7EffectDizzy;
            _frameFunctions[6001] = setNoteskin5;
            _frameFunctions[6036] = setNoteskin4;
        }
    }
}
