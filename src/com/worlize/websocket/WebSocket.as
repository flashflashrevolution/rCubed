/************************************************************************
 *  Copyright 2010-2012 Worlize Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ***********************************************************************/

package com.worlize.websocket
{
    import by.blooddy.crypto.Base64;
    import by.blooddy.crypto.SHA1;
    import com.flashfla.utils.StringUtil;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.net.SecureSocket;
    import flash.net.Socket;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import flash.utils.Timer;

    [Event(name = "connectionFail", type = "com.worlize.websocket.WebSocketErrorEvent")]
    [Event(name = "ioError", type = "flash.events.IOErrorEvent")]
    [Event(name = "abnormalClose", type = "com.worlize.websocket.WebSocketErrorEvent")]
    [Event(name = "message", type = "com.worlize.websocket.WebSocketEvent")]
    [Event(name = "frame", type = "com.worlize.websocket.WebSocketEvent")]
    [Event(name = "ping", type = "com.worlize.websocket.WebSocketEvent")]
    [Event(name = "pong", type = "com.worlize.websocket.WebSocketEvent")]
    [Event(name = "open", type = "com.worlize.websocket.WebSocketEvent")]
    [Event(name = "closed", type = "com.worlize.websocket.WebSocketEvent")]
    public class WebSocket extends EventDispatcher
    {
        private static const MODE_UTF8:int = 0;
        private static const MODE_BINARY:int = 0;

        private static const MAX_HANDSHAKE_BYTES:int = 10 * 1024; // 10KiB
        private static const SEND_FRAME_BUFFER:ByteArray = new ByteArray();

        private var _bufferedAmount:int = 0;

        private var _readyState:int;
        private var _uri:WebSocketURI;
        private var _protocols:Array;
        private var _serverProtocol:String;
        private var _host:String;
        private var _port:uint;
        private var _resource:String;
        private var _secure:Boolean;
        private var _origin:String;
        private var _useNullMask:Boolean = false;

        private var socket:Socket;
        private var timeout:uint;

        private var fatalError:Boolean = false;

        private var nonce:ByteArray;
        private var base64nonce:String;
        private var serverHandshakeResponse:String;
        private var serverExtensions:Array;
        private var serverSupportsDeflate:Boolean;
        private var currentFrame:WebSocketFrame;
        private var frameQueue:Vector.<WebSocketFrame>;
        private var fragmentationOpcode:int = 0;
        private var fragmentationSize:uint = 0;

        private var waitingForServerClose:Boolean = false;
        private var closeTimeout:int = 5000;
        private var closeTimer:Timer;

        private var handshakeBytesReceived:int;
        private var handshakeTimer:Timer;
        private var handshakeTimeout:int = 10000;

        public var config:WebSocketConfig = new WebSocketConfig();

        public var debug:Boolean = false;

        public function WebSocket(uri:WebSocketURI, origin:String, protocols:* = null, timeout:uint = 10000)
        {
            super(null);
            _uri = uri;

            if (protocols is String)
            {
                _protocols = [protocols];
            }
            else
            {
                _protocols = protocols;
            }
            if (_protocols)
            {
                for (var i:int = 0; i < _protocols.length; i++)
                {
                    _protocols[i] = StringUtil.trim(_protocols[i]);
                }
            }
            _origin = origin;
            this.timeout = timeout;
            this.handshakeTimeout = timeout;
            init();
        }

        private function init():void
        {
            parseUrl();

            validateProtocol();

            frameQueue = new Vector.<WebSocketFrame>();
            fragmentationOpcode = 0x00;
            fragmentationSize = 0;

            currentFrame = new WebSocketFrame();

            fatalError = false;

            closeTimer = new Timer(closeTimeout, 1);
            closeTimer.addEventListener(TimerEvent.TIMER, handleCloseTimer);

            handshakeTimer = new Timer(handshakeTimeout, 1);
            handshakeTimer.addEventListener(TimerEvent.TIMER, handleHandshakeTimer);

            socket = secure ? new SecureSocket() : new Socket();
            socket.endian = Endian.BIG_ENDIAN;
            socket.timeout = timeout;

            socket.addEventListener(Event.CONNECT, handleSocketConnect);
            socket.addEventListener(IOErrorEvent.IO_ERROR, handleSocketIOError);
            socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSocketSecurityError);
            socket.addEventListener(Event.CLOSE, handleSocketClose);
            socket.addEventListener(ProgressEvent.SOCKET_DATA, handleSocketData);

            _readyState = WebSocketState.INIT;
        }

        private function validateProtocol():void
        {
            if (_protocols)
            {
                var separators:Array = ["(", ")", "<", ">", "@",
                    ",", ";", ":", "\\", "\"",
                    "/", "[", "]", "?", "=",
                    "{", "}", " ", String.fromCharCode(9)];

                for (var p:int = 0; p < _protocols.length; p++)
                {
                    var protocol:String = _protocols[p];
                    for (var i:int = 0; i < protocol.length; i++)
                    {
                        var charCode:int = protocol.charCodeAt(i);
                        var char:String = protocol.charAt(i);
                        if (charCode < 0x21 || charCode > 0x7E || separators.indexOf(char) !== -1)
                        {
                            throw new WebSocketError("Illegal character '" + String.fromCharCode(char) + "' in subprotocol.");
                        }
                    }
                }
            }
        }

        public function connect():void
        {
            if (_readyState === WebSocketState.OPEN && !socket.connected)
            {
                _readyState = WebSocketState.CLOSED;
            }

            if (_readyState === WebSocketState.INIT || _readyState === WebSocketState.CLOSED)
            {
                _readyState = WebSocketState.CONNECTING;
                generateNonce();
                handshakeBytesReceived = 0;

                socket.connect(_host, _port);
                if (debug)
                {
                    Logger.info(this, "Connecting to " + _host + " on port " + _port);
                }
            }
        }

        public function addBinaryChainBuildingCertificate(certificate:ByteArray, trusted:Boolean):void
        {
            if (!secure)
                throw new Error("addBinaryChainBuildingCertificate only available for secure websockets");

            (socket as SecureSocket).addBinaryChainBuildingCertificate(certificate, trusted);
        }

        private function parseUrl():void
        {
            _host = _uri.host;
            var scheme:String = _uri.scheme.toLocaleLowerCase();
            if (scheme === 'wss')
            {
                _secure = true;
                _port = 443;
            }
            else if (scheme === 'ws')
            {
                _secure = false;
                _port = 80;
            }
            else
            {
                throw new Error("Unsupported scheme: " + scheme);
            }

            if (!isNaN(_uri.port) && _uri.port !== 0)
            {
                _port = _uri.port;
            }

            _resource = _uri.path;
        }

        private function generateNonce():void
        {
            nonce = new ByteArray();
            for (var i:int = 0; i < 16; i++)
            {
                nonce.writeByte(Math.round(Math.random() * 0xFF));
            }
            nonce.position = 0;
            base64nonce = Base64.encode(nonce);
        }

        public function get readyState():int
        {
            return _readyState;
        }

        public function get bufferedAmount():int
        {
            return _bufferedAmount;
        }

        public function get uri():String
        {
            var uri:String;
            uri = _secure ? "wss://" : "ws://";
            uri += _host;
            if ((_secure && _port !== 443) || (!_secure && _port !== 80))
            {
                uri += (":" + _port.toString());
            }
            uri += _resource;
            return uri;
        }

        public function get protocol():String
        {
            return _serverProtocol;
        }

        public function get extensions():Array
        {
            return [];
        }

        public function get host():String
        {
            return _host;
        }

        public function get port():uint
        {
            return _port;
        }

        public function get resource():String
        {
            return _resource;
        }

        public function get secure():Boolean
        {
            return _secure;
        }

        public function get connected():Boolean
        {
            return readyState === WebSocketState.OPEN;
        }

        // Pseudo masking is useful for speeding up wbesocket usage in a controlled environment,
        // such as a self-contained AIR app for mobile where the client can be resonably sure of
        // not intending to screw up proxies by confusing them with HTTP commands in the frame body
        // Probably not a good idea to enable if being used on the web in general cases.
        public function set useNullMask(val:Boolean):void
        {
            _useNullMask = val;
        }

        public function get useNullMask():Boolean
        {
            return _useNullMask;
        }

        private function verifyConnectionForSend():void
        {
            if (_readyState === WebSocketState.CONNECTING)
            {
                throw new WebSocketError("Invalid State: Cannot send data before connected.");
            }
        }

        public function sendUTF(data:String):void
        {
            verifyConnectionForSend();
            var frame:WebSocketFrame = new WebSocketFrame();
            frame.opcode = WebSocketOpcode.TEXT_FRAME;
            frame.binaryPayload = new ByteArray();
            frame.binaryPayload.writeMultiByte(data, 'utf-8');
            fragmentAndSend(frame);
        }

        public function sendBytes(data:ByteArray):void
        {
            verifyConnectionForSend();
            var frame:WebSocketFrame = new WebSocketFrame();
            frame.opcode = WebSocketOpcode.BINARY_FRAME;
            frame.binaryPayload = data;
            fragmentAndSend(frame);
        }

        public function ping(payload:ByteArray = null):void
        {
            verifyConnectionForSend();
            var frame:WebSocketFrame = new WebSocketFrame();
            frame.fin = true;
            frame.opcode = WebSocketOpcode.PING;
            if (payload)
            {
                frame.binaryPayload = payload;
            }
            sendFrame(frame);
        }

        private function pong(binaryPayload:ByteArray = null):void
        {
            verifyConnectionForSend();
            var frame:WebSocketFrame = new WebSocketFrame();
            frame.fin = true;
            frame.opcode = WebSocketOpcode.PONG;
            frame.binaryPayload = binaryPayload;
            sendFrame(frame);
        }

        private function fragmentAndSend(frame:WebSocketFrame):void
        {
            if (frame.opcode > 0x07)
            {
                throw new WebSocketError("You cannot fragment control frames.");
            }

            var threshold:uint = config.fragmentationThreshold;

            if (config.fragmentOutgoingMessages && frame.binaryPayload && frame.binaryPayload.length > threshold)
            {
                frame.binaryPayload.position = 0;
                var length:int = frame.binaryPayload.length;
                var numFragments:int = Math.ceil(length / threshold);
                for (var i:int = 1; i <= numFragments; i++)
                {
                    var currentFrame:WebSocketFrame = new WebSocketFrame();

                    // continuation opcode except for first frame.
                    currentFrame.opcode = (i === 1) ? frame.opcode : 0x00;

                    // fin set on last frame only
                    currentFrame.fin = (i === numFragments);

                    // length is likely to be shorter on the last fragment
                    var currentLength:int = (i === numFragments) ? length - (threshold * (i - 1)) : threshold;
                    frame.binaryPayload.position = threshold * (i - 1);

                    // Slice the right portion of the original payload
                    currentFrame.binaryPayload = new ByteArray();
                    frame.binaryPayload.readBytes(currentFrame.binaryPayload, 0, currentLength);

                    sendFrame(currentFrame);
                }
            }
            else
            {
                frame.fin = true;
                sendFrame(frame);
            }
        }

        private function sendFrame(frame:WebSocketFrame, force:Boolean = false):void
        {
            SEND_FRAME_BUFFER.length = 0;
            frame.mask = true;
            frame.useNullMask = _useNullMask;
            frame.send(SEND_FRAME_BUFFER);
            sendData(SEND_FRAME_BUFFER);
        }

        private function sendData(data:ByteArray, fullFlush:Boolean = false):void
        {
            if (!connected)
            {
                return;
            }
            data.position = 0;
            socket.writeBytes(data, 0, data.bytesAvailable);
            socket.flush();
            data.clear();
        }

        public function close(waitForServer:Boolean = true):void
        {
            if (!socket.connected && _readyState === WebSocketState.CONNECTING)
            {
                _readyState = WebSocketState.CLOSED;
                try
                {
                    socket.close();
                }
                catch (e:Error)
                { /* do nothing */
                }
            }
            if (socket.connected)
            {
                var frame:WebSocketFrame = new WebSocketFrame();
                frame.rsv1 = frame.rsv2 = frame.rsv3 = frame.mask = false;
                frame.fin = true;
                frame.opcode = WebSocketOpcode.CONNECTION_CLOSE;
                frame.closeStatus = WebSocketCloseStatus.NORMAL;
                var buffer:ByteArray = new ByteArray();
                frame.mask = true;
                frame.send(buffer);
                sendData(buffer, true);

                if (waitForServer)
                {
                    waitingForServerClose = true;
                    closeTimer.stop();
                    closeTimer.reset();
                    closeTimer.start();
                }
                dispatchClosedEvent();
            }
        }

        private function handleCloseTimer(event:TimerEvent):void
        {
            if (waitingForServerClose)
            {
                // server hasn't responded to our request to close the
                // connection, so we'll just close it.
                if (socket.connected)
                {
                    socket.close();
                }
            }
        }

        private function handleSocketConnect(event:Event):void
        {
            if (debug)
            {
                Logger.info(this, "Socket Connected");
            }
            sendHandshake();
        }

        private function handleSocketClose(event:Event):void
        {
            if (debug)
            {
                Logger.info(this, "Socket Disconnected");
            }
            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Socket Disconnected", 0));
            dispatchClosedEvent();
        }

        private function handleSocketData(event:ProgressEvent = null):void
        {
            if (_readyState === WebSocketState.CONNECTING)
            {
                readServerHandshake();
                return;
            }

            // addData returns true if the frame is complete, and false
            // if more data is needed.
            while (socket.connected && currentFrame.addData(socket, fragmentationOpcode, config) && !fatalError)
            {
                if (currentFrame.protocolError)
                {
                    drop(WebSocketCloseStatus.PROTOCOL_ERROR, currentFrame.dropReason);
                    return;
                }
                else if (currentFrame.frameTooLarge)
                {
                    drop(WebSocketCloseStatus.MESSAGE_TOO_LARGE, currentFrame.dropReason);
                    return;
                }
                if (!config.assembleFragments)
                {
                    var frameEvent:WebSocketEvent = new WebSocketEvent(WebSocketEvent.FRAME);
                    frameEvent.frame = currentFrame;
                    dispatchEvent(frameEvent);
                }
                processFrame(currentFrame);
                currentFrame = new WebSocketFrame();
            }
        }

        private function inflate(data:ByteArray):void
        {
            data.position = data.length;
            data.writeUnsignedInt(65535); // 00 00 ff ff
            data[0] = data[0] | 1; // not sure why flash wants this bit set
            data.inflate();
        }

        private function processFrame(frame:WebSocketFrame):void
        {
            var event:WebSocketEvent;
            var i:int;
            var currentFrame:WebSocketFrame;

            if (frame.rsv1 && !serverSupportsDeflate)
            {
                drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Received frame with rsv1 set without permessage-deflate negotiated.");
            }
            if (frame.rsv2 || frame.rsv3)
            {
                drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Received frame with reserved bit set without a negotiated extension.");
                return;
            }

            switch (frame.opcode)
            {
                case WebSocketOpcode.BINARY_FRAME:
                    if (config.assembleFragments)
                    {
                        if (frameQueue.length === 0)
                        {
                            if (frame.fin)
                            {
                                event = new WebSocketEvent(WebSocketEvent.MESSAGE);
                                event.message = new WebSocketMessage();
                                event.message.type = WebSocketMessage.TYPE_BINARY;
                                if (frame.rsv1)
                                    inflate(frame.binaryPayload)
                                event.message.binaryData = frame.binaryPayload;
                                dispatchEvent(event);
                            }
                            else if (frameQueue.length === 0)
                            {
                                // beginning of a fragmented message
                                frameQueue.push(frame);
                                fragmentationOpcode = frame.opcode;
                            }
                        }
                        else
                        {
                            drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Illegal BINARY_FRAME received in the middle of a fragmented message.  Expected a continuation or control frame.");
                            return;
                        }
                    }
                    break;
                case WebSocketOpcode.TEXT_FRAME:
                    if (config.assembleFragments)
                    {
                        if (frameQueue.length === 0)
                        {
                            if (frame.fin)
                            {
                                event = new WebSocketEvent(WebSocketEvent.MESSAGE);
                                event.message = new WebSocketMessage();
                                event.message.type = WebSocketMessage.TYPE_UTF8;
                                if (frame.rsv1)
                                    inflate(frame.binaryPayload)
                                event.message.utf8Data = frame.binaryPayload.readMultiByte(frame.binaryPayload.length, 'utf-8');
                                dispatchEvent(event);
                            }
                            else
                            {
                                // beginning of a fragmented message
                                frameQueue.push(frame);
                                fragmentationOpcode = frame.opcode;
                            }
                        }
                        else
                        {
                            drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Illegal TEXT_FRAME received in the middle of a fragmented message.  Expected a continuation or control frame.");
                            return;
                        }
                    }
                    break;
                case WebSocketOpcode.CONTINUATION:
                    if (config.assembleFragments)
                    {
                        if (fragmentationOpcode === WebSocketOpcode.CONTINUATION && frame.opcode === WebSocketOpcode.CONTINUATION)
                        {
                            drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Unexpected continuation frame.");
                            return;
                        }

                        fragmentationSize += frame.length;

                        if (fragmentationSize > config.maxMessageSize)
                        {
                            drop(WebSocketCloseStatus.MESSAGE_TOO_LARGE, "Maximum message size exceeded.");
                            return;
                        }

                        frameQueue.push(frame);

                        if (frame.fin)
                        {
                            // end of fragmented message, so we process the whole
                            // message now.  We also have to decode the utf-8 data
                            // for text frames after combining all the fragments.
                            event = new WebSocketEvent(WebSocketEvent.MESSAGE);
                            event.message = new WebSocketMessage();
                            var messageOpcode:int = frameQueue[0].opcode;
                            var binaryData:ByteArray = new ByteArray();
                            var totalLength:int = 0;
                            for (i = 0; i < frameQueue.length; i++)
                            {
                                totalLength += frameQueue[i].length;
                            }
                            if (totalLength > config.maxMessageSize)
                            {
                                drop(WebSocketCloseStatus.MESSAGE_TOO_LARGE, "Message size of " + totalLength + " bytes exceeds maximum accepted message size of " + config.maxMessageSize + " bytes.");
                                return;
                            }
                            for (i = 0; i < frameQueue.length; i++)
                            {
                                currentFrame = frameQueue[i];
                                binaryData.writeBytes(currentFrame.binaryPayload, 0, currentFrame.binaryPayload.length);
                                currentFrame.binaryPayload.clear();
                            }

                            // inflate if rsv1 is set in the first frame
                            if (frameQueue[0].rsv1)
                                inflate(binaryData);

                            binaryData.position = 0;
                            switch (messageOpcode)
                            {
                                case WebSocketOpcode.BINARY_FRAME:
                                    event.message.type = WebSocketMessage.TYPE_BINARY;
                                    event.message.binaryData = binaryData;
                                    break;
                                case WebSocketOpcode.TEXT_FRAME:
                                    event.message.type = WebSocketMessage.TYPE_UTF8;
                                    event.message.utf8Data = binaryData.readMultiByte(binaryData.length, 'utf-8');
                                    break;
                                default:
                                    drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Unexpected first opcode in fragmentation sequence: 0x" + messageOpcode.toString(16));
                                    return;
                            }
                            frameQueue = new Vector.<WebSocketFrame>();
                            fragmentationOpcode = 0x00;
                            fragmentationSize = 0;
                            dispatchEvent(event);
                        }
                    }
                    break;
                case WebSocketOpcode.PING:
                    if (debug)
                    {
                        Logger.info(this, "Received Ping");
                    }
                    var pingEvent:WebSocketEvent = new WebSocketEvent(WebSocketEvent.PING, false, true);
                    pingEvent.frame = frame;
                    if (dispatchEvent(pingEvent))
                    {
                        pong(frame.binaryPayload);
                    }
                    break;
                case WebSocketOpcode.PONG:
                    if (debug)
                    {
                        Logger.info(this, "Received Pong");
                    }
                    var pongEvent:WebSocketEvent = new WebSocketEvent(WebSocketEvent.PONG);
                    pongEvent.frame = frame;
                    dispatchEvent(pongEvent);
                    break;
                case WebSocketOpcode.CONNECTION_CLOSE:
                    if (debug)
                    {
                        Logger.info(this, "Received close frame");
                    }
                    if (waitingForServerClose)
                    {
                        // got confirmation from server, finish closing connection
                        if (debug)
                        {
                            Logger.info(this, "Got close confirmation from server.");
                        }
                        closeTimer.stop();
                        waitingForServerClose = false;
                        socket.close();
                    }
                    else
                    {
                        if (debug)
                        {
                            Logger.info(this, "Sending close response to server.");
                        }
                        close(false);
                        socket.close();
                    }
                    break;
                default:
                    if (debug)
                    {
                        Logger.info(this, "Unrecognized Opcode: 0x" + frame.opcode.toString(16));
                    }
                    drop(WebSocketCloseStatus.PROTOCOL_ERROR, "Unrecognized Opcode: 0x" + frame.opcode.toString(16));
                    break;
            }
        }

        private function handleSocketIOError(event:IOErrorEvent):void
        {
            Logger.error(this, "handleSocketIOError: " + Logger.event_error(event));
            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "IO Error", event.errorID));
            dispatchClosedEvent();
        }

        private function handleSocketSecurityError(event:SecurityErrorEvent):void
        {
            Logger.error(this, "handleSocketSecurityError: " + Logger.event_error(event));
            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Security Error", event.errorID));
            dispatchClosedEvent();
        }

        private function sendHandshake():void
        {
            serverHandshakeResponse = "";

            var hostValue:String = host;
            if ((_secure && _port !== 443) || (!_secure && _port !== 80))
            {
                hostValue += (":" + _port.toString());
            }

            var text:String = "";
            text += "GET " + resource + " HTTP/1.1\r\n";
            text += "Host: " + hostValue + "\r\n";
            text += "Upgrade: websocket\r\n";
            text += "Connection: Upgrade\r\n";
            text += "Sec-WebSocket-Key: " + base64nonce + "\r\n";
            if (_origin)
            {
                text += "Origin: " + _origin + "\r\n";
            }
            text += "Sec-WebSocket-Version: 13\r\n";
            if (_protocols)
            {
                var protosList:String = _protocols.join(", ");
                text += "Sec-WebSocket-Protocol: " + protosList + "\r\n";
            }

            // we offer permessage-deflate option and accept compressed data from the server, although
            // we never send compressed data ourselves. server_no_context_takeover is needed cause
            // there's no way to make flash's ByteArray.inflate re-use a sliding window
            text += "Sec-WebSocket-Extensions: permessage-deflate; server_no_context_takeover\r\n";

            // TODO: Handle Extensions
            text += "\r\n";

            if (debug)
            {
                Logger.info(this, text);
            }

            socket.writeMultiByte(text, 'us-ascii');
            socket.flush();

            handshakeTimer.stop();
            handshakeTimer.reset();
            handshakeTimer.start();
        }

        private function failHandshake(message:String = "Unable to complete websocket handshake."):void
        {
            if (debug)
            {
                Logger.error(this, message);
            }
            _readyState = WebSocketState.CLOSED;
            if (socket.connected)
            {
                socket.close();
            }

            handshakeTimer.stop();
            handshakeTimer.reset();

            var errorEvent:WebSocketErrorEvent = new WebSocketErrorEvent(WebSocketErrorEvent.CONNECTION_FAIL);
            errorEvent.text = message;
            dispatchEvent(errorEvent);

            var event:WebSocketEvent = new WebSocketEvent(WebSocketEvent.CLOSED);
            dispatchEvent(event);
        }

        private function failConnection(message:String):void
        {
            _readyState = WebSocketState.CLOSED;
            if (socket.connected)
            {
                socket.close();
            }

            var errorEvent:WebSocketErrorEvent = new WebSocketErrorEvent(WebSocketErrorEvent.CONNECTION_FAIL);
            errorEvent.text = message;
            dispatchEvent(errorEvent);

            var event:WebSocketEvent = new WebSocketEvent(WebSocketEvent.CLOSED);
            dispatchEvent(event);
        }

        private function drop(closeReason:uint = WebSocketCloseStatus.PROTOCOL_ERROR, reasonText:String = null):void
        {
            if (!connected)
            {
                return;
            }
            fatalError = true;
            var logText:String = "WebSocket: Dropping Connection. Code: " + closeReason.toString(10);
            if (reasonText)
            {
                logText += (" - " + reasonText);
                ;
            }
            Logger.info(this, logText);

            frameQueue = new Vector.<WebSocketFrame>();
            fragmentationSize = 0;
            if (closeReason !== WebSocketCloseStatus.NORMAL)
            {
                var errorEvent:WebSocketErrorEvent = new WebSocketErrorEvent(WebSocketErrorEvent.ABNORMAL_CLOSE);
                errorEvent.text = "Close reason: " + closeReason;
                dispatchEvent(errorEvent);
            }
            sendCloseFrame(closeReason, reasonText, true);
            dispatchClosedEvent();
            socket.close();
        }

        private function sendCloseFrame(reasonCode:uint = WebSocketCloseStatus.NORMAL, reasonText:String = null, force:Boolean = false):void
        {
            var frame:WebSocketFrame = new WebSocketFrame();
            frame.fin = true;
            frame.opcode = WebSocketOpcode.CONNECTION_CLOSE;
            frame.closeStatus = reasonCode;
            if (reasonText)
            {
                frame.binaryPayload = new ByteArray();
                frame.binaryPayload.writeUTFBytes(reasonText);
            }
            sendFrame(frame, force);
        }

        private function readServerHandshake():void
        {
            var upgradeHeader:Boolean = false;
            var connectionHeader:Boolean = false;
            var serverProtocolHeaderMatch:Boolean = false;
            var keyValidated:Boolean = false;
            var headersTerminatorIndex:int = -1;

            // Load in HTTP Header lines until we encounter a double-newline.
            while (headersTerminatorIndex === -1 && readHandshakeLine())
            {
                if (handshakeBytesReceived > MAX_HANDSHAKE_BYTES)
                {
                    failHandshake("Received more than " + MAX_HANDSHAKE_BYTES + " bytes during handshake.");
                    return;
                }

                headersTerminatorIndex = serverHandshakeResponse.search(/\r?\n\r?\n/);
            }
            if (headersTerminatorIndex === -1)
            {
                return;
            }

            if (debug)
            {
                Logger.info(this, "Server Response Headers:\n" + serverHandshakeResponse);
            }

            // Slice off the trailing \r\n\r\n from the handshake data
            serverHandshakeResponse = serverHandshakeResponse.slice(0, headersTerminatorIndex);

            var lines:Array = serverHandshakeResponse.split(/\r?\n/);

            // Validate status line
            var responseLine:String = lines.shift();
            var responseLineMatch:Array = responseLine.match(/^(HTTP\/\d\.\d) (\d{3}) ?(.*)$/i);
            if (responseLineMatch.length === 0)
            {
                failHandshake("Unable to find correctly-formed HTTP status line.");
                return;
            }
            var httpVersion:String = responseLineMatch[1];
            var statusCode:int = parseInt(responseLineMatch[2], 10);
            var statusDescription:String = responseLineMatch[3];
            if (debug)
            {
                Logger.info(this, "HTTP Status Received: " + statusCode + " " + statusDescription);
            }

            // Verify correct status code received
            if (statusCode !== 101)
            {
                failHandshake("An HTTP response code other than 101 was received.  Actual Response Code: " + statusCode + " " + statusDescription);
                return;
            }

            // Interpret HTTP Response Headers
            serverExtensions = [];
            try
            {
                while (lines.length > 0)
                {
                    responseLine = lines.shift();
                    var header:Object = parseHTTPHeader(responseLine);
                    var lcName:String = header.name.toLocaleLowerCase();
                    var lcValue:String = header.value.toLocaleLowerCase();
                    if (lcName === 'upgrade' && lcValue === 'websocket')
                    {
                        upgradeHeader = true;
                    }
                    else if (lcName === 'connection' && lcValue === 'upgrade')
                    {
                        connectionHeader = true;
                    }
                    else if (lcName === 'sec-websocket-extensions' && header.value)
                    {
                        var extensionsThisLine:Array = header.value.split(',');
                        serverExtensions = serverExtensions.concat(extensionsThisLine);
                    }
                    else if (lcName === 'sec-websocket-accept')
                    {
                        var byteArray:ByteArray = new ByteArray();
                        byteArray.writeUTFBytes(base64nonce + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
                        var expectedKey:String = Base64.encode(SHA1.digest(byteArray));
                        if (debug)
                        {
                            Logger.info(this, "Expected Sec-WebSocket-Accept value: " + expectedKey);
                        }
                        if (header.value === expectedKey)
                        {
                            keyValidated = true;
                        }
                    }
                    else if (lcName === 'sec-websocket-protocol')
                    {
                        if (_protocols)
                        {
                            for each (var protocol:String in _protocols)
                            {
                                if (protocol == header.value)
                                {
                                    _serverProtocol = protocol;
                                }
                            }
                        }
                    }
                }
            }
            catch (e:Error)
            {
                failHandshake("There was an error while parsing the following HTTP Header line:\n" + responseLine);
                return;
            }

            if (!upgradeHeader)
            {
                failHandshake("The server response did not include a valid Upgrade: websocket header.");
                return;
            }
            if (!connectionHeader)
            {
                failHandshake("The server response did not include a valid Connection: upgrade header.");
                return;
            }
            if (!keyValidated)
            {
                failHandshake("Unable to validate server response for Sec-Websocket-Accept header.");
                return;
            }

            if (_protocols && !_serverProtocol)
            {
                failHandshake("The server can not respond in any of our requested protocols");
                return;
            }

            if (debug)
            {
                Logger.info(this, "Server Extensions: " + serverExtensions.join(' | '));
            }

            serverSupportsDeflate = false;
            for each (var ext:String in serverExtensions)
                if (ext.indexOf('permessage-deflate') != -1)
                    serverSupportsDeflate = true;

            // The connection is validated!!
            handshakeTimer.stop();
            handshakeTimer.reset();

            serverHandshakeResponse = null;
            _readyState = WebSocketState.OPEN;

            // prepare for first frame
            currentFrame = new WebSocketFrame();
            frameQueue = new Vector.<WebSocketFrame>();

            dispatchEvent(new WebSocketEvent(WebSocketEvent.OPEN));

            // Start reading data
            handleSocketData();
            return;
        }

        private function handleHandshakeTimer(event:TimerEvent):void
        {
            failHandshake("Timed out waiting for server response.");
        }

        private function parseHTTPHeader(line:String):Object
        {
            var header:Array = line.split(/\: +/);
            return header.length === 2 ? {name: header[0],
                    value: header[1]} : null;
        }

        // Return true if the header is completely read
        private function readHandshakeLine():Boolean
        {
            var char:String;
            while (socket.bytesAvailable)
            {
                char = socket.readMultiByte(1, 'us-ascii');
                handshakeBytesReceived++;
                serverHandshakeResponse += char;
                if (char == "\n")
                {
                    return true;
                }
            }
            return false;
        }

        private function dispatchClosedEvent():void
        {
            if (handshakeTimer.running)
            {
                handshakeTimer.stop();
            }
            if (_readyState !== WebSocketState.CLOSED)
            {
                _readyState = WebSocketState.CLOSED;
                var event:WebSocketEvent = new WebSocketEvent(WebSocketEvent.CLOSED);
                dispatchEvent(event);
            }
        }

    }
}
