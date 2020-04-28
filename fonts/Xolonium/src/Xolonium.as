package
{
    import flash.text.Font;
    import flash.display.Sprite;

    public class Xolonium extends Sprite
    {
        [Embed(source = '../assets/Xolonium-Regular.ttf', fontFamily = 'Xolonium Regular', fontStyle = 'normal', fontWeight = 'normal', mimeType = "application/x-font", advancedAntiAliasing = true, embedAsCFF = false)]
        public static var Regular:Class;

        [Embed(source = '../assets/Xolonium-Bold.ttf', fontFamily = 'Xolonium Bold', fontStyle = 'normal', fontWeight = 'normal', mimeType = "application/x-font", advancedAntiAliasing = true, embedAsCFF = false)]
        public static var Bold:Class;
    }

}
