package arc
{
    import classes.chart.Note;
    import classes.chart.Song;
    import game.GameOptions;

    public class NoteMod extends Object
    {
        private var song:Song;
        private var notes:Array;
        private var shuffle:Array;
        private var lastChord:Object;

        private const DIRECTIONS:Array = ['L', 'D', 'U', 'R'];
        private const HALF_COLOUR:Object = {"red": "red", "blue": "red", "purple": "purple", "yellow": "blue", "pink": "purple", "orange": "yellow", "cyan": "pink", "green": "orange", "white": "white"}

        public var options:GameOptions;

        public var modDark:Boolean;
        public var modHidden:Boolean;
        public var modMirror:Boolean;
        public var modRandom:Boolean;
        public var modScramble:Boolean;
        public var modShuffle:Boolean;
        public var modReverse:Boolean;
        public var modColumnColour:Boolean;
        public var modHalfTime:Boolean;
        public var modNoBackground:Boolean;
        public var modIsolation:Boolean;
        public var modOffset:Boolean;
        public var modRate:Boolean;
        public var modFPS:Boolean;
        public var modJudgeWindow:Boolean;

        private var reverseLastFrame:int;
        private var reverseLastPos:Number;

        public function NoteMod(song:Song, options:GameOptions)
        {
            this.song = song;
            this.options = options;

            updateMods();
        }

        public function updateMods():void
        {
            modDark = options.modEnabled("dark");
            modHidden = options.modEnabled("hidden");
            modMirror = options.modEnabled("mirror");
            modRandom = options.modEnabled("random");
            modScramble = options.modEnabled("scramble");
            modShuffle = options.modEnabled("shuffle");
            modReverse = options.modEnabled("reverse");
            modColumnColour = options.modEnabled("columncolour");
            modHalfTime = options.modEnabled("halftime");
            modNoBackground = options.modEnabled("nobackground");
            modIsolation = options.isolation;
            modOffset = options.offsetGlobal != 0;
            modRate = options.songRate != 1;
            modFPS = options.frameRate > 30;
            modJudgeWindow = Boolean(options.judgeWindow);

            reverseLastFrame = -1;
            reverseLastPos = -1;
        }

        public function start(options:GameOptions):void
        {
            this.options = options;

            updateMods();

            if (modShuffle)
            {
                shuffle = new Array();
                for (var i:int = 0; i < 4; i++)
                {
                    var map:int;
                    while (shuffle.indexOf((map = int(Math.random() * 4))) >= 0)
                    {
                    }
                    shuffle.push(map);
                }
            }

            notes = song.chart.Notes;

            lastChord = {frame: 0, values: [], previousValues: [], notes: []};
        }

        private function valueOfDirection(direction:String):int
        {
            return DIRECTIONS.indexOf(direction.charAt(0));
        }

        private function directionOfValue(value:int):String
        {
            return DIRECTIONS[value].toString();
        }

        public static function noteModRequired(options:GameOptions):Boolean
        {
            var mod:NoteMod = new NoteMod(null, options);
            return mod.required();
        }

        public function required():Boolean
        {
            return modIsolation || modRandom || modScramble || modShuffle || modColumnColour || modHalfTime || modMirror || modOffset || modRate;
        }

        public function transformNote(index:int):Note
        {
            if (modIsolation)
                index += options.isolationOffset;

            if (modReverse)
            {
                index = notes.length - 1 - index;
                if (reverseLastFrame < 0)
                {
                    reverseLastFrame = notes[notes.length - 1].frame - song.musicDelay * 2;
                    reverseLastPos = notes[notes.length - 1].time - ((song.musicDelay * 2) / 30);
                }
            }

            var note:Note = notes[index];
            if (note == null)
                return null;

            var pos:Number = note.time;
            var colour:String = note.colour;
            var frame:Number = note.frame;
            var dir:int = valueOfDirection(note.direction);

            frame -= song.musicDelay;
            pos -= (song.musicDelay / 30);

            if (modReverse)
            {
                frame = reverseLastFrame - frame + song.mp3Frame + 60;
                pos = reverseLastPos - pos + (song.mp3Frame + 60) / 30;
            }

            if (modRate)
            {
                pos /= options.songRate;
                frame /= options.songRate;
            }

            if (modOffset)
            {
                var goffset:int = Math.round(options.offsetGlobal);
                frame += goffset;
                pos += goffset / 30;
            }

            if (modMirror)
                dir = -dir + 3;

            if (modShuffle)
                dir = shuffle[dir];

            if (modRandom || modScramble)
            {
                if (lastChord.frame != int(frame))
                {
                    lastChord.frame = int(frame);
                    lastChord.previousValues = lastChord.values;
                    lastChord.values = [];
                    lastChord.notes = [];
                }
                var value:Object = lastChord.values[lastChord.notes.indexOf(note)];
                if (value != null)
                    dir = int(value);
                else
                {
                    while (lastChord.values.indexOf(dir = int(Math.random() * 4)) != -1)
                    {
                    }
                    for (var i:int = 0; i < 3 && modScramble && lastChord.previousValues.indexOf(dir) != -1; i++)
                        while (lastChord.values.indexOf(dir = int(Math.random() * 4)) != -1)
                        {
                        }
                    lastChord.values.push(dir);
                    lastChord.notes.push(note);
                }
            }

            if (modColumnColour)
                colour = (dir % 3) ? "blue" : "red";

            if (modHalfTime)
                colour = HALF_COLOUR[colour] || colour;

            return new Note(directionOfValue(dir), pos, colour, int(frame));
        }

        public function transformTotalNotes():int
        {
            if (!notes)
                return 0;

            if (modIsolation)
            {
                if (options.isolationLength > 0)
                {
                    return Math.min(options.isolationLength, Math.max(1, notes.length - options.isolationOffset));
                }
                else
                {
                    return Math.max(1, notes.length - options.isolationOffset);
                }
            }
            return notes.length;
        }

        public function transformSongLength():Number
        {
            if (!notes || notes.length <= 0)
                return 0;

            var firstNote:Note;
            var lastNote:Note = notes[notes.length - 1];
            var time:Number = lastNote.time;

            if (modIsolation)
            {

                if (options.isolationLength > 0)
                {
                    firstNote = notes[Math.min(notes.length - 1, options.isolationOffset)];
                    lastNote = notes[Math.min(notes.length - 1, options.isolationOffset + options.isolationLength)];
                    time = lastNote.time - firstNote.time;
                }
                else
                {
                    firstNote = notes[Math.min(notes.length - 1, options.isolationOffset)];
                    time = lastNote.time - firstNote.time;
                }
            }

            // Rates after everything.
            if (modRate)
            {
                time /= options.songRate;
            }

            return time + 1; // 1 seconds for fade out.
        }
    }
}
