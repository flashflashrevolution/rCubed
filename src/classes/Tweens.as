package classes
{

    public class Tweens
    {
        static public function linear(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            return change * elapsed_time / duration + begin;
        }

        static public function inQuad(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration;
            return change * Math.pow(elapsed_time, 2) + begin;
        }

        static public function outQuad(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration;
            return -change * elapsed_time * (elapsed_time - 2) + begin;
        }

        static public function inOutQuad(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration * 2;
            if (elapsed_time < 1)
                return change / 2 * Math.pow(elapsed_time, 2) + begin;
            else
                return -change / 2 * ((elapsed_time - 1) * (elapsed_time - 3) - 1) + begin;

        }

        static public function outInQuad(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outQuad(elapsed_time * 2, begin, change / 2, duration);
            else
                return inQuad((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);

        }

        static public function inCubic(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration;
            return change * Math.pow(elapsed_time, 3) + begin;
        }

        static public function outCubic(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration - 1;
            return change * (Math.pow(elapsed_time, 3) + 1) + begin;
        }

        static public function inOutCubic(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration * 2;
            if (elapsed_time < 1)
            {
                return change / 2 * elapsed_time * elapsed_time * elapsed_time + begin;
            }
            else
            {
                elapsed_time = elapsed_time - 2;
                return change / 2 * (elapsed_time * elapsed_time * elapsed_time + 2) + begin;
            }
        }

        static public function outInCubic(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outCubic(elapsed_time * 2, begin, change / 2, duration);
            else
                return inCubic((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);

        }

        static public function inQuart(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration;
            return change * Math.pow(elapsed_time, 4) + begin;
        }

        static public function outQuart(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration - 1;
            return -change * (Math.pow(elapsed_time, 4) - 1) + begin;
        }

        static public function inOutQuart(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration * 2;
            if (elapsed_time < 1)
            {
                return change / 2 * Math.pow(elapsed_time, 4) + begin;
            }
            else
            {
                elapsed_time = elapsed_time - 2;
                return -change / 2 * (Math.pow(elapsed_time, 4) - 2) + begin;
            }
        }

        static public function outInQuart(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outQuart(elapsed_time * 2, begin, change / 2, duration);
            else
                return inQuart((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);
        }

        static public function inQuint(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration;
            return change * Math.pow(elapsed_time, 5) + begin;
        }

        static public function outQuint(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration - 1;
            return change * (Math.pow(elapsed_time, 5) + 1) + begin;
        }

        static public function inOutQuint(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration * 2;
            if (elapsed_time < 1)
            {
                return change / 2 * Math.pow(elapsed_time, 5) + begin;
            }
            else
            {
                elapsed_time = elapsed_time - 2;
                return change / 2 * (Math.pow(elapsed_time, 5) + 2) + begin;
            }
        }

        static public function outInQuint(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outQuint(elapsed_time * 2, begin, change / 2, duration);
            else
                return inQuint((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);

        }

        static public function inSine(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            return -change * Math.cos(elapsed_time / duration * (Math.PI / 2)) + change + begin;
        }

        static public function outSine(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            return change * Math.sin(elapsed_time / duration * (Math.PI / 2)) + begin;
        }

        static public function inOutSine(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            return -change / 2 * (Math.cos(Math.PI * elapsed_time / duration) - 1) + begin;
        }

        static public function outInSine(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outSine(elapsed_time * 2, begin, change / 2, duration);
            else
                return inSine((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);

        }

        static public function inExpo(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time == 0)
                return begin;
            else
                return change * Math.pow(2, 10 * (elapsed_time / duration - 1)) + begin - change * 0.001;

        }

        static public function outExpo(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time == duration)
                return begin + change;
            else
                return change * 1.001 * (-Math.pow(2, -10 * elapsed_time / duration) + 1) + begin;

        }

        static public function inOutExpo(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time == 0)
            {
                return begin;
            }
            if (elapsed_time == duration)
            {
                return begin + change;
            }
            elapsed_time = elapsed_time / duration * 2;
            if (elapsed_time < 1)
            {
                return change / 2 * Math.pow(2, 10 * (elapsed_time - 1)) + begin - change * 0.0005;
            }
            else
            {
                elapsed_time = elapsed_time - 1;
                return change / 2 * 1.0005 * (-Math.pow(2, -10 * elapsed_time) + 2) + begin;
            }
        }

        static public function outInExpo(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outExpo(elapsed_time * 2, begin, change / 2, duration);
            else
                return inExpo((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);

        }

        static public function inCirc(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration;
            return (-change * (Math.sqrt(1 - Math.pow(elapsed_time, 2)) - 1) + begin);
        }

        static public function outCirc(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration - 1;
            return (change * Math.sqrt(1 - Math.pow(elapsed_time, 2)) + begin);
        }

        static public function inOutCirc(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration * 2;
            if (elapsed_time < 1)
            {
                return -change / 2 * (Math.sqrt(1 - elapsed_time * elapsed_time) - 1) + begin;
            }
            else
            {
                elapsed_time = elapsed_time - 2;
                return change / 2 * (Math.sqrt(1 - elapsed_time * elapsed_time) + 1) + begin;
            }
        }

        static public function outInCirc(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outCirc(elapsed_time * 2, begin, change / 2, duration);
            else
                return inCirc((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);

        }

        static public function inElastic(elapsed_time:Number, begin:Number, change:Number, duration:Number, a:Number, p:Number = NaN):Number
        {
            if (elapsed_time == 0)
            {
                return begin;
            }

            elapsed_time = elapsed_time / duration;

            if (elapsed_time == 1)
            {
                return begin + change;
            }

            if (isNaN(p))
            {
                p = duration * 0.3;
            }

            var s:Number;

            if (!a || a < Math.abs(change))
            {
                a = change;
                s = p / 4;
            }
            else
            {
                s = p / (2 * Math.PI) * Math.asin(change / a);
            }

            elapsed_time = elapsed_time - 1;

            return -(a * Math.pow(2, 10 * elapsed_time) * Math.sin((elapsed_time * duration - s) * (2 * Math.PI) / p)) + begin;
        }

        static public function outElastic(elapsed_time:Number, begin:Number, change:Number, duration:Number, amplitude:Number = NaN, period:Number = NaN):Number
        {
            if (elapsed_time == 0)
            {
                return begin;
            }

            elapsed_time = elapsed_time / duration;

            if (elapsed_time == 1)
            {
                return begin + change;
            }

            if (isNaN(period))
            {
                period = duration * 0.3;
            }

            var s:Number;

            if (isNaN(amplitude) || amplitude < Math.abs(change))
            {
                amplitude = change;
                s = period / 4;
            }
            else
            {
                s = period / (2 * Math.PI) * Math.asin(change / amplitude);
            }

            return amplitude * Math.pow(2, -10 * elapsed_time) * Math.sin((elapsed_time * duration - s) * (2 * Math.PI) / period) + change + begin;
        }

        static public function inOutElastic(elapsed_time:Number, begin:Number, change:Number, duration:Number, amplitude:Number = NaN, period:Number = NaN):Number
        {
            if (elapsed_time == 0)
            {
                return begin;
            }

            elapsed_time = elapsed_time / duration * 2;

            if (elapsed_time == 2)
            {
                return begin + change;
            }

            if (isNaN(period))
            {
                period = duration * (0.3 * 1.5);
            }
            if (isNaN(amplitude))
            {
                amplitude = 0;
            }

            var s:Number;

            if (isNaN(amplitude) || amplitude < Math.abs(change))
            {
                amplitude = change;
                s = period / 4;
            }
            else
            {
                s = period / (2 * Math.PI) * Math.asin(change / amplitude);
            }

            if (elapsed_time < 1)
            {
                elapsed_time = elapsed_time - 1;
                return -0.5 * (amplitude * Math.pow(2, 10 * elapsed_time) * Math.sin((elapsed_time * duration - s) * (2 * Math.PI) / period)) + begin;
            }
            else
            {
                elapsed_time = elapsed_time - 1;
                return amplitude * Math.pow(2, -10 * elapsed_time) * Math.sin((elapsed_time * duration - s) * (2 * Math.PI) / period) * 0.5 + change + begin;
            }
        }

        static public function outInElastic(elapsed_time:Number, begin:Number, change:Number, duration:Number, amplitude:Number = NaN, period:Number = NaN):Number
        {
            if (elapsed_time < duration / 2)
                return outElastic(elapsed_time * 2, begin, change / 2, duration, amplitude, period);
            else
                return inElastic((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration, amplitude, period);
        }

        static public function inBack(elapsed_time:Number, begin:Number, change:Number, duration:Number, s:Number = 1.70158):Number
        {
            elapsed_time = elapsed_time / duration;
            return change * elapsed_time * elapsed_time * ((s + 1) * elapsed_time - s) + begin;
        }

        static public function outBack(elapsed_time:Number, begin:Number, change:Number, duration:Number, s:Number = 1.70158):Number
        {
            elapsed_time = elapsed_time / duration - 1;
            return change * (elapsed_time * elapsed_time * ((s + 1) * elapsed_time + s) + 1) + begin;
        }

        static public function inOutBack(elapsed_time:Number, begin:Number, change:Number, duration:Number, s:Number = 1.70158):Number
        {
            s = s * 1.525;
            elapsed_time = elapsed_time / duration * 2;
            if (elapsed_time < 1)
            {
                return change / 2 * (elapsed_time * elapsed_time * ((s + 1) * elapsed_time - s)) + begin;
            }
            else
            {
                elapsed_time = elapsed_time - 2;
                return change / 2 * (elapsed_time * elapsed_time * ((s + 1) * elapsed_time + s) + 2) + begin;
            }
        }

        static public function outInBack(elapsed_time:Number, begin:Number, change:Number, duration:Number, s:Number = 1.70158):Number
        {
            if (elapsed_time < duration / 2)
                return outBack(elapsed_time * 2, begin, change / 2, duration, s);
            else
                return inBack((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration, s);
        }

        static public function outBounce(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            elapsed_time = elapsed_time / duration;
            if (elapsed_time < 1 / 2.75)
            {
                return change * (7.5625 * elapsed_time * elapsed_time) + begin;
            }
            else if (elapsed_time < 2 / 2.75)
            {
                elapsed_time = elapsed_time - (1.5 / 2.75);
                return change * (7.5625 * elapsed_time * elapsed_time + 0.75) + begin;
            }
            else if (elapsed_time < 2.5 / 2.75)
            {
                elapsed_time = elapsed_time - (2.25 / 2.75);
                return change * (7.5625 * elapsed_time * elapsed_time + 0.9375) + begin;
            }
            else
            {
                elapsed_time = elapsed_time - (2.625 / 2.75);
                return change * (7.5625 * elapsed_time * elapsed_time + 0.984375) + begin;
            }
        }

        static public function inBounce(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            return change - outBounce(duration - elapsed_time, 0, change, duration) + begin;
        }

        static public function inOutBounce(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return inBounce(elapsed_time * 2, 0, change, duration) * 0.5 + begin;
            else
                return outBounce(elapsed_time * 2 - duration, 0, change, duration) * 0.5 + change * 0.5 + begin;
        }

        static public function outInBounce(elapsed_time:Number, begin:Number, change:Number, duration:Number):Number
        {
            if (elapsed_time < duration / 2)
                return outBounce(elapsed_time * 2, begin, change / 2, duration);
            else
                return inBounce((elapsed_time * 2) - duration, begin + change / 2, change / 2, duration);
        }
    }
}
