package popups
{
    import arc.mp.MultiplayerPrompt;
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxText;
    import classes.Language;
    import classes.Noteskins;
    import classes.NoteskinsStruct;
    import classes.Text;
    import classes.replay.Base64Decoder;
    import classes.replay.Base64Encoder;
    import com.bit101.components.ColorChooser;
    import com.flashfla.components.ScrollPane;
    import com.flashfla.utils.ObjectUtil;
    import com.flashfla.utils.StringUtil;
    import com.flashfla.utils.SystemUtil;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.net.FileFilter;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    import game.GameOptions;
    import menu.MenuPanel;

    public class PopupCustomNoteskin extends MenuPanel
    {
        private var _lang:Language = Language.instance;

        private var DEFAULT_OPTIONS:GameOptions = new GameOptions();

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;
        private var sidebar_width:int = 170;
        private var image_holder:ScrollPane;
        private var cell_overlay:Sprite = new Sprite();

        private var btn_importImage:BoxButton;
        private var btn_importJSON:BoxButton;
        private var input_cellDims:BoxText;
        private var input_cellRotation:BoxText;
        private var exportOptions:BoxButton;
        private var saveOptions:BoxButton;
        private var closeOptions:BoxButton;

        private var file:FileReference;
        private var fileLoader:Loader;
        private var fileData:ByteArray;
        private var note_colors_btns:Array = [];
        private var note_colors_inputs:Array = [];

        private var dim_w:int = 1;
        private var dim_h:int = 1;
        private var cell_width:Number = 0;
        private var cell_height:Number = 0;

        private var noteskin_struct:Object = NoteskinsStruct.getDefaultStruct();
        private var active_color:String = "red";

        public function PopupCustomNoteskin(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            super.init();
            DEFAULT_OPTIONS.noteColors.push("receptor");

            return true;
        }

        override public function stageAdd():void
        {
            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);

            this.addChild(bmp);

            var bgbox:Box = new Box(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40, false, false);
            bgbox.x = 20;
            bgbox.y = 20;
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;
            this.addChild(bgbox);

            box = new Box(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40, false, false);
            box.x = 20;
            box.y = 20;
            box.activeAlpha = 0.4;
            box.graphics.lineStyle(1, 0xffffff);
            box.graphics.moveTo(box.width - sidebar_width, 0); // Sidebar border
            box.graphics.lineTo(box.width - sidebar_width, box.height);
            this.addChild(box);

            image_holder = new ScrollPane(box.width - sidebar_width - 2, box.height - 2);
            image_holder.x = 1;
            image_holder.y = 1;
            box.addChild(image_holder);

            //---------------------------------------------------------------------------------------------------------//
            var xPos:int = box.width - sidebar_width + 10;
            var yPos:int = 10;
            var xOff:int = 0;


            btn_importImage = new BoxButton(sidebar_width - 20, 25, _lang.string("popup_noteskin_import_image")); // "Import Image"
            btn_importImage.x = xPos;
            btn_importImage.y = yPos;
            btn_importImage.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(btn_importImage);
            yPos += 30;

            btn_importJSON = new BoxButton(sidebar_width - 20, 25, _lang.string("popup_noteskin_import_json")); // "Import JSON"
            btn_importJSON.x = xPos;
            btn_importJSON.y = yPos;
            btn_importJSON.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(btn_importJSON);
            yPos += 30;

            var cellDescText:Text = new Text(_lang.string("popup_noteskin_grid_rotation")); // "Grid & Rotation:"
            cellDescText.x = xPos;
            cellDescText.y = yPos;
            cellDescText.width = sidebar_width - 20;
            box.addChild(cellDescText);
            yPos += 25;

            input_cellDims = new BoxText((sidebar_width - 25) / 2, 20);
            input_cellDims.x = xPos;
            input_cellDims.y = yPos;
            input_cellDims.text = noteskin_struct["options"]["grid_dim"];
            input_cellDims.restrict = "0-9,";
            input_cellDims.addEventListener(Event.CHANGE, changeHandler);
            box.addChild(input_cellDims);

            input_cellRotation = new BoxText((sidebar_width - 25) / 2, 20);
            input_cellRotation.x = xPos + (((sidebar_width - 25) / 2) + 5);
            input_cellRotation.y = yPos;
            input_cellRotation.text = noteskin_struct["options"]["rotate"];
            input_cellRotation.restrict = "-0-9";
            input_cellRotation.addEventListener(Event.CHANGE, changeHandler);
            box.addChild(input_cellRotation);
            yPos += 25;

            var btn_note_color_input:BoxButton;
            for (var n:int = 0; n < DEFAULT_OPTIONS.noteColors.length; n++)
            {
                btn_note_color_input = new BoxButton((sidebar_width - 25) / 2, 20, _lang.string("note_colors_" + DEFAULT_OPTIONS.noteColors[n]));
                btn_note_color_input.x = (n % 2 == 0 ? xPos : xPos + ((sidebar_width - 25) / 2) + 5);
                btn_note_color_input.y = yPos;
                btn_note_color_input.alpha = 0.75;
                btn_note_color_input.note_color = DEFAULT_OPTIONS.noteColors[n];

                if (n % 2 == 1)
                    yPos += 25;

                btn_note_color_input.addEventListener(MouseEvent.CLICK, clickHandler);
                box.addChild(btn_note_color_input);
                note_colors_btns.push(btn_note_color_input);
            }

            var input_note_dir:BoxText;
            for (n = 0; n < DEFAULT_OPTIONS.noteDirections.length; n++)
            {
                xOff = 0;
                // Direction Text
                var note_dir:Text = new Text(DEFAULT_OPTIONS.noteDirections[n] + " Cell:");
                note_dir.x = xPos + 43;
                note_dir.y = yPos;
                note_dir.align = "right";
                box.addChild(note_dir);
                xOff += 44; //21

                var btn_width:int = (sidebar_width - 64); // / 2;

                input_note_dir = new BoxText(btn_width, 20);
                input_note_dir.x = xPos + xOff;
                input_note_dir.y = yPos;
                input_note_dir.pos = DEFAULT_OPTIONS.noteDirections[n];
                input_note_dir.addEventListener(Event.CHANGE, changeHandler);
                input_note_dir.restrict = "0-9,";
                note_colors_inputs.push(input_note_dir);
                box.addChild(input_note_dir);
                xOff += btn_width + 5;
                /*
                   input_note_dir = new BoxText(btn_width, 20);
                   input_note_dir.x = xPos + xOff;
                   input_note_dir.y = yPos;
                   input_note_dir.rot = DEFAULT_OPTIONS.noteDirections[n];
                   input_note_dir.addEventListener(Event.CHANGE, changeHandler);
                   input_note_dir.restrict = "-0-9";
                   note_colors_inputs.push(input_note_dir);
                   box.addChild(input_note_dir);
                 */
                yPos += 25;
            }

            updateDirections();

            //- Export
            exportOptions = new BoxButton(sidebar_width - 20, 25, _lang.string("menu_copy_to_clipboard"));
            exportOptions.x = xPos;
            exportOptions.y = box.height - 95;
            exportOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(exportOptions);

            //- Save
            saveOptions = new BoxButton(sidebar_width - 20, 25, _lang.string("menu_save"));
            saveOptions.x = xPos;
            saveOptions.y = box.height - 65;
            saveOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(saveOptions);

            //- Close
            closeOptions = new BoxButton(sidebar_width - 20, 25, _lang.string("menu_close"));
            closeOptions.x = xPos;
            closeOptions.y = box.height - 35;
            closeOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(closeOptions);
        }

        override public function stageRemove():void
        {
            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        private function updateDirections():void
        {
            for (var b:int = 0; b < note_colors_btns.length; b++)
            {
                note_colors_btns[b].alpha = active_color == note_colors_btns[b].note_color ? 1 : 0.75;
                note_colors_btns[b].boxColor = active_color == note_colors_btns[b].note_color ? 0x00FF00 : 0xFFFFFF;
            }

            var c:BoxText;
            for (var i:int = 0; i < note_colors_inputs.length; i++)
            {
                c = note_colors_inputs[i];
                if (c.hasOwnProperty("pos"))
                {
                    c.text = NoteskinsStruct.getDirectionValue(noteskin_struct, active_color, c["pos"], "c");
                }
                if (c.hasOwnProperty("rot"))
                {
                    c.text = NoteskinsStruct.getDirectionValue(noteskin_struct, active_color, c["rot"], "r");
                }
            }
        }


        private function noteskinsString():String
        {
            if (fileData == null)
                return null;

            // Base64 Encode Image
            var imgEncode:Base64Encoder = new Base64Encoder();
            imgEncode.encodeBytes(fileData);

            var export_json:Object = {"name": GlobalVariables.instance.activeUser.name + " - Custom Export",
                    "data": imgEncode.toString(),
                    "rects": ObjectUtil.differences(NoteskinsStruct.getDefaultStruct(), noteskin_struct)}

            return JSON.stringify(export_json);
        }

        private function saveNoteskin():void
        {
            LocalStore.setVariable("custom_noteskin", noteskinsString(), 20971520); // 20MB Mins size requested.
            Noteskins.instance.loadCustomNoteskin();
            GlobalVariables.instance.gameMain.addAlert(_lang.stringSimple("popup_noteskin_saved"), 90, Alert.GREEN);
        }

        private function exportNoteskin():void
        {
            var success:Boolean = SystemUtil.setClipboard(noteskinsString());
            if (success)
                GlobalVariables.instance.gameMain.addAlert(_lang.stringSimple("clipboard_success"), 90, Alert.GREEN);
            else
                GlobalVariables.instance.gameMain.addAlert(_lang.stringSimple("clipboard_failure"), 90, Alert.RED);
        }

        private function updateImage():void
        {
            if (fileLoader)
            {
                image_holder.clear();
                fileLoader.x = 5;
                fileLoader.y = 5;
                image_holder.content.addChild(fileLoader);
                image_holder.scrollTo(0, false);
                drawCells();
            }
        }

        private function drawCells():void
        {
            if (fileLoader && image_holder.content.contains(fileLoader) && fileLoader.width > 0 && fileLoader.height > 0)
            {

                // Make Overlay on Top Layer
                if (image_holder.content.contains(cell_overlay))
                    image_holder.content.removeChild(cell_overlay);
                image_holder.content.addChild(cell_overlay);

                cell_overlay.x = fileLoader.x;
                cell_overlay.y = fileLoader.y;

                updateCellDimensions();

                // Draw Cells
                cell_overlay.graphics.clear();
                cell_overlay.graphics.lineStyle(1, 0xffffff);
                for (var n_x:int = 0; n_x < dim_w; n_x++)
                {
                    for (var n_y:int = 0; n_y < dim_h; n_y++)
                    {
                        cell_overlay.graphics.beginFill(0, 0);
                        cell_overlay.graphics.drawRect(n_x * cell_width, n_y * cell_height, cell_width, cell_height);
                        cell_overlay.graphics.endFill();

                        var cell_post:Text = new Text(n_x + "," + n_y);
                        cell_post.x = cell_overlay.x + n_x * cell_width + 3;
                        cell_post.y = cell_overlay.y + n_y * cell_height;
                        image_holder.content.addChild(cell_post);

                        cell_overlay.graphics.beginFill(0, 0.75);
                        cell_overlay.graphics.drawRect(n_x * cell_width, n_y * cell_height, cell_post.width + 6, 20);
                        cell_overlay.graphics.endFill();

                    }
                }

                image_holder.update();
            }
        }

        private function updateCellDimensions():void
        {
            if (fileLoader && image_holder.content.contains(fileLoader) && fileLoader.width > 0 && fileLoader.height > 0)
            {
                var img_w:int = fileLoader.width;
                var img_h:int = fileLoader.height;
                dim_w = 1;
                dim_h = 1;

                var parsedCell:Array = NoteskinsStruct.parseCellInput(input_cellDims.text);
                dim_w = parsedCell[0];
                dim_h = parsedCell[1];

                cell_width = img_w / dim_w;
                cell_height = img_h / dim_h;

                noteskin_struct["options"]["grid_dim"] = dim_w.toString() + "," + dim_h.toString();
            }
        }

        private function changeHandler(e:Event):void
        {
            if (e.currentTarget == input_cellRotation)
                noteskin_struct["options"]["rotate"] = NoteskinsStruct.textToRotation(input_cellRotation.text, 90);
            if (e.currentTarget.hasOwnProperty("pos"))
                NoteskinsStruct.setDirectionValue(noteskin_struct, active_color, e.currentTarget["pos"], "c", e.currentTarget.text);
            else if (e.currentTarget.hasOwnProperty("rot"))
                NoteskinsStruct.setDirectionValue(noteskin_struct, active_color, e.currentTarget["rot"], "r", e.currentTarget.text);
            else
                updateImage();
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == exportOptions)
            {
                exportNoteskin();
                return;
            }
            else if (e.target == saveOptions)
            {
                saveNoteskin();
                return;
            }
            else if (e.target == closeOptions)
            {
                if (GlobalVariables.instance.gameMain.current_popup is PopupOptions)
                {
                    (GlobalVariables.instance.gameMain.current_popup as PopupOptions).setSettings();
                }
                if (this.parent != null && this.parent.contains(this))
                    this.parent.removeChild(this);

                return;
            }
            else if (e.target == btn_importImage)
            {
                try
                {
                    file = new FileReference();

                    var imageFileTypes:FileFilter = new FileFilter("Images (*.jpg, *.png)", "*.jpg;*.png");

                    file.browse([imageFileTypes]);
                    file.addEventListener(Event.SELECT, e_selectFile);
                }
                catch (e:Error)
                {

                }
                return;
            }
            else if (e.target == btn_importJSON)
            {
                var prompt:MultiplayerPrompt = new MultiplayerPrompt(box.parent, _lang.stringSimple("popup_noteskin_import_json")); // "Import JSON"
                prompt.move(Main.GAME_WIDTH / 2 - prompt.width / 2, Main.GAME_HEIGHT / 2 - prompt.height / 2);
                prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
                {
                    try
                    {
                        var json:Object = JSON.parse(subevent.params.value);
                        if (json["rects"] != null && json["data"] != null)
                        {

                            // Update Structs
                            ObjectUtil.merge(noteskin_struct, json["rects"]);
                            input_cellDims.text = noteskin_struct["options"]["grid_dim"];
                            input_cellRotation.text = noteskin_struct["options"]["rotate"];
                            updateDirections();

                            var imageDecoder:Base64Decoder = new Base64Decoder();
                            imageDecoder.decode(json["data"]);
                            fileData = imageDecoder.toByteArray();
                            loadImage();
                        }
                    }
                    catch (e:Error)
                    {
                    }
                });
                return;
            }
            else if (e.target.hasOwnProperty("note_color"))
            {
                active_color = e.target.note_color;
                updateDirections();
                return;
            }
        }

        private function e_selectFile(e:Event):void
        {
            file.addEventListener(Event.COMPLETE, e_loadFile);
            file.load();
        }

        private function e_loadFile(e:Event):void
        {
            fileData = file.data;

            loadImage();
        }

        private function loadImage():void
        {
            fileLoader = new Loader();
            fileLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_displayImage);
            fileLoader.loadBytes(fileData);
        }

        private function e_displayImage(e:Event):void
        {
            updateImage();
        }
    }
}
