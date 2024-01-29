package classes.mp
{

    public class MPSong
    {
        public var id:uint;
        public var level_id:String;

        public var name:String;
        public var author:String;
        public var time:String;
        public var note_count:Number;
        public var difficulty:Number;

        public var engine:Object;

        public var selected:Boolean = false;

        public function update(data:Object):void
        {
            selected = data.selected;
            name = data.name;
            author = data.author;
            time = data.time;
            note_count = data.note_count;
            difficulty = data.difficulty;
            engine = data.engine;
            id = data.id;
            level_id = data.level_id;
        }
    }
}
