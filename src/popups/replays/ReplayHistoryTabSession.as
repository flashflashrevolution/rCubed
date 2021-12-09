package popups.replays
{
    import classes.replay.Replay;

    public class ReplayHistoryTabSession extends ReplayHistoryTabBase
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;

        public function ReplayHistoryTabSession(replayWindow:ReplayHistoryWindow):void
        {
            super(replayWindow);
        }

        override public function get name():String
        {
            return "session";
        }

        override public function setValues():void
        {
            var render_list:Array = [];
            for each (var r:Replay in _gvars.replayHistory)
            {
                if (r.song == null)
                    continue;

                if (parent.searchText.length >= 1 && r.song.name.toLowerCase().indexOf(parent.searchText) == -1)
                    continue;

                render_list[render_list.length] = r;
            }
            parent.pane.setRenderList(render_list);
            parent.updateScrollPane();
        }
    }
}
