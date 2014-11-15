package;

import coffeegames.mapgen.MapAlign;
import coffeegames.mapgen.MapGenerator;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import tile.FlxIsoTilemap;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{
	var mapGen:MapGenerator;
	var mapHeight:Int;
	var mapWidth:Int;
	var map:FlxIsoTilemap;
	var initial:flixel.math.FlxPoint;
	var final:flixel.math.FlxPoint;
	var isPressed:Bool;
	var charA:FlxIsoSprite;
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		super.create();
		
		FlxG.log.redirectTraces = false;
		FlxG.debugger.drawDebug = false;
		
		//Map generator
		mapWidth = 32;
		mapHeight = 32;
		
/*		mapWidth = 42;
		mapHeight = 42;*/
		
/*		mapWidth = 65;
		mapHeight = 65;*/
		
		mapGen = new MapGenerator(mapWidth, mapHeight, 3, 5, 11, false);
		mapGen.setIndices(9, 8, 10, 11, 14, 16, 17, 15, 7, 5, 1, 1, 0);
		mapGen.generate();
		
		//Shows the minimap
		var minimap = mapGen.showMinimap(FlxG.stage, 3, MapAlign.TopLeft);
		FlxG.addChildBelowMouse(minimap);
		mapGen.showColorCodes();
		
		//Getting data from generator
		var mapData:Array<Array<Int>> = mapGen.extractData();
		
		//Isometric tilemap
		map = new FlxIsoTilemap();
		map._tileDepth = 24;
		map.loadMapFrom2DArray(mapData, "images/tileset.png", 48, 48, FlxTilemapAutoTiling.OFF, 0, 0, 1);
		map.adjustTiles();
		map.setTileProperties(2, FlxObject.ANY, onMapCollide, null, 16);
		map.camera.antialiasing = true;
		add(map);
		
		//Adding FlxIsoSprite to the map (WARNING: Currently working on Flash and HTML5 only!)
		charA = new FlxIsoSprite(0, 0, false);
		map.add(charA);
		var initialTile:IsoRect = map.getIsoRectAt(3 * mapWidth + 3);
		charA.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
		
		var text:String = "";
		#if (web || desktop)
		text = "ARROWS - Move player | WASD - Scroll map | SPACE - reset | ENTER - Spawn chars";
		#elseif (ios || android)
		text = "TOUCH AND DRAG - Scroll Map | TOUCH MAP - Move char to map position (Soon)";
		#end
		
		var textPos = minimap.x + minimap.width + 10;
		var textWidth = 1280 - minimap.width - 30;
		var instructions:FlxText = new FlxText(textPos, 10, textWidth, text, 14);
		instructions.scrollFactor.set(0, 0);
		add(instructions);
		
		initial = FlxPoint.get(0, 0);
		final = FlxPoint.get(0, 0);
	}
	
	/**
	 * Function that is called when this state is destroyed - you might want to 
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		//TODO: Make collision work
		//FlxG.collide(map, map.spriteGroup, onMapCollide);
		//map.overlaps(map.spriteGroup);
		
		#if (desktop || web)
		handleInput(elapsed);
		#elseif (android || ios)
		handleTouchInput(elapsed);
		#end
	}
	
	function handleInput(elapsed:Float)
	{
		if (FlxG.keys.pressed.A)
			FlxG.camera.scroll.x -= 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.D)
			FlxG.camera.scroll.x += 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.W)
			FlxG.camera.scroll.y += 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.S)
			FlxG.camera.scroll.y -= 300 * FlxG.elapsed;
			
		if (FlxG.keys.justPressed.SPACE) {
			FlxG.resetState();
		}
		
		if (FlxG.keys.justPressed.ENTER) {
			//Adds 10 automatons
			for (i in 0...10)
			{
				var char = new FlxIsoSprite(0, 0, true);
				var startRow:Int = Std.int(mapHeight / 2);
				var startCol:Int = Std.int(mapWidth / 2);
				var initialTile:IsoRect = map.getIsoRectAt(startRow * startCol);
				char.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
				map.add(char);
			}
		}
		
		//Debug logging (neko || cpp)
		if (FlxG.keys.justPressed.T) {
			var log:String = "";
			var rects:Array<IsoRect> = map._rects.copy();
			var numRects:Int = rects.length;
			for (i in 0...numRects)
			{
				var rect:IsoRect = rects[i];
				log += "rect '" + i + "'\tisoPos : " + rect.isoPos.toString() + "\t| depth : " +
					rect.depth + "\t| onScreen : " + rect.x + "," + rect.y + " \t| rect : " + rect.toString() + "\n";
			}
			#if (neko || cpp)
			sys.io.File.saveContent("./log.txt", log);
			#else
			trace(log);
			#end
		}
	}
	
	function handleTouchInput(elapsed:Float)
	{
		if (FlxG.mouse.justPressed) {
			initial = FlxG.mouse.getScreenPosition();
		}
		
		if (FlxG.mouse.justReleased) {
			final = FlxG.mouse.getScreenPosition();
			if (final.distanceTo(initial) < 2) {
				//Move char to tile
				trace("Will move char to tile with index '" + map.getTileIndexByCoords(FlxG.mouse.getWorldPosition()) + "'");
				
				//TODO: Modify FlxIsoSprite to allow the 'setDestination' method to receive a tile (or point)
			}
		}
		
		if (FlxG.mouse.pressed) {
			var pt = FlxG.mouse.getScreenPosition();
			if (pt.x > initial.x) {
				var amount = pt.x - initial.x;
				FlxG.camera.scroll.x -= amount * elapsed;
			} else {
				var amount = initial.x - pt.x;
				FlxG.camera.scroll.x += amount * elapsed;
			}
				
			if (pt.y > initial.y) {
				var amount = pt.y - initial.y;
				FlxG.camera.scroll.y += amount * elapsed;
			} else {
				var amount = initial.y - pt.y;
				FlxG.camera.scroll.y -= amount * elapsed;
			}
		}
	}
	
	function onMapCollide(objA:Dynamic, objB:Dynamic):Void
	{
		if (objB.allowCollisions == FlxObject.ANY) {
			trace("Collided with wall tile");
		}
	}
}