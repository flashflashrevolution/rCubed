package popups.replays
{
    import classes.Alert;
    import classes.Language;
    import classes.replay.Replay;
    import classes.ui.BoxButton;
    import classes.ui.PromptInput;
    import flash.events.Event;

    public class ReplayHistoryTabSession extends ReplayHistoryTabBase
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        private var btn_import:BoxButton;

        public function ReplayHistoryTabSession(replayWindow:ReplayHistoryWindow):void
        {
            super(replayWindow);
        }

        override public function get name():String
        {
            return "session";
        }

        override public function openTab():void
        {
            // Add UI Elements
            if (!btn_import)
            {
                btn_import = new BoxButton(null, 5, Main.GAME_HEIGHT - 35, 162, 29, _lang.string("popup_replay_import"), 12, e_importClick);
            }
            parent.addChild(btn_import);
        }

        override public function closeTab():void
        {
            parent.removeChild(btn_import);
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
            parent.pane.setRenderList(render_list, false);
            parent.updateScrollPane();
        }

        private function e_importClick(e:Event):void
        {
            new PromptInput(parent, _lang.string("popup_replay_import_window_title"), _lang.string("popup_replay_import"), e_importReplay);
        }

        private function e_importReplay(replayString:String):void
        {
            var r:Replay = new Replay(new Date().getTime());
            r.parseEncode(replayString);
            if (r.isEdited)
                Alert.add(_lang.string("popup_replay_import_edited"), 180);
            if (r.isValid())
            {
                r.loadSongInfo();
                _gvars.replayHistory.unshift(r);
                setValues();
            }
            else
                Alert.add(_lang.string("popup_replay_import_invalid"));
        }
    }
}
