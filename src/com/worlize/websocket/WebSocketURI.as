package com.worlize.websocket
{

    public class WebSocketURI
    {
        public var scheme:String;
        public var host:String;
        public var port:uint;
        public var path:String;

        public function WebSocketURI(host:String, port:uint = 80, scheme:String = "ws", path:String = "/")
        {
            this.host = host;
            this.port = port;
            this.scheme = scheme;
            this.path = path;
        }
    }
}
