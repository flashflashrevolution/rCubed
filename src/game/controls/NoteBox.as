package game.controls
{
    import classes.GameNote;
    import classes.GameReceptor;
    import classes.Noteskins;
    import classes.chart.Note;
    import classes.chart.Song;
    import classes.ui.BoxButton;
    import classes.ui.BoxSlider;
    import classes.ui.Text;
    import com.flashfla.utils.GameNotePool;
    import flash.display.DisplayObjectContainer;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.utils.getTimer;
    import game.GameOptions;

    public class NoteBox extends GameControl
    {
        public static const VERTEX_X:Number = 0;
        public static const VERTEX_Y:Number = 1;

        public static const P_CENTER:int = 0;
        public static const P_TOP:int = 1 << 0;
        public static const P_LEFT:int = 1 << 1;
        public static const P_RIGHT:int = 1 << 2;
        public static const P_BOTTOM:int = 1 << 3;

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _noteskins:Noteskins = Noteskins.instance;
        public var options:GameOptions;
        public var song:Song;

        public var scrollSpeed:Number;
        public var readahead:Number;
        public var totalNotes:int;
        public var noteCount:int;
        public var notePool:Object;
        public var notes:Vector.<GameNote>;

        public var leftReceptor:MovieClip;
        public var downReceptor:MovieClip;
        public var upReceptor:MovieClip;
        public var rightReceptor:MovieClip;
        public var receptorArray:Array;
        public var receptorTable:Object = {};

        public var positionOffsetMax:Object;
        public var receptorAlpha:Number;

        public var recp_colors:Vector.<Number>;
        public var recp_colors_enabled:Vector.<Boolean>;

        public var anchorPoints:Vector.<Point>;

        public function NoteBox(song:Song, options:GameOptions, parent:DisplayObjectContainer)
        {
            if (parent)
                parent.addChild(this);

            this.options = options;
            this.song = song;

            // Create Object Pools
            if (_noteskins.data[options.noteskin] == null)
            {
                options.noteskin = 1;
            }

            notePool = {"L": {}, "D": {}, "U": {}, "R": {}};

            var i:int = 0;
            var preLoadCount:int = 8;
            for each (var direction:String in options.noteDirections)
            {
                for each (var color:String in options.noteColors)
                {
                    var pool:GameNotePool = new GameNotePool();

                    for (i = 0; i < preLoadCount; i++)
                    {
                        var gameNote:GameNote = pool.addObject(new GameNote(0, direction, color, 1 * 1000, 0, options.noteskin));
                        gameNote.visible = false;
                        pool.unmarkObject(gameNote);
                        addChild(gameNote);
                    }

                    notePool[direction][color] = pool;
                }
            }

            // Setup Receptors
            leftReceptor = _noteskins.getReceptor(options.noteskin, "L");
            downReceptor = _noteskins.getReceptor(options.noteskin, "D");
            upReceptor = _noteskins.getReceptor(options.noteskin, "U");
            rightReceptor = _noteskins.getReceptor(options.noteskin, "R");

            if (leftReceptor is GameReceptor)
            {
                (leftReceptor as GameReceptor).animationSpeed = options.receptorSpeed;
                (downReceptor as GameReceptor).animationSpeed = options.receptorSpeed;
                (upReceptor as GameReceptor).animationSpeed = options.receptorSpeed;
                (rightReceptor as GameReceptor).animationSpeed = options.receptorSpeed;
            }

            addChildAt(leftReceptor, 0);
            addChildAt(downReceptor, 0);
            addChildAt(upReceptor, 0);
            addChildAt(rightReceptor, 0);

            // Other Stuff
            scrollSpeed = options.scrollSpeed;
            readahead = (Main.GAME_WIDTH / 300 * 1000 / scrollSpeed);
            receptorAlpha = 1.0;
            notes = new <GameNote>[];
            noteCount = 0;
            totalNotes = song.totalNotes;

            // Copy Receptor Colors
            recp_colors = new Vector.<Number>(options.receptorColors.length, true);
            for (i = 0; i < options.receptorColors.length; i++)
            {
                recp_colors[i] = options.receptorColors[i];
            }

            // Copy Enabled Colors
            recp_colors_enabled = new Vector.<Boolean>(options.enableReceptorColors.length, true);
            for (i = 0; i < options.enableReceptorColors.length; i++)
            {
                recp_colors_enabled[i] = options.enableReceptorColors[i];
            }

            // Anchor Points
            anchorPoints = new <Point>[new Point(0, 0), // P_CENTER,
                new Point(0, -150), //P_TOP
                new Point(-300, 0), //P_LEFT
                new Point(-300, -150), //P_TOP|P_LEFT
                new Point(300, 0), //P_RIGHT
                new Point(300, -150), //P_TOP|P_RIGHT
                new Point(0, 0), //P_LEFT|P_RIGHT
                new Point(0, -150), //P_TOP|P_LEFT|P_RIGHT
                new Point(0, 150), //P_BOTTOM
                new Point(0, 0), //P_TOP|P_BOTTOM
                new Point(-300, 150), //P_LEFT|P_BOTTOM
                new Point(-300, 0), //P_TOP|P_LEFT|P_BOTTOM
                new Point(300, 150), //P_RIGHT|P_BOTTOM
                new Point(300, 0), //P_TOP|P_RIGHT|P_BOTTOM
                new Point(0, 150), //P_LEFT|P_RIGHT|P_BOTTOM
                new Point(0, 0) //P_TOP|P_LEFT|P_RIGHT|P_BOTTOM
                ];
        }

        public function spawnArrow(note:Note, current_position:int = 0):GameNote
        {
            var direction:String = note.direction;
            var color:String = options.getNewNoteColor(note.color);

            var spawnPoolRef:GameNotePool = notePool[direction][color];
            var gameNote:GameNote;

            gameNote = spawnPoolRef.getObject();
            if (gameNote != null)
            {
                gameNote.ID = noteCount++;
                gameNote.DIR = direction;
                gameNote.POSITION = (note.time + 0.5 / 30) * 1000;
                gameNote.FRAME = note.frame;
                gameNote.alpha = 1;
            }
            else
            {
                gameNote = spawnPoolRef.addObject(new GameNote(noteCount++, direction, color, (note.time + 0.5 / 30) * 1000, note.frame, options.noteskin));
                addChild(gameNote);
            }

            gameNote.SPAWN_PROGRESS = gameNote.POSITION - 1000; // readahead;
            gameNote.rotation = getReceptor(direction).rotation;

            if (options.noteScale != 1.0)
            {
                gameNote.scaleX = gameNote.scaleY = options.noteScale;
            }
            else if (options.modEnabled("mini") && !options.modEnabled("mini_resize") && options.noteScale == 1.0)
            {
                gameNote.scaleX = gameNote.scaleY = 0.75;
            }
            else
            {
                gameNote.scaleX = gameNote.scaleY = 1;
            }

            if (options.modEnabled("note_dark"))
            {
                gameNote.alpha = 0.2;
            }

            gameNote.visible = true;
            notes.push(gameNote);

            updateNotePosition(gameNote, current_position);

            return gameNote;
        }

        public function getReceptor(dir:String):MovieClip
        {
            switch (dir)
            {
                case "L":
                    return leftReceptor;
                case "D":
                    return downReceptor;
                case "U":
                    return upReceptor;
                case "R":
                    return rightReceptor;
            }
            return null;
        }

        public function receptorFeedback(dir:String, score:int):void
        {
            if (!options.displayReceptorAnimations)
                return;

            var receptor:MovieClip = getReceptor(dir);
            var isCustom:Boolean = receptor is GameReceptor;
            var f:int = 2;
            var c:uint = 0;
            var e:Boolean = false;

            switch (score)
            {
                case 100:
                    f = 2;
                    c = recp_colors[0];
                    e = recp_colors_enabled[0];
                    break;
                case 50:
                    f = 2;
                    c = recp_colors[1];
                    e = recp_colors_enabled[1];
                    break;
                case 25:
                    f = 7;
                    c = recp_colors[2];
                    e = recp_colors_enabled[2];
                    break;
                case 5:
                    f = 12;
                    c = recp_colors[3];
                    e = recp_colors_enabled[3];
                    break;
                case -5:
                    f = 12;
                    c = recp_colors[4];
                    e = recp_colors_enabled[4];
                    break;
                case -10:
                    f = 12;
                    c = recp_colors[5];
                    e = recp_colors_enabled[5];

                    if (!isCustom)
                    {
                        e = false;
                    }
                    break;
                default:
                    return;
            }

            if (!e)
                return;

            if (isCustom)
                (receptor as GameReceptor).playAnimation(c);

            else
                receptor.gotoAndPlay(f);
        }

        public function get nextNote():Note
        {
            return noteCount < totalNotes ? song.getNote(noteCount) : null;
        }

        public function spawnNextNote(current_position:int = 0):GameNote
        {
            if (nextNote)
            {
                return spawnArrow(nextNote, current_position);
            }

            return null;
        }

        public function update(position:int):void
        {
            var nextRef:Note = nextNote;
            while (nextRef && (nextRef.time + 0.5 / 30) * 1000 - position < readahead)
            {
                spawnArrow(nextRef, position);
                nextRef = nextNote;
            }

            if (options.modEnabled("wave"))
            {
                var waveOffset:int = 0;
                for each (var receptor:MovieClip in receptorArray)
                {
                    if (receptor.VERTEX == VERTEX_X)
                    {
                        receptor.y = receptor.ORIG_Y + (Math.sin((getTimer() + waveOffset) / 1000) * 35);
                    }
                    else if (receptor.VERTEX == VERTEX_Y)
                    {
                        receptor.x = receptor.ORIG_X + (Math.sin((getTimer() + waveOffset) / 1000) * 35);
                    }
                    waveOffset += 165;
                }
            }

            if (options.modEnabled("drunk"))
            {
                var drunkOffset:int = 0;
                for each (receptor in receptorArray)
                {
                    receptor.rotation = receptor.ORIG_ROT + (Math.sin((getTimer() + drunkOffset) / 1387) * 25);
                    drunkOffset += 165;
                }
            }

            if (options.modEnabled("dizzy"))
            {
                for each (receptor in receptorArray)
                {
                    receptor.rotation += 12;
                }
            }

            if (options.modEnabled("hide"))
            {
                leftReceptor.alpha = (leftReceptor.currentFrame == 1) ? 0.0 : receptorAlpha;
                downReceptor.alpha = (downReceptor.currentFrame == 1) ? 0.0 : receptorAlpha;
                upReceptor.alpha = (upReceptor.currentFrame == 1) ? 0.0 : receptorAlpha;
                rightReceptor.alpha = (rightReceptor.currentFrame == 1) ? 0.0 : receptorAlpha;
            }

            for each (var note:GameNote in notes)
            {
                updateNotePosition(note, position);
            }
        }

        public var updateReceptorRef:MovieClip;
        public var updateOffsetRef:Number;
        public var updateBaseOffsetRef:Number;

        public function updateNotePosition(note:GameNote, position:int):void
        {
            updateReceptorRef = getReceptor(note.DIR);
            updateOffsetRef = (note.POSITION - position) / 1000 * 300 * scrollSpeed;
            updateBaseOffsetRef = (position - note.SPAWN_PROGRESS) / (note.POSITION - note.SPAWN_PROGRESS);

            if (updateReceptorRef.VERTEX == VERTEX_X)
            {
                note.x = updateReceptorRef.x - updateOffsetRef * updateReceptorRef.DIRECTION;
                note.y = updateReceptorRef.y;
            }
            else if (updateReceptorRef.VERTEX == VERTEX_Y)
            {
                note.y = updateReceptorRef.y - updateOffsetRef * updateReceptorRef.DIRECTION;
                note.x = updateReceptorRef.x;
            }

            // Position Mods
            if (options.modEnabled("tornado"))
            {
                var tornadoOffset:Number = Math.sin(updateBaseOffsetRef * Math.PI) * (options.receptorSpacing / 2);
                if (updateReceptorRef.VERTEX == VERTEX_X)
                {
                    note.y += tornadoOffset;
                }
                if (updateReceptorRef.VERTEX == VERTEX_Y)
                {
                    note.x += tornadoOffset;
                }
            }

            // Rotation Mods
            if (options.modEnabled("rotating"))
            {
                note.rotation = (updateBaseOffsetRef * 6 * 90) + updateReceptorRef.rotation;
            }

            if (options.modEnabled("dizzy"))
            {
                note.rotation += 18;
            }

            // Alpha Mods
            // switched hidden and sudden, mods were reversed!
            if (options.modEnabled("hidden"))
            {
                note.alpha = 1 - updateBaseOffsetRef;
            }

            if (options.modEnabled("sudden"))
            {
                note.alpha = updateBaseOffsetRef;
            }

            if (options.modEnabled("blink"))
            {
                var blink_offset:Number = (1 - updateBaseOffsetRef) % 0.4;
                var blink_hidden:Boolean = (blink_offset > 0.2);
                note.alpha = (blink_hidden ? 0 : (note.alpha != 1 && note.alpha != 0 ? note.alpha : 1));
            }

            // Scale Mods
            if (options.noteScale == 1 && options.modEnabled("mini_resize") && !options.modEnabled("mini"))
            {
                note.scaleX = note.scaleY = 1 - (updateBaseOffsetRef * 0.65);
            }
        }

        public var removeNoteIndex:int = 0;
        public var removeNoteRef:GameNote;

        public function removeNote(id:int):void
        {
            const len:Number = notes.length;
            for (removeNoteIndex = 0; removeNoteIndex < len; removeNoteIndex++)
            {
                removeNoteRef = notes[removeNoteIndex];
                if (removeNoteRef.ID == id)
                {
                    notePool[removeNoteRef.DIR][removeNoteRef.COLOR].unmarkObject(removeNoteRef);
                    removeNoteRef.visible = false;
                    notes.splice(removeNoteIndex, 1);
                    break;
                }
            }
        }

        public function reset():void
        {
            for each (var note:GameNote in notes)
            {
                notePool[note.DIR][note.COLOR].unmarkObject(note);
                note.visible = false;
            }

            notes.length = 0;
            noteCount = 0;
        }

        public function resetNoteCount(value:int):void
        {
            noteCount = value;
        }

        public function position():void
        {
            var anchor:Point;
            var data:Object = _noteskins.getInfo(options.noteskin);
            var rotation:Number = data.rotation;
            var gap:int = options.receptorSpacing;
            var noteScale:Number = options.noteScale;

            // User-defined note scale
            if (noteScale != 1)
            {
                if (noteScale < 0.1)
                    noteScale = 0.1; // min
                else if (noteScale > 3.0)
                    noteScale = 3.0; // max
                gap *= noteScale
            }
            else if (options.modEnabled("mini") && !options.modEnabled("mini_resize"))
            {
                gap *= 0.75;
            }

            switch (options.scrollDirection)
            {
                case "down":
                    anchor = anchorPoints[P_BOTTOM];

                    leftReceptor.x = gap * -1.5;
                    leftReceptor.y = anchor.y;
                    leftReceptor.rotation = rotation;
                    leftReceptor.VERTEX = VERTEX_Y;
                    leftReceptor.DIRECTION = 1;

                    downReceptor.x = gap * -0.5;
                    downReceptor.y = anchor.y;
                    downReceptor.rotation = 0;
                    downReceptor.VERTEX = VERTEX_Y;
                    downReceptor.DIRECTION = 1;

                    upReceptor.x = gap * 0.5;
                    upReceptor.y = anchor.y;
                    upReceptor.rotation = rotation * 2;
                    upReceptor.VERTEX = VERTEX_Y;
                    upReceptor.DIRECTION = 1;

                    rightReceptor.x = gap * 1.5;
                    rightReceptor.y = anchor.y;
                    rightReceptor.rotation = rotation * -1;
                    rightReceptor.VERTEX = VERTEX_Y;
                    rightReceptor.DIRECTION = 1;

                    receptorArray = [leftReceptor, downReceptor, upReceptor, rightReceptor];
                    positionOffsetMax = {"min_x": -150, "max_x": 150, "min_y": -150, "max_y": 50};
                    break;

                case "right":
                    anchor = anchorPoints[P_RIGHT];

                    leftReceptor.x = anchor.x;
                    leftReceptor.y = gap * 1.5;
                    leftReceptor.rotation = rotation;
                    leftReceptor.VERTEX = VERTEX_X;
                    leftReceptor.DIRECTION = 1;

                    downReceptor.x = anchor.x;
                    downReceptor.y = gap * 0.5;
                    downReceptor.rotation = 0;
                    downReceptor.VERTEX = VERTEX_X;
                    downReceptor.DIRECTION = 1;

                    upReceptor.x = anchor.x;
                    upReceptor.y = gap * -0.5;
                    upReceptor.rotation = rotation * 2;
                    upReceptor.VERTEX = VERTEX_X;
                    upReceptor.DIRECTION = 1;

                    rightReceptor.x = anchor.x;
                    rightReceptor.y = gap * -1.5;
                    rightReceptor.rotation = rotation * -1;
                    rightReceptor.VERTEX = VERTEX_X;
                    rightReceptor.DIRECTION = 1;

                    receptorArray = [upReceptor, rightReceptor, leftReceptor, downReceptor];
                    positionOffsetMax = {"min_x": -150, "max_x": 50, "min_y": -120, "max_y": 120};
                    break;

                case "left":
                    anchor = anchorPoints[P_LEFT];

                    leftReceptor.x = anchor.x;
                    leftReceptor.y = gap * 1.5;
                    leftReceptor.rotation = rotation;
                    leftReceptor.VERTEX = VERTEX_X;
                    leftReceptor.DIRECTION = -1;

                    downReceptor.x = anchor.x;
                    downReceptor.y = gap * 0.5;
                    downReceptor.rotation = 0;
                    downReceptor.VERTEX = VERTEX_X;
                    downReceptor.DIRECTION = -1;

                    upReceptor.x = anchor.x;
                    upReceptor.y = gap * -0.5;
                    upReceptor.rotation = rotation * 2;
                    upReceptor.VERTEX = VERTEX_X;
                    upReceptor.DIRECTION = -1;

                    rightReceptor.x = anchor.x;
                    rightReceptor.y = gap * -1.5;
                    rightReceptor.rotation = rotation * -1;
                    rightReceptor.VERTEX = VERTEX_X;
                    rightReceptor.DIRECTION = -1;

                    receptorArray = [upReceptor, rightReceptor, leftReceptor, downReceptor];
                    positionOffsetMax = {"min_x": -50, "max_x": 150, "min_y": -120, "max_y": 120};
                    break;

                case "split":
                    anchor = anchorPoints[P_BOTTOM];

                    downReceptor.x = gap * -0.5;
                    downReceptor.y = anchor.y;
                    downReceptor.rotation = 0;
                    downReceptor.VERTEX = VERTEX_Y;
                    downReceptor.DIRECTION = 1;

                    upReceptor.x = gap * 0.5;
                    upReceptor.y = anchor.y;
                    upReceptor.rotation = rotation * 2;
                    upReceptor.VERTEX = VERTEX_Y;
                    upReceptor.DIRECTION = 1;

                    anchor = anchorPoints[P_TOP];

                    leftReceptor.x = gap * -1.5;
                    leftReceptor.y = anchor.y;
                    leftReceptor.rotation = rotation;
                    leftReceptor.VERTEX = VERTEX_Y;
                    leftReceptor.DIRECTION = -1;

                    rightReceptor.x = gap * 1.5;
                    rightReceptor.y = anchor.y;
                    rightReceptor.rotation = rotation * -1;
                    rightReceptor.VERTEX = VERTEX_Y;
                    rightReceptor.DIRECTION = -1;

                    receptorArray = [leftReceptor, downReceptor, upReceptor, rightReceptor];
                    positionOffsetMax = {"min_x": -150, "max_x": 150, "min_y": -50, "max_y": 50};
                    break;

                case "split_down":
                    anchor = anchorPoints[P_TOP];

                    downReceptor.x = gap * -0.5;
                    downReceptor.y = anchor.y;
                    downReceptor.rotation = 0;
                    downReceptor.VERTEX = VERTEX_Y;
                    downReceptor.DIRECTION = -1;

                    upReceptor.x = gap * 0.5;
                    upReceptor.y = anchor.y;
                    upReceptor.rotation = rotation * 2;
                    upReceptor.VERTEX = VERTEX_Y;
                    upReceptor.DIRECTION = -1;

                    anchor = anchorPoints[P_BOTTOM];

                    leftReceptor.x = gap * -1.5;
                    leftReceptor.y = anchor.y;
                    leftReceptor.rotation = rotation;
                    leftReceptor.VERTEX = VERTEX_Y;
                    leftReceptor.DIRECTION = 1;

                    rightReceptor.x = gap * 1.5;
                    rightReceptor.y = anchor.y;
                    rightReceptor.rotation = rotation * -1;
                    rightReceptor.VERTEX = VERTEX_Y;
                    rightReceptor.DIRECTION = 1;

                    receptorArray = [leftReceptor, downReceptor, upReceptor, rightReceptor];
                    positionOffsetMax = {"min_x": -150, "max_x": 150, "min_y": -50, "max_y": 50};
                    break;

                case "plus":
                    anchor = anchorPoints[P_CENTER];

                    leftReceptor.x = gap * -0.5;
                    leftReceptor.y = anchor.y;
                    leftReceptor.rotation = rotation;
                    leftReceptor.VERTEX = VERTEX_X;
                    leftReceptor.DIRECTION = 1;

                    downReceptor.x = anchor.x;
                    downReceptor.y = gap * 0.5;
                    downReceptor.rotation = 0;
                    downReceptor.VERTEX = VERTEX_Y;
                    downReceptor.DIRECTION = -1;

                    upReceptor.x = anchor.x;
                    upReceptor.y = gap * -0.5;
                    upReceptor.rotation = rotation * 2;
                    upReceptor.VERTEX = VERTEX_Y;
                    upReceptor.DIRECTION = 1;

                    rightReceptor.x = gap * 0.5;
                    rightReceptor.y = anchor.y;
                    rightReceptor.rotation = rotation * -1;
                    rightReceptor.VERTEX = VERTEX_X;
                    rightReceptor.DIRECTION = -1;

                    receptorArray = [upReceptor, rightReceptor, downReceptor, leftReceptor];
                    positionOffsetMax = {"min_x": -150, "max_x": 150, "min_y": -150, "max_y": 150};
                    break;

                default:
                    anchor = anchorPoints[P_TOP];

                    leftReceptor.x = gap * -1.5;
                    leftReceptor.y = anchor.y;
                    leftReceptor.rotation = rotation;
                    leftReceptor.VERTEX = VERTEX_Y;
                    leftReceptor.DIRECTION = -1;

                    downReceptor.x = gap * -0.5;
                    downReceptor.y = anchor.y;
                    downReceptor.rotation = 0;
                    downReceptor.VERTEX = VERTEX_Y;
                    downReceptor.DIRECTION = -1;

                    upReceptor.x = gap * 0.5;
                    upReceptor.y = anchor.y;
                    upReceptor.rotation = rotation * 2;
                    upReceptor.VERTEX = VERTEX_Y;
                    upReceptor.DIRECTION = -1;

                    rightReceptor.x = gap * 1.5;
                    rightReceptor.y = anchor.y;
                    rightReceptor.rotation = rotation * -1;
                    rightReceptor.VERTEX = VERTEX_Y;
                    rightReceptor.DIRECTION = -1;

                    receptorArray = [leftReceptor, downReceptor, upReceptor, rightReceptor];
                    positionOffsetMax = {"min_x": -150, "max_x": 150, "min_y": -50, "max_y": 150};
                    break;
            }

            for each (var item:MovieClip in receptorArray)
            {
                item.ORIG_X = item.x;
                item.ORIG_Y = item.y;
                item.ORIG_ROT = item.rotation;
            }

            if (options.modEnabled("rotate_cw"))
            {
                leftReceptor.rotation += 90;
                downReceptor.rotation += 90;
                upReceptor.rotation += 90;
                rightReceptor.rotation += 90;
            }
            if (options.modEnabled("rotate_ccw"))
            {
                leftReceptor.rotation -= 90;
                downReceptor.rotation -= 90;
                upReceptor.rotation -= 90;
                rightReceptor.rotation -= 90;
            }

            if (options.noteScale != 1.0)
                downReceptor.scaleX = downReceptor.scaleY = leftReceptor.scaleX = leftReceptor.scaleY = upReceptor.scaleX = upReceptor.scaleY = rightReceptor.scaleX = rightReceptor.scaleY = options.noteScale;

            if (options.modEnabled("mini") && !options.modEnabled("mini_resize") && options.noteScale == 1.0)
                downReceptor.scaleX = downReceptor.scaleY = leftReceptor.scaleX = leftReceptor.scaleY = upReceptor.scaleX = upReceptor.scaleY = rightReceptor.scaleX = rightReceptor.scaleY = 0.75;

            if (options.modEnabled("mini_resize") && !options.modEnabled("mini") && options.noteScale == 1.0)
                downReceptor.scaleX = downReceptor.scaleY = leftReceptor.scaleX = leftReceptor.scaleY = upReceptor.scaleX = upReceptor.scaleY = rightReceptor.scaleX = rightReceptor.scaleY = 0.5;

            if (options.modEnabled("dark"))
                receptorAlpha = 0.3;

            leftReceptor.alpha = downReceptor.alpha = upReceptor.alpha = rightReceptor.alpha = receptorAlpha;
        }

        override public function get id():String
        {
            return GameLayoutManager.LAYOUT_RECEPTORS;
        }

        override public function get editorFlags():int
        {
            return FLAG_POSITION | FLAG_ROTATE | FLAG_SCALE;
        }

        override public function getEditorInterface():GameControlEditor
        {
            var self:NoteBox = this;

            var out:GameControlEditor = super.getEditorInterface();

            new Text(out, 10, out.cy, _lang.string("editor_component_rotation_x"));
            var sliderRotate:BoxSlider = new BoxSlider(out, 10 + 3, out.cy + 20, editorWidth - 56, 10, e_changeHandler);
            sliderRotate.minValue = -180;
            sliderRotate.maxValue = 180;

            var sliderRotateDisplay:Text = new Text(out, 10, out.cy, "0°");
            sliderRotateDisplay.setAreaParams(editorWidth - 52, 22, "right");
            var sliderRotateReset:BoxButton = new BoxButton(out, editorWidth - 36, out.cy + 5, 22, 22, "R", 12, e_changeHandler);

            sliderRotate.slideValue = this.rotationX;
            sliderRotateDisplay.text = Math.round(sliderRotate.slideValue) + "°";

            out.cy += 42;

            function e_changeHandler(e:Event):void
            {
                if (e.target == sliderRotate)
                {
                    var rotateSnap:int = Math.round(sliderRotate.slideValue / 5) * 5;
                    sliderRotateDisplay.text = Math.round(rotateSnap) + "°";
                    editorLayout["rotationX"] = Math.round(rotateSnap);
                    self.rotationX = editorLayout["rotationX"];
                }
                else if (e.target == sliderRotateReset)
                {
                    sliderRotate.slideValue = 0;
                    sliderRotateDisplay.text = Math.round(sliderRotate.slideValue) + "°";
                    editorLayout["rotationX"] = 0;
                    self.rotationX = editorLayout["rotationX"];
                }
            }

            return out;
        }
    }
}
