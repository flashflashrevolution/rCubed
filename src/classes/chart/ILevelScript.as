package classes.chart
{

    /**
     * @author FictionVoid
     */
    public interface ILevelScript
    {
        function init(runtime:ILevelScriptRuntime):void;
        function hasFrameScript(frame:int):Boolean;
        function doFrameEvent(frame:int):void;
    }

}
