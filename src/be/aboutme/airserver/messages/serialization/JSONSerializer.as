package be.aboutme.airserver.messages.serialization
{
    import be.aboutme.airserver.messages.Message;

    public class JSONSerializer implements IMessageSerializer
    {

        protected var messageDelimiter:String;

        public function JSONSerializer(messageDelimiter:String = "\n")
        {
            this.messageDelimiter = messageDelimiter;
        }

        public function serialize(message:Message):*
        {
            return JSON.stringify(message);
        }

        public function deserialize(serialized:*):Vector.<Message>
        {
            var split:Array = serialized.split(messageDelimiter);
            var messages:Vector.<Message> = new Vector.<Message>();
            for each (var input:String in split)
            {
                if (input.length > 0)
                {
                    var decoded:Object = JSON.parse(input);
                    var message:Message = new Message();
                    if (decoded.hasOwnProperty("senderId"))
                        message.senderId = decoded.senderId;
                    if (decoded.hasOwnProperty("command"))
                        message.command = decoded.command;
                    if (decoded.hasOwnProperty("data"))
                        message.data = decoded.data;
                    else
                        message.data = decoded;
                    messages.push(message);
                }
            }
            return messages;
        }
    }
}
