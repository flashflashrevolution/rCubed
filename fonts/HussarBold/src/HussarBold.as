package
{
    import flash.display.Sprite;

    public class HussarBold extends Sprite
    {
        [Embed(source = '../assets/Hussar-Italic.ttf', fontFamily = 'Hussar Italic', fontStyle = 'normal', fontWeight = 'normal', mimeType = "application/x-font", advancedAntiAliasing = true, embedAsCFF = false)]
        public static var Italic:Class;

        [Embed(source = '../assets/Hussar-Regular.ttf', fontFamily = 'Hussar Regular', fontStyle = 'normal', fontWeight = 'normal', mimeType = "application/x-font", advancedAntiAliasing = true, embedAsCFF = false)]
        public static var Regular:Class;
    }

}
