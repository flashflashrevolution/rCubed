package classes
{
    import flash.utils.Dictionary;

    public class ImageCache
    {
        public static const ALIGN_MIDDLE:Number = 1;

        public static var cacheData:Dictionary = new Dictionary();

        public static function getImage(url:String, imageAlign:Number = 0, scaleWidth:Number = NaN, scaleHeight:Number = NaN):ImageCacheSprite
        {
            var cache:CacheData = cacheData[url];

            if (cache == null)
            {
                cache = new CacheData(url);
                cacheData[cache.url] = cache;
            }

            return new ImageCacheSprite(cache, imageAlign, scaleWidth, scaleHeight);
        }
    }
}

import classes.ImageCache;
import com.flashfla.utils.SpriteUtil;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.URLRequest;

internal class CacheData extends EventDispatcher
{
    public var url:String;
    public var data:BitmapData;

    private var _loader:Loader;

    public function CacheData(url:String):void
    {
        this.url = url;

        _loader = new Loader();
        _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_onLoad);
        _loader.load(new URLRequest(url));
    }

    private function e_onLoad(e:Event):void
    {
        _loader.removeEventListener(Event.COMPLETE, e_onLoad);
        data = (_loader.content as Bitmap).bitmapData;

        dispatchEvent(new Event(Event.COMPLETE));
    }

    public function getSprite():DisplayObject
    {
        return new Bitmap(data.clone());
    }
}

internal class ImageCacheSprite extends Sprite
{
    public var url:String;
    public var cache:CacheData;

    public var imageAlign:Number;
    public var scaleWidth:Number;
    public var scaleHeight:Number;

    private var useArea:Boolean;

    public function ImageCacheSprite(cache:CacheData, imageAlign:Number = 0, scaleWidth:Number = NaN, scaleHeight:Number = NaN):void
    {
        this.cache = cache;
        this.imageAlign = imageAlign;
        this.scaleWidth = scaleWidth;
        this.scaleHeight = scaleHeight;

        this.useArea = !isNaN(scaleWidth) && !isNaN(scaleHeight);

        if (cache.data != null)
            addImage();
        else
            cache.addEventListener(Event.COMPLETE, e_onComplete);
    }

    private function addImage():void
    {
        const spr:DisplayObject = cache.getSprite();

        if (useArea)
            SpriteUtil.scaleTo(spr, scaleWidth, scaleHeight);

        if (imageAlign == ImageCache.ALIGN_MIDDLE)
        {
            spr.x = -(scaleWidth >> 1);
            spr.y = -(scaleHeight >> 1);
        }

        if (useArea)
        {
            spr.x += (scaleWidth - spr.width) / 2;
            spr.y += (scaleHeight - spr.height) / 2;
        }

        addChild(spr);
    }

    private function e_onComplete(e:Event):void
    {
        cache.removeEventListener(Event.COMPLETE, e_onComplete);

        if (cache.data != null)
            addImage()
    }

    override public function get width():Number
    {
        return scaleWidth;
    }

    override public function get height():Number
    {
        return scaleHeight;
    }
}
