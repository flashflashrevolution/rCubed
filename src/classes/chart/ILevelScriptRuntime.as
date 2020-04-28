package classes.chart
{
    import game.GameOptions;
    import game.GamePlay;

    /**
     * @author FictionVoid
     */
    public interface ILevelScriptRuntime
    {
        function destroy():void;

        function registerNoteskin(json_data:String):Boolean;
        function unregisterNoteskin(id:int):Boolean;

        function addMod(mod:String):void;
        function removeMod(mod:String):void;

        function setNotescale(value:Number):void;
        function setNoteskin(id:int):void;

        function setNotePool(enabled:Boolean):void;

        function getOptions():GameOptions;
        function getGameplay():GamePlay;
    }

}
