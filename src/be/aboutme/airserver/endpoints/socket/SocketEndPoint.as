package be.aboutme.airserver.endpoints.socket
{
    import be.aboutme.airserver.endpoints.IClientHandler;
    import be.aboutme.airserver.endpoints.IEndPoint;
    import be.aboutme.airserver.endpoints.socket.handlers.SocketClientHandler;
    import be.aboutme.airserver.endpoints.socket.handlers.SocketClientHandlerFactory;
    import be.aboutme.airserver.events.EndPointEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.ServerSocketConnectEvent;
    import flash.net.ServerSocket;

    public class SocketEndPoint extends EventDispatcher implements IEndPoint
    {
        private var port:uint;
        private var portLimit:uint;
        private var socketClientHandlerFactory:SocketClientHandlerFactory;
        private var serverSocket:ServerSocket;

        private var clientHandlers:Vector.<SocketClientHandler>;

        public function SocketEndPoint(port:uint, socketClientHandlerFactory:SocketClientHandlerFactory)
        {
            this.port = port;
            this.portLimit = Math.min(port + 10, 0xFFFF);
            this.socketClientHandlerFactory = socketClientHandlerFactory;
            clientHandlers = new Vector.<SocketClientHandler>();
        }

        public function open():Boolean
        {
            clientHandlers = new Vector.<SocketClientHandler>();

            for (; this.port < this.portLimit; this.port++)
            {
                try
                {
                    //bind the server socket
                    serverSocket = new ServerSocket();
                    serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, clientConnectHandler, false, 0, true);
                    serverSocket.addEventListener(Event.CLOSE, serverSocketCloseHandler, false, 0, true);
                    serverSocket.bind(port);
                    serverSocket.listen();
                    break;
                }
                catch (error:Error)
                {

                }
            }

            return true;
        }

        public function close():void
        {
            //close all socket clienthandlers
            for each (var clientHandler:IClientHandler in clientHandlers)
            {
                clientHandler.close();
            }

            //reset vector
            clientHandlers = new Vector.<SocketClientHandler>();

            //close the socket
            if (serverSocket != null && serverSocket.bound)
            {
                serverSocket.close();
            }
        }

        private function clientConnectHandler(event:ServerSocketConnectEvent):void
        {
            //create the clienthandler
            var clientHandler:IClientHandler = socketClientHandlerFactory.createHandler(event.socket);

            //add event listeners to the clienthandler
            clientHandler.addEventListener(Event.CLOSE, clientHandlerCloseHandler, false, 0, true);
            clientHandlers.push(clientHandler);

            //dispatch added event
            var e:EndPointEvent = new EndPointEvent(EndPointEvent.CLIENT_HANDLER_ADDED);
            e.clientHandler = clientHandler;
            dispatchEvent(e);
        }

        private function serverSocketCloseHandler(event:Event):void
        {
            close();
        }

        private function clientHandlerCloseHandler(event:Event):void
        {
            var clientHandler:IClientHandler = event.target as IClientHandler;

            //remove event listener
            clientHandler.removeEventListener(Event.CLOSE, clientHandlerCloseHandler);

            //remove it from the vector
            for (var i:int = clientHandlers.length - 1; i >= 0; i--)
                if (clientHandlers[i] == clientHandler)
                    clientHandlers.splice(i, 1);
        }

        public function type():String
        {
            return socketClientHandlerFactory.type;
        }

        public function currentPort():uint
        {
            return serverSocket != null && serverSocket.bound ? serverSocket.localPort : 0;
        }
    }
}
