package;

import coffeegames.mapgen.MapAlign;
import coffeegames.mapgen.MapGenerator;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
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
	var text:String;
	var instructions:FlxText;
	
	var uiCam:FlxCamera;
	var mapCam:flixel.FlxCamera;
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		super.create();
		
		FlxG.log.redirectTraces = false;
		FlxG.debugger.drawDebug = false;
		
		//Map generator pre-defined sizes
/*		mapWidth = 8;
		mapHeight = 16;*/
		
		mapWidth = 32;
		mapHeight = 32;
		
/*		mapWidth = 42;
		mapHeight = 42;*/
		
/*		mapWidth = 65;
		mapHeight = 65;*/
		
		mapCam = new FlxCamera(0, 0, 1280, 720, 1);
		FlxG.cameras.add(mapCam);
		
		uiCam = new FlxCamera(0, 0, 1280, 720, 1);
		uiCam.bgColor = 0x00000000;
		FlxG.cameras.add(uiCam);
		
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
		map.setTileProperties(0, FlxObject.NONE, onMapCollide, null, 2);
		map.setTileProperties(5, FlxObject.NONE, onMapCollide, null, 3);
		map.setTileProperties(8, FlxObject.ANY, onMapCollide, null, 10);
		map.cameras = [mapCam];
		map.cameras[0].antialiasing = true;
		add(map);
		
		//Adding player to map
		player = new Player(0, 0);
		player.set_camera(mapCam);
		map.add(player);
		var initialTile:IsoContainer = map.getIsoTileByMapCoords(3, 3);
		player.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
		
		//Adding instruction label
		text = "";
		#if (web || desktop)
		text = "ARROWS - Move player | WASD - Scroll map | SPACE - reset | ENTER - Spawn chars | ZOOM : 1";
		#elseif (ios || android)
		text = "TOUCH AND DRAG - Scroll Map | TOUCH MAP - Move char to map position | ZOOM : 1";
		#end
		var textPos = minimap.x + minimap.width + 10;
		var textWidth = 1280 - minimap.width - 30;
		instructions = new FlxText(textPos, 10, textWidth, text, 14);
		instructions.scrollFactor.set(0, 0);
		instructions.set_camera(uiCam);
		add(instructions);
		
		//Map mouse / touch scrolling helpers
		initial = FlxPoint.get(0, 0);
		final = FlxPoint.get(0, 0);
		
		cursor = new FlxSprite(0, 0);
		cursor.set_camera(mapCam);
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
		
		//TODO: Test / make collision work
/*		FlxG.collide(map, map.spriteGroup, onMapCollide);
		map.overlaps(map.spriteGroup);*/
		
		handleInput(elapsed);
		handleTouchInput(elapsed);
	}
	
	function handleInput(elapsed:Float)
	{
		if (FlxG.keys.pressed.A)
			mapCam.scroll.x -= 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.D)
			mapCam.scroll.x += 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.W)
			mapCam.scroll.y += 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.S)
			mapCam.scroll.y -= 300 * FlxG.elapsed;
			
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
				var initialTile:IsoContainer = map.getIsoTileByMapCoords(Std.int(mapHeight / 2), Std.int(mapWidth / 2));
				automaton.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
				map.add(automaton);
			}
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
				
				var wPos = FlxG.mouse.getWorldPosition(mapCam);
				var tile = map.getIsoTileByCoords(wPos);
				var tPos = FlxPoint.get(tile.isoPos.x + player.width / 2, tile.isoPos.y + player.height / 3);
				trace("Tile : " + tile.mapPos.x + "," + tile.mapPos.y + " - Coords : " + wPos.toString());
				
				//findPath is returning null due to incorrect tile position calculations (or acting weird)
/*				var pPos = FlxPoint.get(player.isoContainer.isoPos.x, player.isoContainer.isoPos.y);
				trace( "pPos : " + pPos );
				var points = map.findPath(pPos, tPos);
				trace( "points : " + points );
				
				if (points != null) {
					for (i in 0...points.length) {
						var t = map.getIsoTileByCoords(points[i]);
						map.setIsoTile(Std.int(t.mapPos.y), Std.int(t.mapPos.x), 0);
					}
					
					player.walkPath(points, 100);
				}*/
				
				//Walks directly to target
				player.walkPath([tPos], 100);
				
				//Testing tile clicks - working
				var tile = map.getIsoTileByCoords(wPos);
				map.setIsoTile(Std.int(tile.mapPos.y), Std.int(tile.mapPos.x), 0);
				
				//Placing cursor over the selected tile (offseting for correct positioning)
				cursor.x = tile.isoPos.x - cursor.width / 2;
				cursor.y = tile.isoPos.y - cursor.height / 2;
			}
		}
		
		if (FlxG.mouse.pressed) {
			var pt = FlxG.mouse.getScreenPosition();
			if (pt.x > initial.x) {
				var amount = pt.x - initial.x;
				mapCam.scroll.x -= 2 * amount * elapsed;
			} 
			
			if (pt.x < initial.x) {
				var amount = initial.x - pt.x;
				mapCam.scroll.x += 2 * amount * elapsed;
			}
				
			if (pt.y > initial.y) {
				var amount = pt.y - initial.y;
				mapCam.scroll.y -= 2 * amount * elapsed;
			} 
			
			if (pt.y < initial.y) {
				var amount = initial.y - pt.y;
				mapCam.scroll.y += 2 * amount * elapsed;
			}
		}
		
		if (FlxG.mouse.wheel > 0) {
			FlxTween.tween(mapCam, { zoom:mapCam.zoom + 0.2 }, 0.25, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = text + " | ZOOM : " + Std.string(mapCam.zoom).substr(0, 3);
			}} );
		}
		
		if (FlxG.mouse.wheel < 0) {
			FlxTween.tween(mapCam, { zoom:mapCam.zoom - 0.2 }, 0.25, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = text + " | ZOOM : " + Std.string(mapCam.zoom).substr(0, 3);
			}} );
		}
	}
	
	function onMapCollide(objA:Dynamic, objB:Dynamic):Void
	{
		if (objB.allowCollisions == FlxObject.ANY) {
			//trace("Collided with wall tile");
		}
	}
}