package;

import coffeegames.mapgen.MapAlign;
import coffeegames.mapgen.MapGenerator;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.util.FlxPath;
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
	var player:Player;
	var cursor:flixel.FlxSprite;
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		super.create();
		
		FlxG.log.redirectTraces = false;
		FlxG.debugger.drawDebug = false;
		
		//Map generator pre-defined sizes
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
		//map.setTileProperties(2, FlxObject.ANY, onMapCollide, null, 16);
		map.setTileProperties(0, FlxObject.NONE, null, null, 18);
		map.camera.antialiasing = true;
		add(map);
		
		//Adding player to map
		player = new Player(0, 0);
		map.add(player);
		var initialTile:IsoContainer = map.getIsoContainerAt(3 * mapWidth + 3);
		player.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
		
		//Adding instruction label
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
		
		//Map mouse / touch scrolling helpers
		initial = FlxPoint.get(0, 0);
		final = FlxPoint.get(0, 0);
		
		cursor = new FlxSprite(0, 0);
		cursor.loadGraphic("images/cursor.png", true, 48, 72);
		add(cursor);
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
		
/*		#if (desktop || web)
		handleInput(elapsed);
		#elseif (android || ios)
		handleTouchInput(elapsed);
		#end*/
		
		handleInput(elapsed);
		handleTouchInput(elapsed);
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
				var automaton = new Automaton(0, 0);
				var startRow:Int = Std.int(mapHeight / 2);
				var startCol:Int = Std.int(mapWidth / 2);
				var initialTile:IsoContainer = map.getIsoContainerAt(startRow * startCol);
				automaton.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
				map.add(automaton);
			}
		}
		
		if (FlxG.keys.justPressed.E) {
			trace("Changed tile");
			//map.setIsoTile(1, 1, 0);
			
			//map.setTileByIndex(
		}
		
		//Debug logging (neko || cpp)
		if (FlxG.keys.justPressed.T) {
			var log:String = "";
			var rects:Array<IsoContainer> = map._isoContainers.copy();
			var numRects:Int = rects.length;
			for (i in 0...numRects)
			{
				var rect:IsoContainer = rects[i];
				log += "rect '" + i + "'\tisoPos : " + rect.isoPos.toString() + "\t| depth : " +
					rect.depth + "\n";
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
			if (final.distanceTo(initial) < 2 && !player.isWalking) {
				
				var wPos = FlxG.mouse.getWorldPosition();
				var tile = map.getIsoTileByCoords(wPos);
				trace("Mouse World Position -> '" + wPos + "' - in Tiles : " + tile.mapPos.x + "," + tile.mapPos.y);
				
				//findPath is returning null due to incorrect tile position calculations
				var pPos = FlxPoint.get(player.isoContainer.isoPos.x, player.isoContainer.isoPos.y);
				//var tPos = FlxPoint.get(tile.isoPos.x, tile.isoPos.y);
				//var tPos = FlxPoint.get(tile.isoPos.x + player.width / 2, tile.isoPos.y + player.height / 2);
				var tPos = FlxPoint.get(tile.isoPos.x + player.width / 2, tile.isoPos.y + player.height / 3);
				var points = map.findPath(pPos, tPos);
				trace( "points : " + points );
				
				for (i in 0...points.length) {
					var t = map.getIsoTileByCoords(points[i]);
					map.setIsoTile(Std.int(t.mapPos.y), Std.int(t.mapPos.x), 0);
					//trace("Tile Index : " + map.getTile(Std.int(t.mapPos.y), Std.int(t.mapPos.x)));
					//trace("Iso data Index : " + t.dataIndex);
				}
				
				player.walkPath(points, 100);
				//player.walkPath([tPos], 100);
				
				
				//Testing tile clicks - working
				var tile = map.getIsoTileByCoords(wPos);
				map.setIsoTile(Std.int(tile.mapPos.y), Std.int(tile.mapPos.x), 0);
				
				//Placing cursor over the selected tile (offseting for correct positioning)
				cursor.x = tile.isoPos.x - cursor.width / 2;
				cursor.y = tile.isoPos.y - cursor.height / 2;
			}
		}
		
/*		if (FlxG.mouse.pressed) {
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
		}*/
	}
	
	function onMapCollide(objA:Dynamic, objB:Dynamic):Void
	{
		if (objB.allowCollisions == FlxObject.ANY) {
			trace("Collided with wall tile");
		}
	}
}