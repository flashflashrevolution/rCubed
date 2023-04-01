package com.flashfla.utils
{

    import classes.GameNote;

    public class GameNotePool
    {
        public var pool:Vector.<PoolObject>;

        public function GameNotePool()
        {
            pool = new Vector.<PoolObject>();
        }

        public function addObject(object:GameNote, mark:Boolean = true):GameNote
        {
            pool.push(new PoolObject(mark, object));
            return object;
        }

        public function unmarkObject(object:GameNote, mark:Boolean = false):void
        {
            for each (var item:PoolObject in pool)
            {
                if (item.value == object)
                {
                    item.mark = mark;
                }
            }
        }

        public function unmarkAll(mark:Boolean = false):void
        {
            for each (var item:PoolObject in pool)
                item.mark = mark;
        }

        public function getObject():GameNote
        {
            for each (var item:PoolObject in pool)
            {
                if (!item.mark)
                {
                    item.mark = true;
                    return item.value;
                }
            }
            return null;
        }
    }
}

import classes.GameNote;

internal class PoolObject
{
    public var mark:Boolean;
    public var value:GameNote;

    public function PoolObject(mark:Boolean, value:GameNote)
    {
        this.mark = mark;
        this.value = value;
    }
}
