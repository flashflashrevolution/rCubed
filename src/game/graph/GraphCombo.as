package game.graph
{
    import flash.display.Sprite;
    import game.GameScoreResult;
    import classes.chart.Song;
    import classes.replay.ReplayNote;

    public class GraphCombo extends GraphBase
    {
        public function GraphCombo(target:Sprite, overlay:Sprite, result:GameScoreResult):void
        {
            super(target, overlay, result);
            init();
        }

        override public function draw():void
        {
            var ratio_x:Number = graphWidth;
            var ratio_y:Number = graphHeight;

            var pos_x:Number;
            var pos_y:Number;

            var song_arrows:int = result.note_count;
            var song_file:Song = result.song;

            var current_combo:int = 0;
            var line_color:int = 0xFCC100;

            if (song_file == null)
            {
                ratio_x /= song_arrows;
                ratio_y /= song_arrows;
            }
            else
            {
                ratio_x /= song_file.chart.Notes[song_file.chart.Notes.length - 1].frame + 5; // 5 Frame Buffer
                ratio_y /= result.max_combo > 0 ? result.max_combo : song_arrows;
                song_arrows = song_file.totalNotes;
            }

            // Draw Combo Graph
            var full_combo:Boolean = true;
            graph.graphics.moveTo(0, 118);
            for (var n:int = 0; n < song_arrows; n++)
            {
                var status:int = result.replay_hit[n];
                if (song_file == null)
                    pos_y = n * ratio_x;
                else
                    pos_y = (song_file.getNote(n).frame * result.options.songRate + song_file.musicStartFrames) * ratio_x;
                if (result.replay_hit.length <= n || (status == -5 && song_file != null))
                {
                    graph.graphics.lineStyle(2, 0xFF0000, 1, true);
                    graph.graphics.lineTo(pos_y, 118);
                    graph.graphics.lineTo(719, 118);
                    break;
                }
                if (status == -10)
                {
                    if (song_file == null)
                    {
                        graph.graphics.lineStyle(1, 0x5F5F5F, 1, true);
                        graph.graphics.moveTo(pos_y, 0);
                        graph.graphics.lineTo(pos_y, 118);
                    }
                    continue;
                }
                else if (status == -5)
                {
                    graph.graphics.lineStyle(2, 0xFF0000, 1, true);
                    graph.graphics.lineTo(pos_y, 118);
                }
                if (status <= 0)
                {
                    current_combo = 0;
                    full_combo = false;
                    line_color = 0xFFFFFF;
                }
                else
                {
                    current_combo++;
                }

                graph.graphics.lineStyle(2, line_color, 1, true);
                graph.graphics.lineTo(pos_y, 118 - current_combo * ratio_y);

                if (status >= 0 && status < 50 && full_combo == true)
                    line_color = 0x00D42A;
                if (status >= 0 && status < 50 && full_combo == false)
                    line_color = 0xFFFFFF;
            }

            if (song_file != null)
            {
                for each (var replayHit:ReplayNote in result.replayData)
                {
                    pos_y = (replayHit.frame * result.options.songRate + song_file.musicStartFrames) * ratio_x;
                    status = replayHit.score;
                    switch (status)
                    {
                        case 25: // Good
                            line_color = 0x40aa40;
                            break;
                        case 5: // Average
                            line_color = 0xa0a000
                            break;
                        case 0: // Boo
                            line_color = 0x804010;
                            break;
                        case -10: // Miss
                            line_color = 0xFF0000;
                            break;
                        default:
                            continue;
                    }
                    graph.graphics.lineStyle(1, line_color, 1, true);
                    graph.graphics.moveTo(pos_y - 2, -2);
                    graph.graphics.lineTo(pos_y + 2, 2);
                    graph.graphics.moveTo(pos_y + 2, -2);
                    graph.graphics.lineTo(pos_y - 2, 2);
                }
            }
        }
    }
}
