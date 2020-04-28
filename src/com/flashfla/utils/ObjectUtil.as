package com.flashfla.utils {
	import flash.utils.ByteArray;
	
	public class ObjectUtil {
		public static function clone(o:Object):Object {
			var bytes:ByteArray = new ByteArray();
			bytes.writeObject(o);
			bytes.position = 0;
			return bytes.readObject();
		}
		
		/**
		 * An equivalent of PHP's recursive print function print_r, which displays objects and arrays in a way that's readable by humans
		 * @param obj    Object to be printed
		 * @param level  (Optional) Current recursivity level, used for recursive calls
		 * @param output (Optional) The output, used for recursive calls
		 */
		public static function print_r(obj:*, level:int = 0, output:String = ''):* {
			if (level == 0)
				output = '(' + ObjectUtil.typeOf(obj) + ') {\n';
			else if (level == 10)
				return output;
			
			var tabs:String = '    ';
			for (var i:int = 0; i < level; i++, tabs += '    ') { }
			
			for (var child:*in obj) {
				output += tabs + '[' + child + '] => (' + ObjectUtil.typeOf(obj[child]) + ') ';
				//output += tabs +'['+ child +'] => ';
				
				if (ObjectUtil.count(obj[child]) == 0) {
					if (ObjectUtil.typeOf(obj[child]) == "string")
						output += "\"" + obj[child] + "\"";
					else if (ObjectUtil.typeOf(obj[child]) == "number")
						output += obj[child] + " [0x" + Number(obj[child]).toString(16) + "]";
					else
						output += obj[child];
				}
				
				var childOutput:String = '';
				if (typeof obj[child] != 'xml') {
					childOutput = ObjectUtil.print_r(obj[child], level + 1);
				}
				
				if (childOutput != '') {
					//output += '(' + ObjectUtil.typeOf(obj[child]) + ') {\n' + childOutput + tabs + '}';
					output += '{\n' + childOutput + tabs + '}';
				}
				output += '\n';
			}
			
			if (level == 0)
				return output + '}\n';
			else
				return output;
		}
		
		/**
		 * An extended version of the 'typeof' function
		 * @param 	variable
		 * @return	Returns the type of the variable
		 */
		public static function typeOf(variable:*):String {
			if (variable is Array)
				return 'array';
			else if (variable is Date)
				return 'date';
			else
				return typeof variable;
		}
		
		
		public static function getClass(obj:Object):Class {
			return Object(obj).constructor;
		}
		
		/**
		 * Returns the size of an object
		 * @param obj Object to be counted
		 */
		public static function count(obj:Object):uint {
			if (ObjectUtil.typeOf(obj) == 'array')
				return obj.length;
			else {
				var len:uint = 0;
				for (var item:*in obj) {
					if (item != 'mx_internal_uid')
						len++;
				}
				return len;
			}
		}
		
		
		public static function merge(main:Object, json:Object):void
		{
			if (json == null)
				return;
			if (main == null) {
				main = json;
				return;
			}
			for (var item:String in json)
			{
				if (main[item] == null)
					continue;
				if (json[item] is String || json[item] is Number)
					main[item] = json[item];
				else if (main[item] is Object)
					merge(main[item], json[item]);
			}
		}
		
		public static function differences(main:Object, changed:Object):Object
		{
			var out:Object;
			
			for (var item:String in main)
			{
				if (changed[item] == null)
					continue;
				
				if (main[item] is String || main[item] is Number)
				{
					if (main[item] != changed[item])
					{
						if (!out) out = {};
						out[item] = changed[item];
					}
				}
				else if (main[item] is Object)
				{
					var diffs:Object = differences(main[item], changed[item]);
					if (diffs)
					{
						if (!out) out = {};
						out[item] = diffs;
					}
				}
			}
			return out;
		}
	
	}
}
