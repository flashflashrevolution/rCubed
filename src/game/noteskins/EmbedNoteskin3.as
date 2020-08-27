package game.noteskins
{
    import flash.utils.ByteArray;

    public class EmbedNoteskin3 extends EmbedNoteskinBase
    {
        [Embed(source = "Noteskin3.swf", mimeType = 'application/octet-stream')]
        private static const EMBED_SWF:Class;

        private static const ID:int = 3;

        override public function getData():Object
        {
            return {"id": ID,
                    "name": "BeatMania",
                    "rotation": 0,
                    "width": 88,
                    "height": 64}
        }

        override public function getBytes():ByteArray
        {
            return new EMBED_SWF();
        }

        override public function getID():int
        {
            return ID;
        }
    }
}
