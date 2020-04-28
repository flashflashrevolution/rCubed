package scripts
{
    import flash.display.BitmapData;
    import flash.geom.Rectangle;
    import flash.display.Sprite;

    public function drawIntoSprite(sprite:Sprite, bmp:BitmapData, grid:Rectangle):void
    {
        var gridX:Array = [grid.left, grid.right, bmp.width];
        var gridY:Array = [grid.top, grid.bottom, bmp.height];

        sprite.graphics.clear();

        var left:Number = 0;
        for (var i:int = 0; i < 3; i++)
        {
            var top:Number = 0;
            for (var j:int = 0; j < 3; j++)
            {
                sprite.graphics.beginBitmapFill(bmp, null, false);
                sprite.graphics.drawRect(left, top, gridX[i] - left, gridY[j] - top);
                sprite.graphics.endFill();
                top = gridY[j];
            }
            left = gridX[i];
        }
        sprite.scale9Grid = grid;
    }
}
