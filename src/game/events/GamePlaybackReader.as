package game.events
{
    import flash.utils.ByteArray;

    public class GamePlaybackReader
    {
        public static function parse(data:ByteArray, initialPosition:int = 0, output:Vector.<GamePlaybackEvent> = null):Vector.<GamePlaybackEvent>
        {
            var lastIndex:int = -1;

            // Use new History if not provided.
            if (output == null)
                output = new <GamePlaybackEvent>[];
            else if (output.length > 0)
                lastIndex = output[output.length - 1].index;

            try
            {
                data.position = initialPosition;

                while (data.bytesAvailable > 0)
                {
                    var TAG:int = data.readUnsignedByte();
                    var LEN:int = data.readUnsignedByte();

                    var event:GamePlaybackEvent;

                    switch (TAG)
                    {
                        case GamePlaybackScoreState.ID:
                            event = GamePlaybackScoreState.readData(data);
                            break;

                        case GamePlaybackJudgeResult.ID:
                            event = GamePlaybackJudgeResult.readData(data);
                            break;

                        case GamePlaybackKeyDown.ID:
                            event = GamePlaybackKeyDown.readData(data);
                            break;

                        case GamePlaybackKeyUp.ID:
                            event = GamePlaybackKeyUp.readData(data);
                            break;

                        case GamePlaybackFocusChange.ID:
                            event = GamePlaybackFocusChange.readData(data);
                            break;

                        case GamePlaybackSpectatorHit.ID:
                            event = GamePlaybackSpectatorHit.readData(data);
                            break;

                        case GamePlaybackSpectatorEnd.ID:
                            event = GamePlaybackSpectatorEnd.readData(data);
                            break;

                        default:
                            trace("unknown tag", TAG, "length", LEN);
                            event = null;
                            data.position += LEN;
                            break;
                    }

                    if (event == null)
                        continue;

                    if (event.index > lastIndex)
                        output.push(event);
                }

            }
            catch (e:Error)
            {
                return null;
            }

            return output;
        }
    }
}
