package game.noteskins
{
    import flash.utils.ByteArray;

    public class EmbedNoteskin6 extends EmbedNoteskinBase
    {
        [Embed(source = "Noteskin6.swf", mimeType = 'application/octet-stream')]
        private static const EMBED_SWF:Class;

        private static const ID:int = 6;

        override public function getData():Object
        {
            return {"id": ID,
                    "name": "Delta",
                    "rotation": 90,
                    "width": 64,
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
