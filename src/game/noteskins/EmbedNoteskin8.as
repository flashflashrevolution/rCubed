package game.noteskins
{
    import flash.utils.ByteArray;

    public class EmbedNoteskin8 extends EmbedNoteskinBase
    {
        [Embed(source = "Noteskin8.swf", mimeType = 'application/octet-stream')]
        private static const EMBED_SWF:Class;

        private static const ID:int = 8;

        override public function getData():Object
        {
            return {"id": ID,
                    "name": "BeatMania (v2)",
                    "rotation": 0,
                    "width": 70,
                    "height": 51}
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
