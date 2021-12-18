package classes.ui
{
    import flash.display.Sprite;
    import assets.menu.icons.fa.*;

    public class IconUtil
    {
        public static function getIcon(name:String):Sprite
        {
            switch (name)
            {
                case "iconPlay":
                    return new iconPlay();
                case "iconFilter":
                    return new iconFilter();
                case "iconAward":
                    return new iconAward();
                case "iconClose":
                    return new iconClose();
                case "iconCopy":
                    return new iconCopy();
                case "iconDelete":
                    return new iconDelete();
                case "iconFilm":
                    return new iconFilm();
                case "iconFilter":
                    return new iconFilter();
                case "iconFolder":
                    return new iconFolder();
                case "iconGear":
                    return new iconGear();
                case "iconHeartEmpty":
                    return new iconHeartEmpty();
                case "iconHeartFull":
                    return new iconHeartFull();
                case "iconLeft":
                    return new iconLeft();
                case "iconList":
                    return new iconList();
                case "iconMap":
                    return new iconMap();
                case "iconMedal":
                    return new iconMedal();
                case "iconMinus":
                    return new iconMinus();
                case "iconMusic":
                    return new iconMusic();
                case "iconPause":
                    return new iconPause();
                case "iconPhoto":
                    return new iconPhoto();
                case "iconPlay":
                    return new iconPlay();
                case "iconPlus":
                    return new iconPlus();
                case "iconRandom":
                    return new iconRandom();
                case "iconRecord":
                    return new iconRecord();
                case "iconRefresh":
                    return new iconRefresh();
                case "iconRight":
                    return new iconRight();
                case "iconSave":
                    return new iconSave();
                case "iconSearch":
                    return new iconSearch();
                case "iconSpeed":
                    return new iconSpeed();
                case "iconStar":
                    return new iconStar();
                case "iconStop":
                    return new iconStop();
                case "iconTime":
                    return new iconTime();
                case "iconTrophy":
                    return new iconTrophy();
                case "iconUpLevel":
                    return new iconUpLevel();
                case "iconUsers":
                    return new iconUsers();
                case "iconVideo":
                    return new iconVideo();
            }
            return null;
        }
    }
}
