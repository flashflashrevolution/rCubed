package
{
    import classes.Language;
    import classes.Site;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import com.coltware.airxzip.ZipEntry;
    import com.coltware.airxzip.ZipFileReader;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.sprintf;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.net.URLRequest;
    import flash.net.URLStream;
    import flash.system.Capabilities;
    import flash.text.AntiAliasType;
    import flash.text.StyleSheet;
    import flash.text.TextField;
    import flash.utils.ByteArray;
    import menu.MenuPanel;

    public class AirUpdater extends MenuPanel
    {
        private var _site:Site = Site.instance;
        private var _lang:Language = Language.instance;

        private var os:String = Capabilities.os.toLowerCase();

        protected var urlStream:URLStream;
        protected var fileStream:FileStream;
        private var downloadedFile:File;

        private var reader:ZipFileReader;
        private var updateList:Array;
        private var update_checks:Number = 0;

        private var titleDisplay:Text;
        private var messageDisplay:Text;
        private var actionButton:BoxButton;
        private var outputText:TextField;
        private var actionState:int = 0;

        private var totalFiles:int = 0;
        private var failFiles:int = 0;

        public function AirUpdater(myParent:MenuPanel)
        {
            super(myParent);

            updateList = [];

        }

        override public function stageAdd():void
        {

            titleDisplay = new Text(this, 5, 35, _lang.string("air_game_update"), 20);
            titleDisplay.width = Main.GAME_WIDTH - 10;
            titleDisplay.align = Text.CENTER;

            messageDisplay = new Text(this, 5, 65, Constant.AIR_VERSION + " -> " + _site.data["game_r3air_version"], 14);
            messageDisplay.width = Main.GAME_WIDTH - 10;
            messageDisplay.align = Text.CENTER;

            actionButton = new BoxButton(this, 25, Main.GAME_HEIGHT - 25 - 25, Main.GAME_WIDTH - 50, 25, "---", 12, e_actionButton);
            actionButtonState(false);

            var box:Box = new Box(this, 25, 115, false, false);
            box.setSize(Main.GAME_WIDTH - 50, 300);

            var style:StyleSheet = new StyleSheet();
            style.setStyle("BODY", {color: "#FFFFFF", fontSize: 14});
            style.setStyle("A", {textDecoration: "underline", fontWeight: "bold"});
            outputText = new TextField();
            outputText.styleSheet = style;
            outputText.width = box.width - 10;
            outputText.height = box.height - 10;
            outputText.x = 5;
            outputText.y = 5;
            outputText.selectable = true;
            outputText.embedFonts = true;
            outputText.antiAliasType = AntiAliasType.ADVANCED;
            outputText.multiline = true;
            outputText.wordWrap = true;
            outputText.htmlText = "<BODY><FONT face=\"" + Language.FONT_NAME + "\"></FONT></BODY>";
            box.addChild(outputText);

            update_checks = LocalStore.getVariable("air_update_checks", 0);
            if (update_checks > 0)
            {
                appendText(getUpdateCheckText());
            }

            appendText(_lang.string("air_update_pre_message"));

            if (getUpdateFile() == null)
            {
                downloadUpdate();
            }
            else
            {
                unpackUpdate();
            }
        }

        private function getUpdateCheckText():String
        {
            if (update_checks == 0)
                return "";

            var u:String = _lang.string("air_update_fail") + " [" + update_checks + "]\n";
            if (update_checks >= 3)
                u += "<B><FONT COLOR=\"#ffa0a0\">" + _lang.string("air_update_fail_multiple") + "</FONT></B>\n";
            return u + "---------------------------------------------------------------------\n";
        }

        private function actionButtonState(boolean:Boolean):void
        {
            actionButton.enabled = boolean;
            actionButton.alpha = boolean ? 1 : 0.75;
        }

        private function appendText(string:String, newLine:Boolean = true):void
        {
            outputText.htmlText = outputText.htmlText.substr(0, outputText.htmlText.length - 14) + string + (newLine ? "\n" : "") + "</FONT></BODY>";
            outputText.scrollV = outputText.maxScrollV;
        }

        private function e_actionButton(e:Event):void
        {
            if (actionButton.enabled)
            {
                if (actionState == 1)
                {
                    LocalStore.setVariable("air_update_checks", update_checks + 1);
                    appendText("---------------------------------------------------------------------");
                    appendText(_lang.string("air_process_update"));
                    actionState = 2
                    actionButtonState(false);
                    do_file_process();
                }
                else if (actionState == 2)
                {
                    actionButtonState(false);
                    restartGame();
                }
            }
        }

        private function restartGame():void
        {
            appendText("---------------------------------------------------------------------");
        /*
           if(NativeProcess.isSupported)
           {
           var updateFile:File = getGameFile();
           if (updateFile != null) {
           var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
           var cmdExe:File = (os.indexOf("win") > -1) ? new File("C:\\Windows\\System32\\cmd.exe") : null;
           if (false && cmdExe && cmdExe.exists)
           {
           var args:Vector.<String> = new Vector.<String>();
           args.push("/c", updateFile.nativePath);

           info.executable = cmdExe;
           info.arguments = args;
           appendText("Using CMD");
           }
           else
           {
           info.workingDirectory = File.applicationDirectory;
           info.executable = updateFile;
           appendText("Using R3Air.exe");
           }
           appendText(info.workingDirectory.nativePath);
           appendText(info.executable.nativePath);
           var installProcess:NativeProcess = new NativeProcess();
           try
           {

           updateFile.openWithDefaultApplication();
           installProcess.start(info);
           appendText("Starting Game");
           } catch (e:Error)
           {
           appendText(e.name + " (" + e.errorID + "):" + e.message + "\n" + e.getStackTrace());
           }
           } else {
           appendText("Unable to find game executable...");
           }
           }
           else
           {
           appendText("NativeProcess not supported.");
           }
         */

        }

        private function getUpdateFile():File
        {
            var air_file:File = new File(AirContext.getAppPath("R3Air." + _site.data["game_r3air_version"] + ".air"));
            if (air_file.exists && !air_file.isDirectory)
            {
                return air_file;
            }
            return null;
        }

        private function getGameFile():File
        {
            var air_file:File = File.applicationDirectory.resolvePath("R3Air.exe");
            if (air_file.exists && !air_file.isDirectory)
            {
                return air_file;
            }
            return null;
        }

        /**
         * ------------------------------------ DOWNLOAD UPDATE SECTION -------------------------------------
         */

        /**
         * Starts downloading update.
         */
        public function downloadUpdate():void
        {
            var URL:String = Constant.ROOT_URL + "~velocity/P/R3Air." + _site.data["game_r3air_version"] + ".air?t=" + new Date().getTime();
            downloadedFile = new File(AirContext.getAppPath("R3Air." + _site.data["game_r3air_version"] + ".air"));

            fileStream = new FileStream();
            fileStream.addEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);
            fileStream.addEventListener(Event.CLOSE, fileStream_closeHandler);
            fileStream.openAsync(downloadedFile, FileMode.WRITE);

            urlStream = new URLStream();
            urlStream.addEventListener(ProgressEvent.PROGRESS, urlStream_progressHandler);
            urlStream.addEventListener(Event.COMPLETE, urlStream_completeHandler);
            urlStream.addEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);

            try
            {
                urlStream.load(new URLRequest(URL));
            }
            catch (error:Error)
            {
            }
        }

        protected function fileStream_closeHandler(e:Event):void
        {
            fileStream.removeEventListener(Event.CLOSE, fileStream_closeHandler);
            fileStream.removeEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);

            unpackUpdate();
        }

        protected function urlStream_progressHandler(e:ProgressEvent):void
        {
            var bytes:ByteArray = new ByteArray();
            urlStream.readBytes(bytes);
            fileStream.writeBytes(bytes);

            var BL:Number = e.bytesLoaded;
            var BT:Number = e.bytesTotal;

            if (actionButton)
            {
                actionButton.text = Math.round((BL / BT) * 100) + "%  --- " + (BT > 0 ? "(" + NumberUtil.bytesToString(BL) + " / " + NumberUtil.bytesToString(BT) + ")" : "");
            }
        }

        protected function urlStream_completeHandler(e:Event):void
        {
            urlStream.removeEventListener(ProgressEvent.PROGRESS, urlStream_progressHandler);
            urlStream.removeEventListener(Event.COMPLETE, urlStream_completeHandler);
            urlStream.removeEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);
            urlStream.close();
            fileStream.close();
        }

        protected function urlStream_ioErrorHandler(e:IOErrorEvent):void
        {
            fileStream.removeEventListener(Event.CLOSE, fileStream_closeHandler);
            fileStream.removeEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);
            fileStream.close();

            urlStream.removeEventListener(ProgressEvent.PROGRESS, urlStream_progressHandler);
            urlStream.removeEventListener(Event.COMPLETE, urlStream_completeHandler);
            urlStream.removeEventListener(IOErrorEvent.IO_ERROR, urlStream_ioErrorHandler);
            urlStream.close();
            appendText(_lang.string("air_update_download_error"));
        }

        /**
         * ------------------------------------ UPDATE UNPACK SECTION -------------------------------------
         */

        public function unpackUpdate():void
        {
            var air_file:File = getUpdateFile();
            if (air_file != null)
            {
                appendText(_lang.string("air_update_unpacking"));
                var haveChangeLog:Boolean = false;
                try
                {
                    reader = new ZipFileReader();
                    reader.open(air_file);

                    var list:Array = reader.getEntries();
                    updateList = [];
                    for each (var entry:ZipEntry in list)
                    {
                        if (!entry.isDirectory())
                        {
                            updateList.push(entry);
                            if (entry.getFilename() == "changelog.txt")
                            {
                                try
                                {
                                    var changeBytes:ByteArray = reader.unzip(entry);
                                    outputText.htmlText = "<BODY><FONT face=\"" + Language.FONT_NAME + "\">";
                                    outputText.htmlText += getUpdateCheckText();
                                    outputText.htmlText += changeBytes.toString().replace(/\r\n/gi, "\n") + "\n</FONT></BODY>";
                                    haveChangeLog = true;
                                }
                                catch (e:Error)
                                {

                                }
                            }
                        }
                    }
                    if (!haveChangeLog)
                        appendText(_lang.string("air_update_no_changelog"));
                    totalFiles = updateList.length;
                    actionState = 1;
                    actionButton.text = _lang.string("air_start_update");
                    actionButtonState(true);
                }
                catch (e:Error)
                {
                    try
                    {
                        LocalStore.setVariable("air_update_checks", update_checks + 1);
                        reader.close();
                        air_file.deleteFile();
                        appendText("<B><FONT COLOR=\"#ffa0a0\">" + _lang.string("air_unpack_error") + "</FONT></B>");
                    }
                    catch (fe:Error)
                    {

                    }
                }

            }
            else
            {
                appendText(_lang.string("air_update_missing"));
            }

        }

        private function do_file_process():void
        {
            if (updateList.length > 0)
            {
                var entry:ZipEntry = updateList.pop();

                appendText("- " + entry.getFilename() + " ... ", false);
                try
                {
                    // Write File Data
                    AirContext.writeFile(AirContext.getAppPath(entry.getFilename()), reader.unzip(entry), 0, e_fileError);
                    appendText("<FONT COLOR=\"#84ff94\">" + _lang.string("air_file_success") + "</FONT>");
                }
                catch (e:Error)
                {
                    appendText("<B><FONT COLOR=\"#ffa0a0\">" + _lang.string("air_file_failure") + "</FONT></B>");
                    failFiles++;
                }
                do_file_process();
            }
            else
            {
                reader.close();
                appendText("---------------------------------------------------------------------");
                if (failFiles > 0)
                {
                    appendText("<FONT COLOR=\"#84ff94\">" + sprintf(_lang.string("air_count_files_success"), {"count": (totalFiles - failFiles)}) + "</FONT></B>");
                    appendText("<B><FONT COLOR=\"#ffa0a0\">" + sprintf(_lang.string("air_count_files_failure"), {"count": (failFiles)}) + "</FONT></B>");
                    appendText("<B><FONT COLOR=\"#ffa0a0\">" + sprintf(_lang.string("air_count_files_error"), {"count": (failFiles)}) + "</FONT></B>\n");
                }
                else
                {
                    try
                    {
                        getUpdateFile().deleteFile();
                    }
                    catch (e:Error)
                    {

                    }
                }
                appendText(_lang.string("air_manual_restart"));
                actionButton.text = _lang.string("air_start_update_2");
                actionButtonState(false);
            }
        }

        private function e_fileError(e:Event):void
        {
            appendText("<FONT COLOR=\"#ffa0a0\">FAILURE-2</FONT>");
            failFiles++;
        }
    }
}
