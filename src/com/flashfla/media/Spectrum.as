/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.media {
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.SoundMixer;
	import flash.utils.ByteArray;
	
	public class Spectrum extends Sprite {
		private var _width:int = 850;
		private var _height:int = 150;
		
		public function Spectrum(w:int = 850, h:int = 150):void {
			this._width = w;
			this._height = h;
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function addListeners():void {
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function removeListeners():void {
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(event:Event):void {
			var bytes:ByteArray = new ByteArray();
			const CHANNEL_LENGTH:int = 256;
			var nodeGAP = this._width / CHANNEL_LENGTH;
			
			SoundMixer.computeSpectrum(bytes);
			
			var g:Graphics = this.graphics;
			
			g.clear();
			
			g.lineStyle(0, 0x6600CC);
			g.beginFill(0x6600CC);
			g.moveTo(0, this._height);
			
			var n:Number = 0;
			
			for (var i:int = 0; i < CHANNEL_LENGTH; i++) {
				n = (bytes.readFloat() * this._height);
				g.lineTo(i * nodeGAP, this._height - n);
			}
			
			g.lineTo(CHANNEL_LENGTH * nodeGAP, this._height);
			g.endFill();
			
			g.lineStyle(0, 0xCC0066);
			g.beginFill(0xCC0066, 0.5);
			g.moveTo(CHANNEL_LENGTH * nodeGAP, this._height);
			
			for (i = CHANNEL_LENGTH; i > 0; i--) {
				n = (bytes.readFloat() * this._height);
				g.lineTo(i * nodeGAP, this._height - n);
			}
			
			g.lineTo(0, this._height);
			g.endFill();
		}
	}
}
