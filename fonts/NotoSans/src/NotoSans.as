package
{
    import flash.display.Sprite;

    public class NotoSans extends Sprite
    {
        // "U+4E00-U+62FF" // CJK Unified Ideographs (Part 1/4)
        // "U+6300-U+77FF" // CJK Unified Ideographs (Part 2/4)
        // "U+7800-U+8CFF" // CJK Unified Ideographs (Part 3/4)
        // "U+8D00-U+9FFF" // CJK Unified Ideographs (Part 4/4)

        // U+30A0-U+30FF // Katakana
        // U+3040-U+309F // Hiragana

        // "U+0020-U+007E" // Basic Latin
        // "U+00A0-U+00FF" // Latin-1 Supplement
        // "U+0100-U+017F" // Latin Extended-A
        // "U+0180-U+024F" // Latin Extended-B

        // "U+0400-U+04FF" // Cyrillic
        // "U+0500-U+052F" // Cyrillic Supplement

        [Embed(source = '../assets/NotoSans-CJK-Bold.ttc', fontFamily = 'Noto Sans CJK JP Bold', fontStyle = 'normal', fontWeight = 'bold', mimeType = "application/x-font", advancedAntiAliasing = true, embedAsCFF = false)]
        public static var CJKBold:Class;

        [Embed(source = '../assets/NotoSans-Bold.ttf', fontFamily = 'Noto Sans Bold', fontStyle = 'normal', fontWeight = 'bold', mimeType = "application/x-font", advancedAntiAliasing = true, embedAsCFF = false)]
        public static var Bold:Class;
    }
}
