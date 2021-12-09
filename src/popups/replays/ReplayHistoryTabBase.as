package popups.replays
{
    import classes.replay.Replay;
    import classes.ui.ScrollPaneContent;

    public class ReplayHistoryTabBase
    {
        protected var parent:ReplayHistoryWindow;
        public var container:ScrollPaneContent;

        public function ReplayHistoryTabBase(replayWindow:ReplayHistoryWindow):void
        {
            this.parent = replayWindow;
        }

        public function get name():String
        {
            return null;
        }

        public function openTab():void
        {

        }

        public function closeTab():void
        {

        }

        public function setValues():void
        {

        }

        public function prepareReplay(r:Replay):Replay
        {
            return r;
        }
    }
}
