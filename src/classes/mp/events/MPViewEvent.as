package classes.mp.events
{
    import flash.events.Event;

    public class MPViewEvent extends Event
    {
        public static const CHANGE:String = "change_selected_view";

        public var view:String;

        public function MPViewEvent(view:String)
        {
            super(CHANGE, false, false);

            this.view = view;
        }
    }
}
