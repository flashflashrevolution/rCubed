package menu
{

    public class MenuSongSelectionOptions
    {
        public var activeGenre:int = 0;
        public var activeIndex:int = -1;
        public var activeSongId:int = -1;
        public var pageNumber:int = 0;
        public var infoTab:int = 0;

        public var scroll_position:Number = 0;

        public var last_search_text:String;
        public var last_search_type:String;

        public var isFilter:Boolean = false;
        public var filter:Function = null;

        public var queuePlaylist:Array = [];
    }
}
