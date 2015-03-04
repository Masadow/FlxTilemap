package states;

import coffeegames.mapgen.MapAlign;
import coffeegames.mapgen.MapGenerator;
import experimental.IsoUtils;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import tile.FlxIsoTilemap;
import tile.Astar;

/**
 * A FlxState which can be used for the game's menu.
 */
class Generator extends FlxState
{
	//Set this to true to debug map culling
	static inline var CULLING_DEBUG:Bool = false;
	
	var mapGen:MapGenerator;
	var mapHeight:Int;
	var mapWidth:Int;
	var map:FlxIsoTilemap;
	var initial:flixel.math.FlxPoint;
	var final:flixel.math.FlxPoint;
	var player:Player;
	var cursor:FlxIsoSprite;
	var text:String;
	var instructions:FlxText;
	
	var uiCam:FlxCamera;
	var mapCam:flixel.FlxCamera;
	var isZooming:Bool;
	var minimap:Bitmap;
	var aStar:Astar;
	
	var timer:FlxTimer;
	var info:flixel.text.FlxText;
	
	var wPos:FlxPoint;
	var infoTxt:String;
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		super.create();
		
		#if cpp
		cpp.vm.Profiler.start('log.txt');
		#end
		
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
		
		FlxG.log.redirectTraces = false;
		//FlxG.debugger.drawDebug = true;
		
		isZooming = false;
		
		//Map generator pre-defined sizes
/*		mapWidth = 100;
		mapHeight = 100;*/
		
		mapWidth = 350;
		mapHeight = 235;

		//Works!
/*		mapWidth = 1000;
		mapHeight = 1000;*/
		
		timer = new FlxTimer();
		wPos = FlxPoint.get(0, 0);
		
		//Map camera
		mapCam = new FlxCamera(0, 0, 1280, 720, 1);
		FlxG.cameras.add(mapCam);
		
		//User interface camera
		uiCam = new FlxCamera(0, 0, 1280, 720, 1);
		uiCam.bgColor = 0x0000000;
		FlxG.cameras.add(uiCam);
		
		//Create the map and the player
		createMap();
		
		//Creates all user interface elements
		createUI();
		
		//Map mouse / touch scrolling helpers
		initial = FlxPoint.get(0, 0);
		final = FlxPoint.get(0, 0);
		
		//Cursor to show mouse click position
		cursor = new FlxIsoSprite(0, 0);
		cursor.set_camera(mapCam);
		cursor.loadGraphic("images/iso_64_32_b.png", true, 64, 96);
		cursor.animation.add("idle", [18], 12);
		cursor.animation.play("idle");
		cursor.ignoreDrawDebug = true;
		add(cursor);
	}
	
	function createMap()
	{
		//Initializing map generator
		mapGen = new MapGenerator(mapWidth, mapHeight, 3, 5, 11, false);
		mapGen.setIndices(9, 8, 10, 11, 14, 16, 17, 15, 7, 5, 1, 1, 0);
		mapGen.generate();
		
		//Shows the minimap
		minimap = mapGen.showMinimap(FlxG.stage, 3, MapAlign.TopLeft);
		FlxG.addChildBelowMouse(minimap);
		minimap.x -minimap.width;
		minimap.visible = false;
		mapGen.showColorCodes();
		
		//Getting data from generator
		var mapData:Array<Array<Int>> = mapGen.extractData();
		
		//Isometric tilemap
		if (CULLING_DEBUG)
			map = new FlxIsoTilemap(new Rectangle(128, 128, 1024, 464));
		else
			map = new FlxIsoTilemap(new Rectangle(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight));
		
		//TODO: Make it setable through the constructor
		map.tileDepth = 32;
		
		//Old tileset, walls had ground tiles drawn in their frames to account for only one tile layer
		//map.loadMapFrom2DArray(mapData, "images/tileset_64.png", 64, 64, FlxTilemapAutoTiling.OFF, 0, 0, 1);
		
		//Tileset without ground tiles drawn in the walls (only works with layers)
		map.loadMapFrom2DArray(mapData, "images/tileset_64_exp.png", 64, 64, FlxTilemapAutoTiling.OFF, 0, 0, 1);
		map.adjustTiles();
		
		//Layer setup
		//Static layer
		var tileRange = [0, 1, 2];
		var groundLayer = map.createLayerFromTileArray(tileRange, 0, 1);
		map.addLayer(groundLayer);
		//Dynamic layer
		tileRange = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
		var midLayer = map.createLayerFromTileArray(tileRange, 1, -1);
		map.addLayer(midLayer);
		
		aStar = new Astar(IsoUtils.convertToInt(map.getLayerAt(1).data), false, false);
		aStar.walkableTiles = [ -1, 0, 1, 5, 6, 7, 18];
		aStar.debug = true;
		
		map.setTileProperties(0, FlxObject.NONE, onMapCollide, null, 8);
		map.setTileProperties(8, FlxObject.NONE, onMapCollide, null, 8);
		map.setTileProperties(16, FlxObject.ANY, onMapCollide, null, 2);
		
		map.cameras = [mapCam];
		#if debug
		map.ignoreDrawDebug = true;
		#end
		add(map);
		
		//Adding player to map
		player = new Player(0, 0);
		player.ID = 10;
		player.set_camera(mapCam);
		map.add(player, 1);
		//Setting player position
		var initialTile = map.getIsoTileByMapCoords(1, 1);
		player.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
	}
	
	function createUI()
	{
		if (CULLING_DEBUG) {
			var frame = new FlxObject(128, 128, 1024, 464);
			#if debug
			frame.debugBoundingBoxColor = 0xFFFFFF;
			#end
			frame.set_camera(uiCam);
			add(frame);
			
			var scrCenterX = new FlxObject(639, 128, 2, 463);
			#if debug
			scrCenterX.debugBoundingBoxColor = 0xFFFFFF;
			#end
			scrCenterX.set_camera(uiCam);
			add(scrCenterX);
			
			var scrCenterY = new FlxObject(128, 359, 1024, 2);
			#if debug
			scrCenterY.debugBoundingBoxColor = 0xFFFFFF;
			#end
			scrCenterY.set_camera(uiCam);
			add(scrCenterY);
			
			var frameColor = 0xDD666666;
			//var frameColor = 0xFF666666;
			var top = new FlxSprite(0, 0);
			top.makeGraphic(1280, 128, frameColor);
			#if debug
			top.ignoreDrawDebug = true;
			#end
			top.set_camera(uiCam);
			add(top);
			
			var bottom = new FlxSprite(0, 592);
			bottom.makeGraphic(1280, 128, frameColor);
			#if debug
			bottom.ignoreDrawDebug = true;
			#end
			bottom.set_camera(uiCam);
			add(bottom);
			
			var left = new FlxSprite(0, 128);
			left.makeGraphic(128, 464, frameColor);
			#if debug
			left.ignoreDrawDebug = true;
			#end
			left.set_camera(uiCam);
			add(left);
			
			var right = new FlxSprite(1152, 128);
			right.makeGraphic(128, 464, frameColor);
			#if debug
			right.ignoreDrawDebug = true;
			#end
			right.set_camera(uiCam);
			add(right);
		}
		
		//Adding instruction label
		text = '';
		#if (flash || desktop)
		text = 'MAP SIZE - ${map.widthInTiles},${map.heightInTiles}\nARROWS - Move player | WASD - Scroll map\nSPACE - reset | ENTER - Spawn chars\nTAB - Toggle minimap | ZOOM : 1';
		#elseif html5
		text = 'MAP SIZE - ${map.widthInTiles},${map.heightInTiles} | ARROWS - Move player | WASD - Scroll map | SPACE - reset | ENTER - Spawn chars | TAB - Toggle minimap | PgUp / PgDown -> ZOOM : 1';
		#elseif (ios || android)
		text = 'MAP SIZE - ${map.widthInTiles},${map.heightInTiles}\nTOUCH AND DRAG - Scroll Map | TOUCH MAP - Move char to map position\nTAB - Toggle minimap | ZOOM : 1';
		#end
		var textPos = 10;
		//var textWidth = 1280 - minimap.width - 30;
		var textWidth = 1280 - 30;
		instructions = new FlxText(textPos, 10, textWidth, text, 14);
		instructions.scrollFactor.set(0, 0);
		instructions.setBorderStyle(FlxTextBorderStyle.OUTLINE_FAST, 0x666666);
		instructions.set_camera(uiCam);
		#if debug
		instructions.ignoreDrawDebug = true;
		#end
		add(instructions);
		
		var infoWidth = 400;
		infoTxt = 'Cursor\nTile : 0, 0\nWorld : 0, 0\nMouse : 0, 0';
		info = new FlxText(1270 - infoWidth, 10, infoWidth, infoTxt, 14);
		info.scrollFactor.set(0, 0);
		info.setBorderStyle(FlxTextBorderStyle.OUTLINE_FAST, 0x666666);
		info.alignment = FlxTextAlign.RIGHT;
		info.set_camera(uiCam);
		#if debug
		info.ignoreDrawDebug = true;
		#end
		add(info);
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
		
		// ### TODO: Test / make collision work
/*		FlxG.collide(map, map.spriteGroup, onMapCollide);
		map.overlaps(map.spriteGroup);*/
		
		#if cpp
		if (FlxG.keys.justPressed.F8) {
			cpp.vm.Profiler.stop();
			openfl.Lib.exit();
		}
		#end
		
		handleInput(elapsed);
		handleTouchInput(elapsed);
		
	}
	
	function handleInput(elapsed:Float)
	{
		//Scrolls the map
		if (FlxG.keys.pressed.A)
			mapCam.scroll.x -= 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.D)
			mapCam.scroll.x += 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.W)
			mapCam.scroll.y -= 300 * FlxG.elapsed;
		if (FlxG.keys.pressed.S)
			mapCam.scroll.y += 300 * FlxG.elapsed;
		
		//Restart the demo
		if (FlxG.keys.justPressed.SPACE) {
			FlxG.resetState();
		}
		
		if (FlxG.keys.justPressed.TAB) {
			if (minimap.visible) {
				FlxTween.tween(instructions, { x: 10 }, 0.3, { type:FlxTween.ONESHOT, ease:FlxEase.quadOut});
				FlxTween.tween(minimap, { x: -minimap.width }, 0.3, { type:FlxTween.ONESHOT, ease:FlxEase.quadOut, onComplete:function (t:FlxTween) {
					minimap.visible = false;
				}});
			} else {
				minimap.visible = true;
				FlxTween.tween(instructions, { x: minimap.width + 20 }, 0.3, { type:FlxTween.ONESHOT, ease:FlxEase.quadOut});
				FlxTween.tween(minimap, { x: 10 }, 0.3, { type:FlxTween.ONESHOT, ease:FlxEase.quadOut } );
			}
		}
		
		//Adds 10 automatons
		if (FlxG.keys.justPressed.ENTER) {
			for (i in 0...10)
			{
				var automaton = new Automaton(0, 0);
				map.add(automaton, 1);
				var initialTile = player.isoContainer;
				automaton.setPosition(initialTile.isoPos.x, initialTile.isoPos.y);
			}
		}
		
		#if html5
		//Camera zoom in
		if (FlxG.keys.justPressed.PAGEUP && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom + 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
			}} );
		}
		
		//Camera zoom out
		if (FlxG.keys.justPressed.PAGEDOWN && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom - 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
			}} );
		}
		#end
	}
	
	function handleTouchInput(elapsed:Float)
	{
		//Mouse drag start
		if (FlxG.mouse.justPressed) {
			//Get initial mouse press position
			initial = FlxG.mouse.getScreenPosition();
		}
		
		//Mouse drag end / click to move character
		if (FlxG.mouse.justReleased) {
			
			//Gets final mouse position after releasing press
			final = FlxG.mouse.getScreenPosition();
			
			//If initial and final click distance is small, consider it a click
			if (final.distanceTo(initial) < 2 && !player.isWalking) {
				
				//Mouse world position
				FlxG.mouse.getWorldPosition(mapCam, wPos);
				
				//var cPos = map.getIsoCoordsByPoint(map.getIsoPointByCoords(wPos));
				var tPos = map.getIsoPointByCoords(wPos);
				var cPos = map.getIsoCoordsByPoint(tPos);
				
				info.text = 'Cursor\nTile : ${tPos.x}, ${tPos.y}\nWorld : ${wPos.x}, ${wPos.y}\nCursor : ${cPos.x}, ${cPos.y}';
				
				cursor.x = cPos.x - cursor.width / 2;
				cursor.y = cPos.y - cursor.height / 2;
				
/*				//player.setPosition(cPos.x + player.width / 2, cPos.y + player.height / 2);
				var pHeightOffset = player.height / 6;
				player.setPosition(cPos.x, cPos.y + pHeightOffset);*/
				
				
				
				//Player target tile
				var tile = map.getIsoTileByCoords(wPos);
				
				if (tile == null) {
					trace('Tile is null, aborting');
					return;
				}
				
				//trace('Player -> Target tile position : ${tile.isoPos.x},${tile.isoPos.y} | Map : ${tile.mapPos.x},${tile.mapPos.y}');
				
				//TODO: Create a method to simplify using the Node typedef
				var current:Node = {x:player.isoContainer.mapPos.x, y:player.isoContainer.mapPos.y, name:'${player.isoContainer.mapPos.x}-${player.isoContainer.mapPos.y}', FCost:0, GCost:0, HCost:0, parent:null};
				var target:Node = { x:tile.mapPos.x, y:tile.mapPos.y, name:'${tile.mapPos.x}-${tile.mapPos.y}', FCost:0, GCost:0, HCost:0, parent:null };
				
				var path = aStar.findPath(current, target);
				
				if (path == null) {
					//trace('Could not find path between (${current.x},${current.y}) and (${target.x},${target.y}). Path is null!');
					return;
				}
					
				var ptArr = new Array<FlxPoint>();
				var originalTileIndices = [];
				for (i in 0...path.length) {
					var tile = map.getIsoTileByMapCoords(path[i].x, path[i].y);
					originalTileIndices.push(tile.index);
					map.setIsoTile(tile.mapPos.y, tile.mapPos.x, 18);
					ptArr.push(FlxPoint.get(tile.isoPos.x + player.width / 2, tile.isoPos.y + player.height / 1.5));
				}
				
				var count = 0;
				timer.start(0.2, function (t:FlxTimer) {
					var tile = map.getIsoTileByMapCoords(path[t.elapsedLoops - 1].x, path[t.elapsedLoops - 1].y);
					map.setIsoTile(tile.mapPos.y, tile.mapPos.x, originalTileIndices[count]);
					count++;
				}, path.length);
				
				//Walks directly to target
				player.walkPath(ptArr, 200);
				
				//Sets the player position directly (debugging purposes)
				//player.setPosition(tile.isoPos.x + player.width / 2, tile.isoPos.y + player.height / 2);
				//trace("Player actual position : " + player.isoContainer.toString());
			}
		}
		
		//Mouse drag to scroll camera
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
		
		//Camera zoom in
		if (FlxG.mouse.wheel > 0 && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom + 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
			}} );
		}
		
		//Camera zoom out
		if (FlxG.mouse.wheel < 0 && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom - 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
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