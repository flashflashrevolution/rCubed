package com.flashfla.media
{
    import flash.utils.ByteArray;

    public class Beatbox
    {
        public static function parseBeatbox(data:ByteArray):Array
        {
            var header:Object = SwfParser.readHeader(data);

            var done:Boolean = false;
            while (data.bytesAvailable > 0 && !done)
            {
                var tag:Object = SwfParser.readTag(data);
                switch (tag.tag)
                {
                    case SwfParser.SWF_TAG_DOACTION:
                        try
                        {
                            var actionStack:Array = new Array();
                            var actionVariables:Object = new Object();
                            var actionRegisters:Array = new Array(4);
                            var constantPool:Array = [];
                            while (!done)
                            {
                                var action:Object = SwfParser.readAction(data);
                                switch (action.action)
                                {
                                    case SwfParser.SWF_ACTION_END:
                                        done = true;
                                        break;
                                    case SwfParser.SWF_ACTION_CONSTANTPOOL:
                                        constantPool = new Array();
                                        var constantCount:int = data.readUnsignedShort();
                                        for (var i:int = 0; i < constantCount; i++)
                                            constantPool.push(SwfParser.readString(data));
                                        break;
                                    case SwfParser.SWF_ACTION_PUSH:
                                        while (data.position < action.position + action.length)
                                        {
                                            var pushValue:Object;
                                            switch (data.readUnsignedByte())
                                            {
                                                case SwfParser.SWF_TYPE_STRING_LITERAL:
                                                    pushValue = SwfParser.readString(data);
                                                    break;
                                                case SwfParser.SWF_TYPE_FLOAT_LITERAL:
                                                    pushValue = data.readFloat();
                                                    break;
                                                case SwfParser.SWF_TYPE_NULL:
                                                    pushValue = null;
                                                    break;
                                                case SwfParser.SWF_TYPE_UNDEFINED:
                                                    pushValue = undefined;
                                                    break;
                                                case SwfParser.SWF_TYPE_REGISTER:
                                                    pushValue = actionRegisters[data.readUnsignedByte()];
                                                    break;
                                                case SwfParser.SWF_TYPE_BOOLEAN:
                                                    pushValue = Boolean(data.readUnsignedByte());
                                                    break;
                                                case SwfParser.SWF_TYPE_DOUBLE:
                                                    pushValue = data.readDouble();
                                                    break;
                                                case SwfParser.SWF_TYPE_INTEGER:
                                                    pushValue = data.readInt();
                                                    break;
                                                case SwfParser.SWF_TYPE_CONSTANT8:
                                                    pushValue = constantPool[data.readUnsignedByte()];
                                                    break;
                                                case SwfParser.SWF_TYPE_CONSTANT16:
                                                    pushValue = constantPool[data.readUnsignedShort()];
                                                    break;
                                                default:
                                                    break;
                                            }
                                            actionStack.push(pushValue);
                                        }
                                        break;
                                    case SwfParser.SWF_ACTION_POP:
                                        actionStack.pop();
                                        break;
                                    case SwfParser.SWF_ACTION_DUPLICATE:
                                        actionStack.push(actionStack[actionStack.length - 1]);
                                        break;
                                    case SwfParser.SWF_ACTION_STORE_REGISTER:
                                        actionRegisters[data.readUnsignedByte()] = actionStack[actionStack.length - 1];
                                        break;
                                    case SwfParser.SWF_ACTION_GET_VARIABLE:
                                        var gvName:String = actionStack.pop();
                                        if (!(gvName in actionVariables))
                                            actionVariables[gvName] = new Object();
                                        actionStack.push(actionVariables[gvName]);
                                        break;
                                    case SwfParser.SWF_ACTION_SET_VARIABLE:
                                        var svValue:Object = actionStack.pop();
                                        actionVariables[actionStack.pop()] = svValue;
                                        break;
                                    case SwfParser.SWF_ACTION_INIT_ARRAY:
                                        var arraySize:int = actionStack.pop();
                                        var array:Array = new Array();
                                        for (i = 0; i < arraySize; i++)
                                            array.push(actionStack.pop());
                                        actionStack.push(array);
                                        break;
                                    case SwfParser.SWF_ACTION_GET_MEMBER:
                                        var gmName:String = actionStack.pop();
                                        var gmObject:Object = actionStack.pop();
                                        if (!(gmName in gmObject))
                                            gmObject[gmName] = new Object();
                                        actionStack.push(gmObject[gmName]);
                                        break;
                                    case SwfParser.SWF_ACTION_SET_MEMBER:
                                        var smValue:Object = actionStack.pop();
                                        var smName:String = actionStack.pop();
                                        actionStack.pop()[smName] = smValue;
                                        break;
                                    default:
                                        break;
                                }
                                data.position = action.position + action.length;
                            }
                            var _root:Object = actionVariables["_root"] || {};
                            var beatBox:Array = _root["beatBox"];
                            if (beatBox)
                                return beatBox;
                        }
                        catch (error:Error)
                        {
                        }
                        done = false;
                        break;
                    default:
                        break;
                }

                data.position = tag.position + tag.length;
            }

            return null;
        }
    }
}
