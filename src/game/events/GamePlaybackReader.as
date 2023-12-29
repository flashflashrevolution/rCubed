package game.events
{
    import flash.utils.ByteArray;

    public class GamePlaybackReader
    {
        public static function parse(data:ByteArray, initialPosition:int = 0, output:Vector.<GamePlaybackEvent> = null):Vector.<GamePlaybackEvent>
        {
            trace("read start");
            // Use new History if not provided.
            if (output == null)
                output = new <GamePlaybackEvent>[];

            try
            {
                data.position = initialPosition;

                while (data.bytesAvailable > 0)
                {
                    var TAG:int = data.readUnsignedByte();
                    var LEN:int = data.readUnsignedByte();

                    switch (TAG)
                    {
                        case GamePlaybackJudgeResult.ID:
                            output.push(GamePlaybackJudgeResult.readData(data));
                            break;

                        case GamePlaybackKeyDown.ID:
                            output.push(GamePlaybackKeyDown.readData(data));
                            break;

                        case GamePlaybackKeyUp.ID:
                            output.push(GamePlaybackKeyUp.readData(data));
                            break;

                        case GamePlaybackFocusChange.ID:
                            output.push(GamePlaybackFocusChange.readData(data));
                            break;

                        default:
                            trace("unknown tag", TAG, "length", LEN);
                            data.position += LEN;
                            break;
                    }
                }

            }
            catch (e:Error)
            {
                return null;
            }

            for (var i:int = 0; i < output.length; i++)
            {
                trace(output[i]);
            }
            return output;
        }
    }
}
