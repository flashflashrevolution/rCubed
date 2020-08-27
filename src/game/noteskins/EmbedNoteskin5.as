package game.noteskins
{
    import flash.utils.ByteArray;

    public class EmbedNoteskin5 extends EmbedNoteskinBase
    {
        [Embed(source = "Noteskin5.swf", mimeType = 'application/octet-stream')]
        private static const EMBED_SWF:Class;

        private static const ID:int = 5;

        override public function getData():Object
        {
            return {"id": ID,
                    "name": "Metal",
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
