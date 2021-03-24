package classes.replay
{
    import arc.ArcGlobals;
    import classes.User;
    import com.flashfla.utils.StringUtil;
    import flash.utils.ByteArray;
    import game.GameOptions;

    /**
     * A Class needed to pack and unpack a binary based R3 replay.
     *
     * The format of the current plays (as of version 1)
     *
     * [int] Total notes.
     *
     * for each note:
     *   [byte] ms time from song note time.
     *      The default judge window allows the number to be within the range of -128 - 127 at all times.
     *      A value of 0x7F is use to signify the note wasn't hit and should act as a miss.
     *
     * [int] Total Boos.
     *
     * for each boo:
     *   [byte] boo frame header.
     *      Consist of 8 bits:
     * 	       - 0: Left
     * 	       - 1: Down
     * 	       - 2: Up
     * 	       - 3: Right
     * 	       - 4: Extended Frame Size - Only set when more then 4 directions are required for this frame header. Such as 6 / 8 key files.
     * 	       - 5: Written Byte  - The time is <= 0x7F
     * 	       - 6: Written Short - The time is <= 0x7FFF
     * 	       - 7: Written Int   - The time is <= 0x7FFFFFFF
     *
     * 	[byte] [optional] direction frame bits
     *      This only exist if the "Extended Frame Size" bit is set in the header.
     *      Consist of 8 bits:
     * 	       - 0: P1 Up Left
     * 	       - 1: P1 Down Right
     * 	       - 2: P2 Left
     * 	       - 3: P2 Down
     * 	       - 4: P2 Up
     * 	       - 5: P2 Right
     * 	       - 6: P2 Up Left
     * 	       - 7: P2 Down Right
     *
     * 	[byte/short/int] boo time.
     * 	    The amount of ms since the last boo frame.
     * 	    The size is based on the bit from the header.
     */
    public class ReplayPack
    {
        // 00000001 
        public static const BIT_P1_LEFT:int = (1 << 0);
        // 00000010 
        public static const BIT_P1_DOWN:int = (1 << 1);
        // 00000100 
        public static const BIT_P1_UP:int = (1 << 2);
        // 00001000 
        public static const BIT_P1_RIGHT:int = (1 << 3);
        // 00000001 
        public static const BIT_P1_KEY_5:int = (1 << 0);
        // 00000010 
        public static const BIT_P1_KEY_6:int = (1 << 1);

        // 00000100 
        public static const BIT_P2_LEFT:int = (1 << 2);
        // 00001000 
        public static const BIT_P2_DOWN:int = (1 << 3);
        // 00010000 
        public static const BIT_P2_UP:int = (1 << 4);
        // 00100000 
        public static const BIT_P2_RIGHT:int = (1 << 5);
        // 01000000 
        public static const BIT_P2_KEY_5:int = (1 << 6);
        // 10000000 
        public static const BIT_P2_KEY_6:int = (1 << 7);

        // 00010000 
        public static const BIT_FRAME_EXTEND:int = (1 << 4);
        // 00100000 
        public static const BIT_PACK_BYTE:int = (1 << 5);
        // 01000000 
        public static const BIT_PACK_SHORT:int = (1 << 6);
        // 10000000 
        public static const BIT_PACK_INT:int = (1 << 7);

        static public const MAGIC:String = "FBRF";
        static public const MAJOR_VER:uint = 1;
        static public const MINOR_VER:uint = 1;

        public static function pack(binNotes:Array, binBoos:Array):ByteArray
        {
            // Generate Bin Replay Format
            var binReplay:ByteArray = new ByteArray();

            // Write Placeholder size
            binReplay.writeUnsignedInt(0);

            // Write Note Judements
            binReplay.writeInt(binNotes.length);
            for (var nx:int = 0; nx < binNotes.length; nx++)
            {
                if (binNotes[nx] == null)
                    binReplay.writeByte(0x7F);
                else
                    binReplay.writeByte(binNotes[nx]);
            }

            // Write Boos
            var booCount:int = 0;
            var booPosition:uint = binReplay.position;
            binBoos.sortOn("t", Array.NUMERIC);
            binReplay.writeInt(0);

            var LAST_TIME:int = 0;

            for (nx = 0; nx < binBoos.length; nx++)
            {
                var FRAME_HEADER:int = 0;
                var EXTENDED_HEADER:int = 0;

                var CUR_TIME:uint = binBoos[nx]["t"];
                var DIR_BIT:int = getDirectionBit(binBoos[nx]["d"]);
                var DIR_CHECK:Boolean = isExtendedDirection(binBoos[nx]["d"]);

                if (CUR_TIME < 0)
                    CUR_TIME = 0; // Should Never Happen!

                var TIME_DIFF:uint = CUR_TIME - LAST_TIME;

                // Set Direction Bit
                if (DIR_CHECK)
                {
                    FRAME_HEADER |= BIT_FRAME_EXTEND;
                    EXTENDED_HEADER |= DIR_BIT;
                }
                else
                    FRAME_HEADER |= DIR_BIT;

                // Find Matching Time Boos, set bit if not set.
                while (nx < binBoos.length - 1)
                {
                    if (binBoos[nx + 1]["t"] == CUR_TIME)
                    {
                        var TEMP_DIR_BIT:int = getDirectionBit(binBoos[nx + 1]["d"]);
                        var TEMP_DIR_CHECK:Boolean = isExtendedDirection(binBoos[nx + 1]["d"]);

                        // Check time and if the frame direction bit isn't set.
                        if (TEMP_DIR_CHECK && (TEMP_DIR_BIT & EXTENDED_HEADER) == 0)
                        {
                            FRAME_HEADER |= BIT_FRAME_EXTEND;
                            EXTENDED_HEADER |= TEMP_DIR_BIT;
                        }
                        if (!TEMP_DIR_CHECK && (TEMP_DIR_BIT & FRAME_HEADER) == 0)
                            FRAME_HEADER |= TEMP_DIR_BIT;
                        else
                            break;
                        nx++;
                    }
                    else
                        break;
                }

                // Set Pack Size
                if (TIME_DIFF > 0)
                {
                    if (TIME_DIFF <= 0x7F)
                        FRAME_HEADER |= BIT_PACK_BYTE;
                    else if (TIME_DIFF <= 0x7FFF)
                        FRAME_HEADER |= BIT_PACK_SHORT;
                    else
                        FRAME_HEADER |= BIT_PACK_INT;
                }

                // Write Boo Header
                binReplay.writeByte(FRAME_HEADER);
                if ((FRAME_HEADER & BIT_FRAME_EXTEND) != 0)
                {
                    binReplay.writeByte(EXTENDED_HEADER);
                }

                // Write Boo Time
                if (TIME_DIFF > 0)
                {
                    if (TIME_DIFF <= 0x7F)
                        binReplay.writeByte(TIME_DIFF);
                    else if (TIME_DIFF <= 0x7FFF)
                        binReplay.writeShort(TIME_DIFF);
                    else
                        binReplay.writeInt(TIME_DIFF);
                }
                LAST_TIME = CUR_TIME;
                booCount++;
            }

            // Update Boo Count
            binReplay.position = booPosition;
            binReplay.writeInt(booCount);

            // Write Length
            binReplay.position = 0;
            binReplay.writeUnsignedInt(binReplay.length - 4);

            return binReplay;
        }

        public static function unpack(ba:ByteArray, judgeOffset:int = 0):Object
        {
            var note_array:Array = [];
            var boo_array:Array = [];

            try
            {
                // Nothing can possibly exist < 2 in length.
                if (ba.length < 2)
                    return null;

                ba.position = 0;

                // Get Notes
                var total_notes:int = ba.readInt();
                for (var n:int = 0; n < total_notes; n++)
                {
                    if (ba[ba.position] == 0x7F)
                    {
                        note_array.push(null);
                        ba.readByte();
                    }
                    else
                        note_array.push(ba.readByte() + judgeOffset);
                }

                // Get Boos
                var boo_time:uint = 0;
                var total_boos:int = ba.readInt();
                for (n = 0; n < total_boos; n++)
                {
                    var header:int = ba.readByte();
                    var ext:int = 0;

                    // Check Extended Header
                    if ((header & BIT_FRAME_EXTEND) != 0)
                        ext = ba.readByte();

                    // Get Boo Time
                    var this_boo:int = 0;
                    if ((header & BIT_PACK_BYTE) != 0)
                        boo_time += ba.readUnsignedByte();
                    else if ((header & BIT_PACK_SHORT) != 0)
                        boo_time += ba.readUnsignedShort();
                    else if ((header & BIT_PACK_INT) != 0)
                        boo_time += ba.readUnsignedInt();

                    // Fill Boo Array
                    if ((header & BIT_P1_LEFT) != 0)
                        boo_array.push({"t": boo_time, "d": "L"});
                    if ((header & BIT_P1_DOWN) != 0)
                        boo_array.push({"t": boo_time, "d": "D"});
                    if ((header & BIT_P1_UP) != 0)
                        boo_array.push({"t": boo_time, "d": "U"});
                    if ((header & BIT_P1_RIGHT) != 0)
                        boo_array.push({"t": boo_time, "d": "R"});

                    if ((header & BIT_FRAME_EXTEND) != 0)
                    { // TODO: Actually finish the directions for these, we don't have a set standard yet.
                        if ((ext & BIT_P1_KEY_5) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                        if ((ext & BIT_P1_KEY_6) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                        if ((ext & BIT_P2_LEFT) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                        if ((ext & BIT_P2_DOWN) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                        if ((ext & BIT_P2_UP) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                        if ((ext & BIT_P2_RIGHT) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                        if ((ext & BIT_P2_KEY_5) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                        if ((ext & BIT_P2_KEY_6) != 0)
                            boo_array.push({"t": boo_time, "d": "X"});
                    }
                }
            }
            catch (e:Error)
            {
                return {"error": true, "note": note_array, "boo": boo_array};
            }

            return {"note": note_array, "boo": boo_array};
        }

        /**
         * Gets the applicible bit based on the direction provided.
         * @param	dir Direction to get bit for.
         * @return The direction bit.
         */
        public static function getDirectionBit(dir:String):int
        {
            if (dir == 'L')
                return BIT_P1_LEFT;
            if (dir == 'D')
                return BIT_P1_DOWN;
            if (dir == 'U')
                return BIT_P1_UP;
            if (dir == 'R')
                return BIT_P1_RIGHT;
            return 0;
        }

        public static function isExtendedDirection(dir:String):Boolean
        {
            return dir != 'L' && dir != 'D' && dir != 'U' && dir != 'R';
        }

        public static function printBits(num:int):String
        {
            return StringUtil.pad(num.toString(2), 8, "0");
        }

        static public function checksum(bin:ByteArray, hasCheck:Boolean = false):uint
        {
            var ss:uint = bin.position;
            var cc:uint = 0xc0ffee;
            var aa:int = 0;
            var ll:int = Math.floor((bin.length - (hasCheck ? 4 : 0)) / 4);
            bin.position = 0;
            while (aa < ll)
            {
                cc ^= bin.readInt();
                aa++;
            }
            bin.position = ss;
            return cc;
        }

        static public function writeSiteReplay(binReplayNotes:Array, binReplayBoos:Array):ByteArray
        {
            // No replay to make.
            if (binReplayNotes.length == 0 && binReplayBoos.length == 0)
                return null;

            var binReplay:ByteArray = new ByteArray();
            binReplay.writeUTFBytes(MAGIC);
            binReplay.writeByte(MAJOR_VER); // Major Version
            binReplay.writeByte(MINOR_VER); // Minor Version
            binReplay.writeByte(0); // Header Flag
            binReplay.writeBytes(pack(binReplayNotes, binReplayBoos)); // Replay Pack
            binReplay.writeUnsignedInt(checksum(binReplay));
            return binReplay;
        }

        static public function writeReplay(activeUser:User, options:GameOptions, judgements:String, binReplayNotes:Array, binReplayBoos:Array):ByteArray
        {
            // No replay to make.
            if (binReplayNotes.length == 0 && binReplayBoos.length == 0)
                return null;

            // No Custom Judge Windows, not supported.
            if (options.judgeWindow)
                return null;

            // Get Alt engine Settings
            var settings:Object = options.settingsEncode();
            if (options.song.songInfo.engine)
                settings.arc_engine = ArcGlobals.instance.legacyEncode(options.song.songInfo);

            var timestamp:Number = Math.floor(new Date().getTime() / 1000);
            var settingsEncode:String = JSON.stringify(settings);
            var binReplay:ByteArray = new ByteArray();
            binReplay.writeUTFBytes(MAGIC);
            binReplay.writeByte(MAJOR_VER); // Major Version
            binReplay.writeByte(MINOR_VER); // Minor Version
            binReplay.writeByte(1); // Header Flag
            binReplay.writeUnsignedInt(activeUser.siteId); // Userid
            binReplay.writeUnsignedInt(options.song.id); // Song ID
            binReplay.writeFloat(options.songRate) // Song Rate
            binReplay.writeUnsignedInt(timestamp);
            binReplay.writeUTF(judgements);
            binReplay.writeUTF(settingsEncode);
            binReplay.writeBytes(pack(binReplayNotes, binReplayBoos)); // Replay Pack
            binReplay.writeUnsignedInt(checksum(binReplay));

            if (!verifyReplayWrite(binReplay, activeUser, options, judgements, binReplayNotes, binReplayBoos, settingsEncode, timestamp))
            {
                return null;
            }

            return binReplay;
        }

        static public function readReplay(ba:ByteArray, ignoreOffset:Boolean = false):ReplayPacked
        {
            var replay:ReplayPacked = new ReplayPacked();
            ba.position = 0;
            var checksumCheck:uint = checksum(ba, true);
            try
            {
                // Replay Version Data
                replay.MAGIC = ba.readUTFBytes(4);
                replay.MAJOR_VER = ba.readByte();
                replay.MINOR_VER = ba.readByte();

                var judgeOffset:int = 0;
                var hasHeader:Boolean = ba.readByte() == 1;

                // Play Data
                if (hasHeader)
                {
                    replay.user_id = ba.readUnsignedInt();
                    replay.song_id = ba.readUnsignedInt();
                    replay.song_rate = ba.readFloat();
                    replay.timestamp = ba.readUnsignedInt();
                    replay.raw_judgements = ba.readUTF();
                    replay.raw_settings = ba.readUTF();
                    replay.judgements = JSON.parse(replay.raw_judgements);
                    replay.settings = JSON.parse(replay.raw_settings);

                    if (!ignoreOffset)
                        judgeOffset = replay.settings.judgeOffset * 1000 / 30;
                }

                // Replay Data
                var len:uint = ba.readUnsignedInt();
                var packed_replay:ByteArray = new ByteArray();
                ba.readBytes(packed_replay, 0, len);
                var unpacked_replay:Object = unpack(packed_replay, judgeOffset);
                if (unpacked_replay != null)
                {
                    replay.rep_notes = unpacked_replay["note"];
                    replay.rep_boos = unpacked_replay["boo"];
                }

                // Checksum
                replay.checksum = ba.readUnsignedInt();
                replay.rechecksum = checksumCheck;
                replay.replay_bin = ba;

                replay.update();
            }
            catch (e:Error)
            {
                return null;
            }
            ba.position = 0;
            return replay;
        }

        static private function verifyReplayWrite(binReplay:ByteArray, activeUser:User, options:GameOptions, judgements:String, binReplayNotes:Array, binReplayBoos:Array, settingsEncode:String, timestamp:Number):Boolean
        {
            // Read Replay to Verify Write
            var test:ReplayPacked = readReplay(binReplay, true);
            if (test == null)
            {
                trace("test is null, complete fail");
                return false;
            }
            if (MAGIC != test.MAGIC)
            {
                trace("MAGIC failed comparison", MAGIC, test.MAGIC);
                return false;
            }
            if (MAJOR_VER != test.MAJOR_VER)
            {
                trace("MAJOR_VER failed comparison", MAJOR_VER, test.MAJOR_VER);
                return false;
            }
            if (MINOR_VER != test.MINOR_VER)
            {
                trace("MINOR_VER failed comparison", MINOR_VER, test.MINOR_VER);
                return false;
            }
            if (activeUser.siteId != test.user_id)
            {
                trace("user_id failed comparison", activeUser.siteId, test.user_id);
                return false;
            }
            if (options.song.id != test.song_id)
            {
                trace("song_id failed comparison", options.song.id, test.song_id);
                return false;
            }
            if (options.songRate.toFixed(3) != test.song_rate.toFixed(3))
            {
                trace("song_rate failed comparison", options.songRate, test.song_rate);
                return false;
            }
            if (timestamp != test.timestamp)
            {
                trace("timestamp failed comparison", timestamp, test.timestamp);
                return false;
            }
            if (judgements != test.raw_judgements)
            {
                trace("raw_judgements failed comparison", judgements, test.raw_judgements);
                return false;
            }
            if (settingsEncode != test.raw_settings)
            {
                trace("raw_settings failed comparison", settingsEncode, test.raw_settings);
                return false;
            }

            // Compare Notes
            if (test.rep_notes == null)
            {
                trace("rep_notes is NULL");
                return false;
            }
            if (binReplayNotes.length != test.rep_notes.length)
            {
                trace("rep_notes length doesn't match", binReplayNotes.length, test.rep_notes.length);
                return false;
            }
            var compareFailure:int = 0;
            for (var i:int = 0; i < binReplayNotes.length; i++)
            {
                if (binReplayNotes[i] != test.rep_notes[i])
                {
                    trace("rep_notes[" + i + "]", binReplayNotes[i], "!=", test.rep_notes[i]);
                    compareFailure++;
                }
            }
            if (compareFailure > 0)
            {
                trace("rep_notes had", compareFailure, "incorrect matchings");
                return false;
            }

            // Compare Boos
            if (test.rep_boos == null)
            {
                trace("rep_boos is NULL");
                return false
            }
            if (binReplayBoos.length != test.rep_boos.length)
            {
                trace("rep_boos length doesn't match", binReplayBoos.length, test.rep_boos.length);
                return false;
            }
            // TODO: Boos are re-ordered when packed as they can appear in any order but are
            // unpacked in a fixed order, causing false positives.
            /*
               compareFailure = 0;
               for (i = 0; i < binReplayBoos.length; i++)
               {
               if (binReplayBoos[i]["d"] != test.rep_boos[i]["d"])
               {
               trace("rep_boos[" + i + "][d]", binReplayBoos[i]["d"], "!=", test.rep_boos[i]["d"], "(" + binReplayBoos[i]["t"], test.rep_boos[i]["t"] + ")");
               compareFailure++;
               }
               if (binReplayBoos[i]["t"] != test.rep_boos[i]["t"])
               {
               trace("rep_boos[" + i + "][t]", binReplayBoos[i]["t"], "!=", test.rep_boos[i]["t"], "(" + binReplayBoos[i]["d"], test.rep_boos[i]["d"] + ")");
               compareFailure++;
               }
               }
               if (compareFailure > 0)
               {
               trace("rep_boos had", compareFailure, "incorrect matchings");
               return false;
               }
             */
            return true;
        }

    }

}
