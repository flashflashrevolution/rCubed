package com.flashfla.registry
{
    import org.appsroid.RegistryModify;
    import flash.filesystem.File;
    import flash.events.Event;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import RegExp;
    import flash.desktop.NativeApplication

    /**
     * ...
     * @author Zageron
     */
    public class UriTool
    {

        public function UriTool()
        {
            var rm:RegistryModify = new RegistryModify("data/registry-editor.exe");
            rm.addEventListener("ErrorData", onError);
        }

        private function onError(e:Event):void
        {
            trace("Error message:", e);
        }

        public static function load_uri_data(uri_registry_data:String):String
        {
            var file:File = File.applicationDirectory.resolvePath(uri_registry_data);
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            return stream.readUTFBytes(stream.bytesAvailable);
        }

        public static function template_replace_application_path(registry_json:String):String
        {
            var argumentCheck:RegExp = /(\{\{(.*)\}\})/i;
            var result:String = registry_json.replace(argumentCheck, File.applicationDirectory.nativePath + "\\R3Air.exe");
            trace(result);
            return result;
        }
    }
}
