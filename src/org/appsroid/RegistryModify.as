package org.appsroid
{
    import flash.desktop.NativeProcess;
    import flash.desktop.NativeProcessStartupInfo;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.NativeProcessExitEvent;
    import flash.events.ProgressEvent;
    import flash.filesystem.File;

    public class RegistryModify extends EventDispatcher
    {
        private var _np:NativeProcess;
        private var _npi:NativeProcessStartupInfo;
        private var _args:Vector.<String>;
        private var exePath:String;

        public var _output:String;

        public function RegistryModify(_exePath:String)
        {
            exePath = _exePath;
        }

        public function readValue(_rootKey:String, _path:String, _key:String):void
        {
            _args = new Vector.<String>();
            _args.push("-action:read", "-key:" + _key, "-path:" + _path, "-rootkey:" + _rootKey);
            process();
        }

        public function writeValue(_rootKey:String, _path:String, _key:String, _value:String):void
        {
            _args = new Vector.<String>();
            _args.push("-action:write", "-key:" + _key, "-value:" + _value, "-path:" + _path, "-rootkey:" + _rootKey);
            process();
        }

        public function writeDwordValue(_rootKey:String, _path:String, _key:String, _value:String):void
        {
            _args = new Vector.<String>();
            _args.push("-action:writedword", "-key:" + _key, "-value:" + _value, "-path:" + _path, "-rootkey:" + _rootKey);
            process();
        }

        public function deleteKey(_rootKey:String, _path:String):void
        {
            _args = new Vector.<String>();
            _args.push("-action:delete", "-path:" + _path, "-rootkey:" + _rootKey);
            process();
        }

        public function checkKey(_rootKey:String, _path:String):void
        {
            _args = new Vector.<String>();
            _args.push("-action:check", "-path:" + _path, "-rootkey:" + _rootKey);
            process();
        }

        private function process():void
        {
            _npi = new NativeProcessStartupInfo();
            _npi.executable = File.applicationDirectory.resolvePath(exePath);
            _npi.arguments = _args;

            _np = new NativeProcess();
            _np.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
            _np.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
            _np.addEventListener(NativeProcessExitEvent.EXIT, onExit);
            _np.start(_npi);
        }

        private function onOutputData(e:ProgressEvent):void
        {
            _output = String(_np.standardOutput.readUTFBytes(_np.standardOutput.bytesAvailable));
            dispatchEvent(new Event("OutputData"));
        }

        private function onErrorData(e:ProgressEvent):void
        {
            _output = String(_np.standardError.readUTFBytes(_np.standardError.bytesAvailable));
            dispatchEvent(new Event("ErrorData"));
        }

        private function onExit(e:NativeProcessExitEvent):void
        {
            _np.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
            _np.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
            _np.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
            _npi = null;
            _np = null;
            _args = null;
            dispatchEvent(new Event(Event.COMPLETE));
        }
    }
}
