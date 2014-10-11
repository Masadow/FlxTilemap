package coffeegames.mapgen;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.KeyboardEvent;
import flash.Lib;
import flash.ui.Keyboard;

/**
 * ...
 * @author Tiago Ling Alexandre
 */

class Main 
{
	var mapGen:MapGenerator;
	
	static function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// entry point
		var main:Main = new Main();
	}
	
	public function new() {
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyUp);
		
		init();
	}
	
	private function init():Void {
		mapGen = new MapGenerator(40, 20, 3, 5, 11, false);
		mapGen.setIndices(10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22);
		mapGen.showMinimap(Lib.current, 2, MapAlign.TopRight);
		mapGen.showColorCodes();
		
		var mapData:Array<Array<Int>> = mapGen.extractData();
		for (i in 0...mapData.length) {
			trace(mapData[i]);
		}
	}
	
	private function onKeyUp(e:KeyboardEvent):Void 
	{
		if (e.keyCode == Keyboard.SPACE) {
			mapGen.generate();
		}
		
		if (e.keyCode == Keyboard.ENTER) {
			mapGen.dispose(Lib.current);
			init();
		}
	}
	
}