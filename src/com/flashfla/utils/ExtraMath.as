package com.flashfla.utils
{
    import flash.utils.Dictionary

    public class ExtraMath
    {
        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getRandomFraction
        //Function Nature: Returns a random fraction in decimal format with specifed number of decimal places
        //Argument Description: <startValue>,<endValue>,<number of decimal places to be retained(optional)>,<except some fractions(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getRandomFraction(10,12,3));
        //Output:11.345
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.getRandomFraction(10,12,2,[11.34,10.87]));
        //Output:10.76(will not include 11.34,10.87);
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getRandomFraction($min:Number, $max:Number, roundOff:int = 2, exceptArray:Array = null):Number
        {
            var ran:Number = Math.floor((Math.random() * ($max - $min) + $min) * Math.pow(10, roundOff)) / Math.pow(10, roundOff);
            if (exceptArray)
            {
                var isInExceptArray:Boolean = true;
                var len:int = exceptArray.length;
                while (isInExceptArray)
                {
                    isInExceptArray = false
                    for (var i:int; i < len; i++)
                    {
                        if (ran == exceptArray[i])
                        {
                            isInExceptArray = true;
                            break;
                        }
                    }
                    if (isInExceptArray)
                    {
                        ran = Math.floor((Math.random() * ($max - $min) + $min) * Math.pow(10, roundOff)) / Math.pow(10, roundOff);
                    }
                }
            }
            return ran;
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getRandom
        //Function Nature: Returns a random integer
        //Argument Description: <startValue>,<endValue>,<except some integers(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getRandom(1,10));
        //Output:5
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.getRandom(1,10,[3,4,5]));
        //Output:7(will not include 3,4,5);
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getRandom($min:int, $max:int, exceptArray:Array = null):int
        {
            var series:Array = new Array();
            var dontInclude:Dictionary = new Dictionary(true);
            if (exceptArray)
            {
                var len:int = exceptArray.length;
                for (var i:int; i < len; i++)
                {
                    dontInclude[exceptArray[i]] = true
                }
            }
            for (i = $min; i <= $max; i++)
            {
                if (dontInclude[i] != true)
                {
                    series.push(i);
                }
            }
            var ran:Number = Math.floor(Math.random() * series.length);
            var number:* = series.splice(ran, 1);
            if (number.length == 0)
            {
                return $min;
            }
            else
            {
                return number[0];
            }
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getRandomSeries
        //Function Nature: Returns a random series of integer
        //Argument Description: <startValue>,<endValue>,<except some integers(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getRandom(1,10));
        //Output:5
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.getRandom(1,10,[3,4,5]));
        //Output:7(will not include 3,4,5);
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getRandomSeries($min:int, $max:int, $count:int = -1, exceptArray:Array = null):Array
        {
            var series:Array = new Array();
            var dontInclude:Dictionary = new Dictionary(true);
            if (exceptArray)
            {
                var len:int = exceptArray.length;
                for (var i:int; i < len; i++)
                {
                    dontInclude[exceptArray[i]] = true;
                }
            }
            for (i = $min; i <= $max; i++)
            {
                if (dontInclude[i] != true)
                {
                    series.push(i)
                }
            }
            if ($count != -1)
            {
                var filteredSeries:Array = new Array();
                for (i = 0; i < $count; i++)
                {
                    var ran:Number = Math.floor(Math.random() * series.length);
                    var num:Number = series.splice(ran, 1);
                    filteredSeries.push(num[0]);
                }
                return filteredSeries;
            }
            else
            {
                return series;
            }
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getSeries
        //Function Nature: Returns a arithmetic series between the given limits
        //Argument Description: <startValue>,<endValue>,<difference(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getSeries(5,10));
        //Output:5,6,7,8,9,10
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.getSeries(5,10,2));
        //Output:5,7,9
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getSeries($min:Number, $max:Number, $dif:Number = 1):Array
        {
            var series:Array = new Array();
            for (var i:int = $min; i <= $max; i = i + $dif)
            {
                series.push(i);
            }
            return series;
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getRandomElement
        //Function Nature: Returns a random element from an array
        //Argument Description: <array>,<remove(whether to remove that element or not)(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1:
        //var numArray:Array=[2,5,8,9,1]
        //trace(SuperMath.getRandomElement(numArray));
        //Output:8
        //trace(numArray)
        //Output:2,5,8,9,1
        //-------------------------------------------------------------------------------------------------------------------------//
        //var numArray:Array=[2,5,8,9,1]
        //trace(SuperMath.getRandomElement(numArray,true));
        //Output:8
        //trace(numArray)
        //Output:2,5,9,1(8 will be removed);
        //-------------------------------------------------------------------------------------------------------------------------//
        private static function getRandomElement(arr:Array, remove:Boolean = false):*
        {
            var len:int = arr.length;
            var ran:int = Math.floor(Math.random() * len);
            var element:* = arr[ran];
            if (remove)
            {
                arr.splice(ran, 1);
            }
            return element;
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getPrimeList
        //Function Nature: Returns a prime series between the given limits
        //Argument Description: <startValue>,<endValue>,<number of primes you needed>,<randomised series or not(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getPrimeList(5,20));
        //Output:5,7,11,13,17,19
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.getPrimeList(5,20,2));
        //Output:5,7(first two)
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 3: trace(SuperMath.getPrimeList(5,20,2,true));
        //Output:13,7(any two)
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getPrimeList($min:int, $max:int, $count:int = -1, randomised:Boolean = false):Array
        {
            var series:Array = [];
            for (var i:int = $min; i <= $max; i++)
            {
                if (isPrime(i))
                {
                    series.push(i);
                }
            }
            if ($count != -1)
            {
                var filteredSeries:Array = new Array();
                var ran:int
                for (i = 0; i < $count; i++)
                {
                    if (randomised)
                    {
                        ran = Math.floor(Math.random() * series.length);
                    }
                    else
                    {
                        ran = i;
                    }
                    var num:* = series.splice(ran, 1);
                    filteredSeries.push(num[0])
                }
                return filteredSeries;
            }
            else
            {
                return series;
            }
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getCompositeList
        //Function Nature: Returns a composite series between the given limits
        //Argument Description: <startValue>,<endValue>,<number of composites you needed>,<randomised series or not(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getCompositeList(5,20));
        //Output:6,8,10,12,14,15,16,18.20
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.getCompositeList(5,20,3));
        //Output:6,8,10(first three)
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 3: trace(SuperMath.getCompositeList(5,20,3,true));
        //Output:14,7,8(any three)
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getCompositeList($min:int, $max:int, $count:int = -1, randomised:Boolean = false):Array
        {
            var series:Array = [];
            for (var i:int = $min; i <= $max; i++)
            {
                if (!isPrime(i))
                {
                    series.push(i);
                }
            }
            if ($count != -1)
            {
                var filteredSeries:Array = new Array();
                var ran:int
                for (i = 0; i < $count; i++)
                {
                    if (randomised)
                    {
                        ran = Math.floor(Math.random() * series.length);
                    }
                    else
                    {
                        ran = i;
                    }
                    var num:* = series.splice(ran, 1);
                    filteredSeries.push(num[0])
                }
                return filteredSeries;
            }
            else
            {
                return series;
            }
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getPrimeFactors
        //Function Nature: Returns a prime factors of a given number
        //Argument Description: <number>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getPrimeFactors(36));
        //Output:2,3
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.getPrimeFactors(100));
        //Output:2,5
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getPrimeFactors($num:Number):Array
        {
            var factorArray:Array = [];
            if ($num == 2)
            {
                factorArray = [2];
                return factorArray;
            }
            else
            {
                if ($num == 1)
                {
                    return factorArray;
                }
                else
                {
                    for (var i:int = 2; i <= $num; i++)
                    {
                        if ($num % i == 0 && isPrime(i))
                        {
                            factorArray.push(i);
                        }
                    }
                    return factorArray;
                }
            }
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getFactors
        //Function Nature: Returns a all factors of a given number
        //Argument Description: <number>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getFactors(36));
        //Output:1,2,3,6,12,18,36
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getFactors($num:Number):Array
        {
            var factorArray:Array = [];

            for (var i:int = 1; i <= $num; i++)
            {
                if ($num % i == 0)
                {
                    factorArray.push(i);
                }
            }
            return factorArray;

        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getGCD
        //Function Nature: Returns GCD of two given numbers
        //Argument Description: <number1>,<number2>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getGCD(10,15));
        //Output:5
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getGCD(a:int, b:int):int
        {
            if ((a < 0) || (b < 0))
            {
                return getGCD(Math.abs(a), Math.abs(b));
            }
            if (a < b)
            {
                return getGCD(b, a);
            }
            if (b == 0)
            {
                return a;
            }
            return getGCD(b, a % b);
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getLCM
        //Function Nature: Returns LCM of two given numbers
        //Argument Description: <number1>,<number2>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getLCM(10,15));
        //Output:30
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getLCM(a:int, b:int):int
        {
            return (a * b) / getGCD(a, b);
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:getCommonMultiples
        //Function Nature: Returns series of commmon multiples of two given numbers
        //Argument Description: <number1>,<number2>,<number of multiples(optional)>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.getCommonMultiples(10,15,7));
        //Output:30,60,90,120,150,180,210
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function getCommonMultiples(a:int, b:int, cnt:int = 1):Array
        {
            return getSeries(getLCM(a, b), getLCM(a, b) * (cnt - 1), getLCM(a, b));
        }

        //-------------------------------------------------------------------------------------------------------------------------//
        //Function Name:isPrime
        //Function Nature: Checks whether the given number is prime or not.
        //Argument Description: <number>
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 1: trace(SuperMath.isPrime(10));
        //Output:false
        //-------------------------------------------------------------------------------------------------------------------------//
        //Example 2: trace(SuperMath.isPrime(23));
        //Output:true
        //-------------------------------------------------------------------------------------------------------------------------//
        public static function isPrime($num:Number):Boolean
        {
            if ($num == 2)
            {
                return true;
            }
            else
            {
                if ($num == 1)
                {
                    return false;
                }
                else
                {
                    for (var i:int = 2; i < $num; i++)
                    {
                        if ($num % i == 0)
                        {
                            return false;
                        }
                    }
                    return true;
                }
            }
        }
    }
}
