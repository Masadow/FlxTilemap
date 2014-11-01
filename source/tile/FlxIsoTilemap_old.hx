package tile;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.layer.DrawStackItem;
import flixel.system.layer.frames.FlxSpriteFrames;
import flixel.system.layer.Region;
import flixel.tile.FlxBaseTilemap.FlxBaseTilemap;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import flixel.util.loaders.CachedGraphics;
import flixel.util.loaders.TextureRegion;

@:bitmap("assets/images/tile/autotiles.png")	 class GraphicAuto    extends BitmapData {}
@:bitmap("assets/images/tile/autotiles_alt.png") class GraphicAutoAlt extends BitmapData {}

/**
 * This is a traditional tilemap display and collision class. It takes a string of comma-separated numbers and then associates
 * those values with tiles from the sheet you pass in. It also includes some handy static parsers that can convert
 * arrays or images into strings that can be loaded.
 */
class FlxIsoTilemap extends FlxBaseTilemap<FlxIsoTile>
{
	/** 
 	 * A helper buffer for calculating number of columns and rows when the game size changed
	 * We are only using its member functions that's why it is an empty instance
 	 */
 	private static var _helperBuffer:FlxIsoTilemapBuffer = Type.createEmptyInstance(FlxIsoTilemapBuffer);
	
	/**
	 * Helper variable for non-flash targets. Adjust it's value if you'll see tilemap tearing (empty pixels between tiles). To something like 1.02 or 1.03
	 */
	public var tileScaleHack:Float = 1.01;
	
	/**
	 * Changes the size of this tilemap. Default is (1, 1). 
	 * Anything other than the default is very slow with blitting!
	 */
	public var scale(default, null):FlxPoint;
	
	/**
	 * Rendering variables.
	 */
	public var region(default, null):Region;
	public var framesData(default, null):FlxSpriteFrames;
	public var cachedGraphics(default, set):CachedGraphics;
	
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	private var _flashPoint:Point;
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	private var _flashRect:IsoRect;
	/**
	 * Internal list of buffers, one for each camera, used for drawing the tilemaps.
	 */
	private var _buffers:Array<FlxIsoTilemapBuffer>;
	/**
	 * Internal representation of rectangles, one for each tile in the entire tilemap, used to speed up drawing.
	 */
	public var _rects:Array<IsoRect>;
	/**
	 * Internal, the width of a single tile.
	 */
	private var _tileWidth:Int = 0;
	/**
	 * Internal, the depth of a single tile.
	 */
	public var _tileDepth(default, default):Int = 0;
	
	/**
	 * Internal, the height of a single tile.
	 */
	private var _tileHeight:Int = 0;
	
	private var _scaledTileWidth:Float = 0;
	private var _scaledTileDepth:Float = 0;
	private var _scaledTileHeight:Float = 0;
	
	/**
	 * Group holding all sprites added to the map
	 */
	public var spriteGroup:FlxTypedGroup<FlxIsoSprite>;
	
	#if (FLX_RENDER_BLIT && !FLX_NO_DEBUG)
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugTileNotSolid:BitmapData;
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugTilePartial:BitmapData;
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugTileSolid:BitmapData;
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugRect:Rectangle;
	#end

	#if FLX_RENDER_TILE
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods. Used only in cpp
	 */
	private var _helperPoint:Point;
	/**
	 * Internal representation of rectangles (actually id of rectangle in tileSheet), one for each tile in the entire tilemap, used to speed up drawing.
	 */
	private var _rectIDs:Array<Int>;
	#end
	
	/**
	 * Internal helper point used for convenience inside drawTilemap()
	 */
	private var drawPt:Point;
	
	/**
	 * The tilemap constructor just initializes some basic variables.
	 */
	public function new()
	{
		super();
		
		drawPt = new Point(0, 0);
		
		_buffers = new Array<FlxIsoTilemapBuffer>();
		_flashPoint = new Point();
		
		#if FLX_RENDER_TILE
		_helperPoint = new Point();
		#end
		
		scale = new FlxCallbackPoint(setScaleXCallback, setScaleYCallback, setScaleXYCallback);
		scale.set(1, 1);
		
		spriteGroup = new FlxTypedGroup<FlxIsoSprite>();
		
		FlxG.signals.gameResized.add(onGameResize);
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		_flashPoint = null;
		_flashRect = null;
		var i:Int = 0;
		var l:Int;
		
		if (_tileObjects != null)
		{
			l = _tileObjects.length;
			
			for (i in 0...l)
			{
				_tileObjects[i].destroy();
			}
			
			_tileObjects = null;
		}
		
		if (_buffers != null)
		{
			i = 0;
			l = _buffers.length;
			
			for (i in 0...l)
			{
				_buffers[i].destroy();
			}
			
			_buffers = null;
		}
		
		_data = null;
		
		_rects = null;
		#if FLX_RENDER_BLIT
		#if !FLX_NO_DEBUG
		_debugRect = null;
		_debugTileNotSolid = null;
		_debugTilePartial = null;
		_debugTileSolid = null;
		#end
		#else
		_helperPoint = null;
		_rectIDs = null;
		#end
		
		framesData = null;
		cachedGraphics = null;
		region = null;
		
		// need to destroy FlxCallbackPoints
		scale = FlxDestroyUtil.destroy(scale);
		
		FlxG.signals.gameResized.remove(onGameResize);
		
		super.destroy();
	}
	
	override private function cacheGraphics(TileWidth:Int, TileHeight:Int, TileGraphic:Dynamic):Void 
	{
		// Figure out the size of the tiles
		cachedGraphics = FlxG.bitmap.add(TileGraphic);
		_tileWidth = TileWidth;
		
		if (_tileWidth <= 0)
		{
			_tileWidth = cachedGraphics.bitmap.height;
		}
		
		//_tileDepth = TileDepth; ->> Set directly by the user
		if (_tileDepth < 0)
		{
			_tileDepth = _tileWidth;
		}
		
		_tileHeight = TileHeight;
		
		if (_tileHeight <= 0)
		{
			_tileHeight = _tileWidth;
		}
		
		if (!Std.is(TileGraphic, TextureRegion))
		{
			region = new Region(0, 0, _tileWidth, (_tileDepth + _tileHeight));
			region.width = Std.int(cachedGraphics.bitmap.width / _tileWidth) * _tileWidth;
			region.height = Std.int(cachedGraphics.bitmap.height / (_tileDepth + _tileHeight)) * (_tileDepth + _tileHeight);
		}
		else
		{
			var spriteRegion:TextureRegion = cast TileGraphic;
			region = spriteRegion.region.clone();
			if (region.tileWidth > 0)
			{
				_tileWidth = region.tileWidth;
			}
			else
			{
				region.tileWidth = _tileWidth;
			}
			
			if (region.tileHeight > 0)
			{
				_tileHeight = region.tileWidth;
			}
			else
			{
				region.tileHeight = (_tileDepth + _tileHeight);
			}
		}
	}
	
	override private function initTileObjects(DrawIndex:Int, CollideIndex:Int):Void 
	{
		// Create some tile objects that we'll use for overlap checks (one for each tile)
		_tileObjects = new Array<FlxIsoTile>();
		
		var length:Int = region.numTiles;
		length += _startingIndex;
		
		for (i in 0...length)
		{
			_tileObjects[i] = new FlxIsoTile(this, i, _tileWidth, _tileDepth, _tileHeight, (i >= DrawIndex), (i >= CollideIndex) ? allowCollisions : FlxObject.NONE);
		}
		
		// Create debug tiles for rendering bounding boxes on demand
		#if (FLX_RENDER_BLIT && !FLX_NO_DEBUG)
		_debugTileNotSolid = makeDebugTile(FlxColor.BLUE);
		_debugTilePartial = makeDebugTile(FlxColor.PINK);
		_debugTileSolid = makeDebugTile(FlxColor.GREEN);
		#end
	}
	
	override private function computeDimensions():Void 
	{
		_scaledTileWidth = _tileWidth * scale.x;
		_scaledTileDepth = _tileDepth * scale.y;
		_scaledTileHeight = _tileHeight * scale.y;
		
		// Then go through and create the actual map
		width = widthInTiles * _scaledTileWidth;
		height = heightInTiles * (_scaledTileDepth + _scaledTileHeight);
	}
	
	override private function updateMap():Void 
	{
		_rects = new Array<IsoRect>();
		FlxArrayUtil.setLength(_rects, totalTiles);
		
		#if FLX_RENDER_BLIT
		#if !FLX_NO_DEBUG
		_debugRect = new Rectangle(0, 0, _tileWidth, (_tileDepth + _tileHeight));
		#end
		
		var i:Int = 0;
		while (i < totalTiles)
		{
			updateTile(i++);
		}
		#else
		updateFrameData();
		#end
	}
	
	/**
	 * Must be called after loadMap to set the values and initial
	 * position of the tiles` IsoRects.
	 */
	public function adjustTiles():Void
	{
		var row = 0;
		var column = 0;
		var rowIndex = 0;
		var columnIndex = 0;
		var _flashPoint = new Point(0, 0);
		
		while (row < heightInTiles)
		{
			columnIndex = rowIndex;
			column = 0;
			
			_flashPoint.x = heightInTiles * _scaledTileWidth / 2 - (_scaledTileWidth / 2 * (row + 1));
			_flashPoint.y = row * (_scaledTileDepth / 2);
			
			while (column < widthInTiles)
			{
				_flashPoint.x += _scaledTileWidth / 2;
				_flashPoint.y += _scaledTileDepth / 2;
				
				var rect = _rects[columnIndex];
				if (rect.depth == -1) {
					rect.setIso(_flashPoint.x, _flashPoint.y);
					rect.depth = Std.int(_flashPoint.y * rect.depthModifier + _flashPoint.x);
					rect.index = _data[columnIndex];
				}
				
				column++;
				columnIndex++;
			}
			
			_flashPoint.y += (_tileDepth + _tileHeight);
			
			rowIndex += widthInTiles;
			row++;
		}
	}
	
	/**
	 * Adds a FlxIsoSprite to be used in conjunction with this FlxIsoTilemap.
	 * The sprite will get sorted with the tiles and will be drawn according
	 * to its position inside the sorted array
	 * @param	Sprite	The FlxIsoSprite to be added to the map
	 */
	public function add(Sprite:FlxIsoSprite):Void
	{
		_rects.push(Sprite.isoRect);
		spriteGroup.add(Sprite);
		Sprite.cameras = [];
	}
	
	/**
	 * Sorts a range of tiles inside an array using the insertion sort algorithm.
	 * Adapted from the original code by
	 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
	 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
	 * @param	a		The array to be sorted
	 * @param	compare	The comparing function to be used
	 * @param	first	Starting index for the comparison
	 * @param	count	The length of items to be compared starting from 'first'
	 */
	private function sortRange(a:Array<IsoRect>, compare:IsoRect->IsoRect->Int, first:Int, count:Int)
	{
		var k = a.length;
		if (k > 1)
		{
			_insertionSort(a, first, count, compare);
		}
	}
	
	private function _insertionSort(a:Array<IsoRect>, first:Int, k:Int, cmp:IsoRect->IsoRect->Int)
	{
		for (i in first + 1...first + k)
		{
			var x = a[i];
			var j = i;
			while (j > first)
			{
				var y = a[j - 1];
				if (cmp(y, x) > 0)
				{
					a[j] = y;
					j--;
				}
				else
					break;
			}
			
			a[j] = x;
		}
	}
	
	/**
	 * Internal, simple function used to compare two values from an array
	 * Used by sortRange function
	 * @param	a	The first value to compare
	 * @param	b	The second value to compare
	 * @return		An int representing the difference between values a and b
	 */
	private function compareNumberRise(a:IsoRect, b:IsoRect):Int
	{
		return a.depth - b.depth;
	}
	
	override public function update(elapsed:Float):Void
	{
		sortRange(_rects, compareNumberRise, 0, _rects.length);
		
		super.update(elapsed);
		
		for (spr in spriteGroup.members)
		{
			spr.update(elapsed);
		}
	}
	
	#if !FLX_NO_DEBUG
	override public function drawDebugOnCamera(Camera:FlxCamera):Void
	{
		#if FLX_RENDER_TILE
		var buffer:FlxIsoTilemapBuffer = null;
		var l:Int = FlxG.cameras.list.length;
		
		for (i in 0...l)
		{
			if (FlxG.cameras.list[i] == Camera)
			{
				buffer = _buffers[i];
				break;
			}
		}
		
		if (buffer == null)	
		{
			return;
		}
		
		// Copied from getScreenXY()
		_helperPoint.x = Math.floor((x - Math.floor(Camera.scroll.x) * scrollFactor.x) * 5) / 5 + 0.1;
		_helperPoint.y = Math.floor((y - Math.floor(Camera.scroll.y) * scrollFactor.y) * 5) / 5 + 0.1;
		
		var tileID:Int;
		var debugColor:Int;
		var drawX:Float;
		var drawY:Float;
	
		// Copy tile images into the tile buffer
		// Modified from getScreenXY()
		_point.x = (Camera.scroll.x * scrollFactor.x) - x; 
		_point.y = (Camera.scroll.y * scrollFactor.y) - y;
		var screenXInTiles:Int = Math.floor(_point.x / _scaledTileWidth);
		var screenYInTiles:Int = Math.floor(_point.y / _scaledTileDepth);
		var screenRows:Int = buffer.rows;
		var screenColumns:Int = buffer.columns;
		
		// Bound the upper left corner
		if (screenXInTiles < 0)
		{
			screenXInTiles = 0;
		}
		if (screenXInTiles > widthInTiles - screenColumns)
		{
			screenXInTiles = widthInTiles - screenColumns;
		}
		if (screenYInTiles < 0)
		{
			screenYInTiles = 0;
		}
		if (screenYInTiles > heightInTiles - screenRows)
		{
			screenYInTiles = heightInTiles - screenRows;
		}
		
		var rowIndex:Int = screenYInTiles * widthInTiles + screenXInTiles;
		_flashPoint.y = 0;
		var row:Int = 0;
		var column:Int;
		var columnIndex:Int;
		var tile:FlxIsoTile;
		var debugTile:BitmapData;
		
		var totalRects:Int = _rects.length;
		for (i in 0...totalRects) {
			drawX = _rects[i].isoPos.x - _point.x;
			drawY = _rects[i].isoPos.y + _point.y;
			
			tile = _tileObjects[_rects[i].index];
			
			if (tile != null)
			{
				if (tile.allowCollisions <= FlxObject.NONE)
				{
					debugColor = FlxColor.BLUE;
				}
				else if (tile.allowCollisions != FlxObject.ANY)
				{
					debugColor = FlxColor.PINK;
				}
				else
				{
					debugColor = FlxColor.GREEN;
				}
				
				// Copied from makeDebugTile
				var gfx:Graphics = Camera.debugLayer.graphics;
				gfx.lineStyle(1, debugColor, 0.5);
				gfx.drawRect(drawX, drawY, _scaledTileWidth, _scaledTileDepth + _scaledTileHeight);
			}
		}
		#end
	}
	#end
	
	/**
	 * Draws the tilemap buffers to the cameras.
	 */
	override public function draw():Void
	{
		// don't try to render a tilemap that isn't loaded yet
		if (cachedGraphics == null)
		{
			return;
		}
		
		var cameras = cameras;
		var camera:FlxCamera;
		var buffer:FlxIsoTilemapBuffer;
		var i:Int = 0;
		var l:Int = cameras.length;
		
		while (i < l)
		{
			camera = cameras[i];
			
			if (!camera.visible || !camera.exists)
			{
				continue;
			}
			
			if (_buffers[i] == null)
			{
				_buffers[i] = createBuffer(camera);
			}
			
			buffer = _buffers[i++];
			buffer.dirty = true;
			#if FLX_RENDER_BLIT
			if (buffer.dirty)
			{
				drawTilemap(buffer, camera);
				buffer.dirty = false;
			}
			
			buffer.draw(camera, _flashPoint, scale.x, scale.y);
			#else
			drawTilemap(buffer, camera);
			#end
			
			#if !FLX_NO_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
		
		#if !FLX_NO_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	/**
	 * Set the dirty flag on all the tilemap buffers.
	 * Basically forces a reset of the drawn tilemaps, even if it wasn'tile necessary.
	 * 
	 * @param	Dirty		Whether to flag the tilemap buffers as dirty or not.
	 */
	override public function setDirty(Dirty:Bool = true):Void
	{
		for (buffer in _buffers)
		{
			buffer.dirty = true;
		}
	}
	
	/**
	 * Checks if the Object overlaps any tiles with any collision flags set,
	 * and calls the specified callback function (if there is one).
	 * Also calls the tile's registered callback if the filter matches.
	 * 
	 * @param	Object				The FlxObject you are checking for overlaps against.
	 * @param	Callback			An optional function that takes the form "myCallback(Object1:FlxObject,Object2:FlxObject)", where Object1 is a FlxIsoTile object, and Object2 is the object passed in in the first parameter of this method.
	 * @param	FlipCallbackParams	Used to preserve A-B list ordering from FlxObject.separate() - returns the FlxIsoTile object as the second parameter instead.
	 * @param	Position			Optional, specify a custom position for the tilemap (useful for overlapsAt()-type funcitonality).
	 * @return	Whether there were overlaps, or if a callback was specified, whatever the return value of the callback was.
	 */
	override public function overlapsWithCallback(Object:FlxObject, ?Callback:FlxObject->FlxObject->Bool, FlipCallbackParams:Bool = false, ?Position:FlxPoint):Bool
	{
		var results:Bool = false;
		
		var X:Float = x;
		var Y:Float = y;
		
		if (Position != null)
		{
			X = Position.x;
			Y = Position.y;
		}
		
		// Figure out what tiles we need to check against
		var selectionX:Int = Math.floor((Object.x - X) / _scaledTileWidth);
		var selectionY:Int = Math.floor((Object.y - Y) / _scaledTileHeight);
		var selectionWidth:Int = selectionX + Math.ceil(Object.width / _scaledTileWidth) + 1;
		var selectionHeight:Int = selectionY + Math.ceil(Object.height / _scaledTileHeight) + 1;
		
		// Then bound these coordinates by the map edges
		selectionWidth = Std.int(FlxMath.bound(selectionWidth, 0, widthInTiles));
		selectionHeight = Std.int(FlxMath.bound(selectionHeight, 0, heightInTiles));
		
		// Then loop through this selection of tiles
		var rowStart:Int = selectionY * widthInTiles;
		var row:Int = selectionY;
		var column:Int;
		var tile:FlxIsoTile;
		var overlapFound:Bool;
		var deltaX:Float = X - last.x;
		var deltaY:Float = Y - last.y;
		
		while (row < selectionHeight)
		{
			column = selectionX;
			
			while (column < selectionWidth)
			{
				var index:Int = rowStart + column;
				if ((index < 0) || (index > _data.length - 1))
				{
					column++;
					continue;
				}
				
				var dataIndex:Int = _data[index];
				if (dataIndex < 0)
				{
					column++;
					continue;
				}
				
				tile = _tileObjects[dataIndex];
				tile.width = _scaledTileWidth;
				tile.height = _scaledTileHeight;
				tile.x = X + column * tile.width;
				tile.y = Y + row * tile.height;
				tile.last.x = tile.x - deltaX;
				tile.last.y = tile.y - deltaY;
				
				overlapFound = ((Object.x + Object.width) > tile.x)  && (Object.x < (tile.x + tile.width)) && 
				               ((Object.y + Object.height) > tile.y) && (Object.y < (tile.y + tile.height));
				
				if (tile.allowCollisions != FlxObject.NONE)
				{
					if (Callback != null)
					{
						if (FlipCallbackParams)
						{
							overlapFound = Callback(Object, tile);
						}
						else
						{
							overlapFound = Callback(tile, Object);
						}
					}
				}
				
				if (overlapFound)
				{
					if ((tile.callbackFunction != null) && ((tile.filter == null) || Std.is(Object, tile.filter)))
					{
						tile.mapIndex = rowStart + column;
						tile.callbackFunction(tile, Object);
					}
					
					if (tile.allowCollisions != FlxObject.NONE)
					{
						results = true;
					}
				}
				
				column++;
			}
			
			rowStart += widthInTiles;
			row++;
		}
		
		return results;
	}
	
	public function getIsoRectAt(Index:Int):IsoRect
	{
		return _rects[Index];
	}
	
	override public function getTileIndexByCoords(Coord:FlxPoint):Int
	{
		return Std.int((Coord.y - y) / (_scaledTileDepth + _scaledTileHeight)) * widthInTiles + Std.int((Coord.x - x) / _scaledTileWidth);
	}
	
	override public function getTileCoordsByIndex(Index:Int, Midpoint:Bool = true):FlxPoint
	{
		var point = FlxPoint.get(x + Std.int(Index % widthInTiles) * _scaledTileWidth, y + Std.int(Index / widthInTiles) * (_scaledTileDepth + _scaledTileHeight));
		if (Midpoint)
		{
			point.x += _scaledTileWidth * 0.5;
			point.y += (_scaledTileDepth + _scaledTileHeight) * 0.5;
		}
		return point;
	}
	
	/**
	 * Returns a new Flash Array full of every coordinate of the requested tile type.
	 * 
	 * @param	Index		The requested tile type.
	 * @param	Midpoint	Whether to return the coordinates of the tile midpoint, or upper left corner. Default is true, return midpoint.
	 * @return	An Array with a list of all the coordinates of that tile type.
	 */
	public function getTileCoords(Index:Int, Midpoint:Bool = true):Array<FlxPoint>
	{
		var array:Array<FlxPoint> = null;
		
		var point:FlxPoint;
		var i:Int = 0;
		var l:Int = widthInTiles * heightInTiles;
		
		while (i < l)
		{
			if (_data[i] == Index)
			{
				point = FlxPoint.get(x + Std.int(i % widthInTiles) * _scaledTileWidth, y + Std.int(i / widthInTiles) * _scaledTileHeight);
				
				if (Midpoint)
				{
					point.x += _scaledTileWidth * 0.5;
					point.y += _scaledTileHeight * 0.5;
				}
				
				if (array == null)
				{
					array = new Array<FlxPoint>();
				}
				array.push(point);
			}
			
			i++;
		}
		
		return array;
	}
	
	/**
	 * Call this function to lock the automatic camera to the map's edges.
	 * 
	 * @param	Camera			Specify which game camera you want.  If null getScreenXY() will just grab the first global camera.
	 * @param	Border			Adjusts the camera follow boundary by whatever number of tiles you specify here.  Handy for blocking off deadends that are offscreen, etc.  Use a negative number to add padding instead of hiding the edges.
	 * @param	UpdateWorld		Whether to update the collision system's world size, default value is true.
	 */
	public function follow(?Camera:FlxCamera, Border:Int = 0, UpdateWorld:Bool = true):Void
	{
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		
		Camera.setScrollBoundsRect(x + Border * _scaledTileWidth, y + Border * _scaledTileHeight, width - Border * _scaledTileWidth * 2, height - Border * _scaledTileHeight * 2, UpdateWorld);
	}
	
	/**
	 * Shoots a ray from the start point to the end point.
	 * If/when it passes through a tile, it stores that point and returns false.
	 * 
	 * @param	Start		The world coordinates of the start of the ray.
	 * @param	End			The world coordinates of the end of the ray.
	 * @param	Result		A Point object containing the first wall impact.
	 * @param	Resolution	Defaults to 1, meaning check every tile or so.  Higher means more checks!
	 * @return	Returns true if the ray made it from Start to End without hitting anything.  Returns false and fills Result if a tile was hit.
	 */
	override public function ray(Start:FlxPoint, End:FlxPoint, ?Result:FlxPoint, Resolution:Float = 1):Bool
	{
		var step:Float = _scaledTileWidth;
		
		if (_scaledTileHeight < _scaledTileWidth)
		{
			step = _scaledTileHeight;
		}
		
		step /= Resolution;
		var deltaX:Float = End.x - Start.x;
		var deltaY:Float = End.y - Start.y;
		var distance:Float = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
		var steps:Int = Math.ceil(distance / step);
		var stepX:Float = deltaX / steps;
		var stepY:Float = deltaY / steps;
		var curX:Float = Start.x - stepX - x;
		var curY:Float = Start.y - stepY - y;
		var tileX:Int;
		var tileY:Int;
		var i:Int = 0;
		
		Start.putWeak();
		End.putWeak();
		
		while (i < steps)
		{
			curX += stepX;
			curY += stepY;
			
			if ((curX < 0) || (curX > width) || (curY < 0) || (curY > height))
			{
				i++;
				continue;
			}
			
			tileX = Math.floor(curX / _scaledTileWidth);
			tileY = Math.floor(curY / _scaledTileHeight);
			
			if (_tileObjects[_data[tileY * widthInTiles + tileX]].allowCollisions != FlxObject.NONE)
			{
				// Some basic helper stuff
				tileX *= Std.int(_scaledTileWidth);
				tileY *= Std.int(_scaledTileHeight);
				var rx:Float = 0;
				var ry:Float = 0;
				var q:Float;
				var lx:Float = curX - stepX;
				var ly:Float = curY - stepY;
				
				// Figure out if it crosses the X boundary
				q = tileX;
				
				if (deltaX < 0)
				{
					q += _scaledTileWidth;
				}
				
				rx = q;
				ry = ly + stepY * ((q - lx) / stepX);
				
				if ((ry > tileY) && (ry < tileY + _scaledTileHeight))
				{
					if (Result == null)
					{
						Result = FlxPoint.get();
					}
					
					Result.x = rx;
					Result.y = ry;
					
					return false;
				}
				
				// Else, figure out if it crosses the Y boundary
				q = tileY;
				
				if (deltaY < 0)
				{
					q += _scaledTileHeight;
				}
				
				rx = lx + stepX * ((q - ly) / stepY);
				ry = q;
				
				if ((rx > tileX) && (rx < tileX + _scaledTileWidth))
				{
					if (Result == null)
					{
						Result = FlxPoint.get();
					}
					
					Result.x = rx;
					Result.y = ry;

					return false;
				}
				
				return true;
			}
			
			i++;
		}
		
		return true;
	}
	
	/**
	 * Use this method for creating tileSheet for FlxIsoTilemap. Must be called after loadMap() method.
	 * If you forget to call it then you will not see this FlxIsoTilemap on c++ target
	 */
	public function updateFrameData():Void
	{
		if (cachedGraphics != null && _tileWidth >= 1 && _tileHeight >= 1)
		{
			framesData = cachedGraphics.tilesheet.getSpriteSheetFrames(region, new Point(0, 0));
			#if FLX_RENDER_TILE
			_rectIDs = new Array<Int>();
			FlxArrayUtil.setLength(_rectIDs, totalTiles);
			#end
			var i:Int = 0;
			
			while (i < totalTiles)
			{
				updateTile(i++);
			}
		}
	}
	
	/**
	 * Change a particular tile to FlxSprite. Or just copy the graphic if you dont want any changes to mapdata itself.
	 * 
	 * @link http://forums.flixel.org/index.php/topic,5398.0.html
	 * @param	X		The X coordinate of the tile (in tiles, not pixels).
	 * @param	Y		The Y coordinate of the tile (in tiles, not pixels).
	 * @param	NewTile	New tile to the mapdata. Use -1 if you dont want any changes. Default = 0 (empty)
	 * @return	FlxSprite.
	 */
	public function tileToFlxSprite(X:Int, Y:Int, NewTile:Int = 0):FlxSprite
	{
		var rowIndex:Int = X + (Y * widthInTiles);
		
		var rect:Rectangle = null;
		
		rect = _rects[rowIndex];
		#if FLX_RENDER_TILE
		var tile:FlxIsoTile = _tileObjects[_data[rowIndex]];
		
		if ((tile == null) || !tile.visible)
		{
			// Nothing to do here: rect object should stay null.
		}
		else
		{
			var rx:Int = (_data[rowIndex] - _startingIndex) * (_tileWidth + region.spacingX);
			var ry:Int = 0;
			
			if (rx >= region.width)
			{
				ry = Std.int(rx / region.width) * (_tileHeight + region.spacingY);
				rx %= region.width;
			}
			
			rect = new Rectangle(rx + region.startX, ry + region.startY, _tileWidth, _tileHeight);
		}
		#end
		
		// TODO: make it better for native targets
		var pt:Point = new Point(0, 0);
		var tileSprite:FlxSprite = new FlxSprite();
		tileSprite.makeGraphic(_tileWidth, _tileHeight, FlxColor.TRANSPARENT, true);
		tileSprite.x = X * _tileWidth + x;
		tileSprite.y = Y * _tileHeight + y;
		tileSprite.scale.x = scale.x;
		tileSprite.scale.y = scale.y;
		
		if (rect != null) 
		{
			tileSprite.pixels.copyPixels(cachedGraphics.bitmap, rect, pt);
		}
		
		tileSprite.dirty = true;
		tileSprite.updateFrameData();

		if (NewTile >= 0) 
		{
			setTile(X, Y, NewTile);
		}
		
		return tileSprite;
	}
	
	/**
	 * Use this method so the tilemap buffers are updated, eg when resizing your game
	 */
	public function updateBuffers():Void
	{
		var i:Int = 0;
		var l:Int;
		
		if (_buffers != null)
		{
			i = 0;
			l = _buffers.length;
			
			for (i in 0...l)
			{
				_buffers[i].destroy();
			}
			
			_buffers = null;
		}
		
		_buffers = new Array<FlxIsoTilemapBuffer>();
	}
	
	/**
	 * Internal function that actually renders the tilemap to the tilemap buffer. Called by draw().
	 * 
	 * @param	Buffer		The FlxIsoTilemapBuffer you are rendering to.
	 * @param	Camera		The related FlxCamera, mainly for scroll values.
	 */
	private function drawTilemap(Buffer:FlxIsoTilemapBuffer, Camera:FlxCamera):Void
	{
	#if FLX_RENDER_BLIT
		Buffer.fill();
	#else
		var tileID:Int;
		
		var hackScaleX:Float = tileScaleHack * scale.x;
		var hackScaleY:Float = tileScaleHack * scale.y;
		
		var drawItem:DrawStackItem = Camera.getDrawStackItem(cachedGraphics, false, 0);
		var currDrawData:Array<Float> = drawItem.drawData;
		var currIndex:Int = drawItem.position;
	#end
		
		// Copy tile images into the tile buffer
		_point.x = (Camera.scroll.x * scrollFactor.x) - x; //modified from getScreenXY()
		_point.y = (Camera.scroll.y * scrollFactor.y) - y;
		
		var tile:FlxIsoTile;
		
		#if !FLX_NO_DEBUG
		var debugTile:BitmapData;
		#end 
		
		var totalRects:Int = _rects.length;
		for (i in 0...totalRects)
		{
			_flashRect = _rects[i];
			if (_flashRect != null)
			{
				drawPt.x = _flashRect.isoPos.x - _point.x;
				drawPt.y = _flashRect.isoPos.y + _point.y;
				
				#if FLX_RENDER_TILE
				tileID = _rectIDs[i];
				#end
				
				if (isTileOnScreen(drawPt, Camera, _scaledTileWidth, _scaledTileDepth, _scaledTileHeight))
				{
					#if FLX_RENDER_BLIT
					if (_flashRect.sprite == null) 
					{
						Buffer.pixels.copyPixels(cachedGraphics.bitmap, _flashRect, drawPt, null, null, true);
					} else {
						_flashRect.sprite.draw();
						Buffer.pixels.copyPixels(_flashRect.sprite.framePixels, _flashRect, drawPt, null, null, true);
					}
					#else
						currDrawData[currIndex++] = drawPt.x;
						currDrawData[currIndex++] = drawPt.y;
						currDrawData[currIndex++] = _flashRect.index;
						
						// Tilemap tearing hack
						currDrawData[currIndex++] = hackScaleX; 
						currDrawData[currIndex++] = 0;
						currDrawData[currIndex++] = 0;
						// Tilemap tearing hack
						currDrawData[currIndex++] = hackScaleY; 
						
						// Alpha
						currDrawData[currIndex++] = 1.0;
					#end
					
					#if (FLX_RENDER_BLIT && !FLX_NO_DEBUG)
					if (FlxG.debugger.drawDebug && !ignoreDrawDebug) 
					{
						tile = _tileObjects[_flashRect.index];
						
						if (tile != null)
						{
							if (tile.allowCollisions <= FlxObject.NONE)
							{
								// Blue
								debugTile = _debugTileNotSolid; 
							}
							else if (tile.allowCollisions != FlxObject.ANY)
							{
								// Pink
								debugTile = _debugTilePartial; 
							}
							else
							{
								// Green
								debugTile = _debugTileSolid; 
							}
							
							Buffer.pixels.copyPixels(debugTile, _debugRect, drawPt, null, null, true);
						}
					}
					#end
				}
			}
		}
		
		#if FLX_RENDER_TILE
		drawItem.position = currIndex;
		#end
	}
	
	/**
	 * Simple check to see if a tile in on screen
	 * @param	pos	Position of the tile in pixels
	 * @param	cam	Current camera
	 * @return	True if the tile is inside the screen, false otherwise
	 */
	private static inline function isTileOnScreen(pos:Point, cam:FlxCamera, w:Float, d:Float, h:Float):Bool
	{
		return ((pos.x > (cam.x - w) && pos.x < cam.width) && (pos.y > (cam.y - (d + h)) && pos.y < cam.height));
	}
	
	/**
	 * Internal function to clean up the map loading code.
	 * Just generates a wireframe box the size of a tile with the specified color.
	 */
	#if (FLX_RENDER_BLIT && !FLX_NO_DEBUG)
	private function makeDebugTile(Color:Int):BitmapData
	{
		var debugTile:BitmapData;
		debugTile = new BitmapData(_tileWidth, (_tileDepth + _tileHeight), true, 0);

		var gfx:Graphics = FlxSpriteUtil.flashGfx;
		gfx.clear();
		gfx.moveTo(0, 0);
		gfx.lineStyle(1, Color, 0.5);
		gfx.lineTo(_tileWidth - 1, 0);
		gfx.lineTo(_tileWidth - 1, (_tileDepth + _tileHeight) - 1);
		gfx.lineTo(0, (_tileDepth + _tileHeight) - 1);
		gfx.lineTo(0, 0);
		
		debugTile.draw(FlxSpriteUtil.flashGfxSprite);
		
		return debugTile;
	}
	#end
	
	/**
	 * Internal function used in setTileByIndex() and the constructor to update the map.
	 * 
	 * @param	Index		The index of the tile you want to update.
	 */
	override private function updateTile(Index:Int):Void
	{
		var tile:FlxIsoTile = _tileObjects[_data[Index]];
		
		if ((tile == null) || !tile.visible)
		{
			_rects[Index] = null;
			#if FLX_RENDER_TILE
			_rectIDs[Index] = -1;
			#end
			
			return;
		}
		
		var rx:Int = (_data[Index] - _startingIndex) * (_tileWidth + region.spacingX);
		var ry:Int = 0;
		
		if (rx >= region.width)
		{
			ry = Std.int(rx / region.width) * ((_tileDepth + _tileHeight) + region.spacingY);
			rx %= region.width;
		}
		_rects[Index] = new IsoRect(rx + region.startX, ry + region.startY, _tileWidth, _tileDepth + _tileHeight, null);
		
		//TODO: Experimenting with depthModifier var. Remove this and allow depthModifier to be set through setTileProperties()
		if (_data[Index] == 0 || _data[Index] == 1) {
			_rects[Index].depthModifier = 500;
		} else {
			_rects[Index].depthModifier = 1000;
		}
		
		#if FLX_RENDER_TILE
		_rects[Index].index = framesData.frames[_data[Index] - _startingIndex].tileID;
		_rectIDs[Index] = framesData.frames[_data[Index] - _startingIndex].tileID;
		#end
	}
	
	private inline function createBuffer(camera:FlxCamera):FlxIsoTilemapBuffer
	{
		var buffer = new FlxIsoTilemapBuffer(_tileWidth, _tileDepth, _tileHeight, widthInTiles, heightInTiles, camera, scale.x, scale.y);
		buffer.pixelPerfectRender = pixelPerfectRender;
		return buffer;
	}
	
	/**
	 * Signal listener for gameResize 
	 */
	private function onGameResize(_,_):Void
	{
		for (i in 0...cameras.length)
		{
			var camera = cameras[i];
			var buffer = _buffers[i];
			
			// Calculate the required number of columns and rows
			_helperBuffer.updateColumns(_tileWidth, widthInTiles, scale.x, camera);
			_helperBuffer.updateRows((_tileDepth + _tileHeight), heightInTiles, scale.y, camera);
			
			// Create a new buffer if the number of columns and rows differs
			if (buffer == null || _helperBuffer.columns != buffer.columns || _helperBuffer.rows != buffer.rows)
			{
				if (buffer != null)
					buffer.destroy();

				_buffers[i] = createBuffer(camera);
			}
		}
	}
	
	/**
	 * Internal function for setting cachedGraphics property for this object. 
	 * It changes cachedGraphics' useCount also for better memory tracking.
	 */
	private function set_cachedGraphics(Value:CachedGraphics):CachedGraphics
	{
		var oldCached:CachedGraphics = cachedGraphics;
		
		if ((cachedGraphics != Value) && (Value != null))
		{
			Value.useCount++;
		}
		
		if ((oldCached != null) && (oldCached != Value))
		{
			oldCached.useCount--;
		}
		
		return cachedGraphics = Value;
	}
	
	override private function set_pixelPerfectRender(Value:Bool):Bool 
	{
		if (_buffers != null)
		{
			for (buffer in _buffers)
			{
				buffer.pixelPerfectRender = Value;
			}
		}
		
		return pixelPerfectRender = Value;
	}
	
	private function setScaleXYCallback(Scale:FlxPoint):Void
	{
		setScaleXCallback(Scale);
		setScaleYCallback(Scale);
	}
	
	private function setScaleXCallback(Scale:FlxPoint):Void
	{
		_scaledTileWidth = _tileWidth * scale.x;
		width = widthInTiles * _scaledTileWidth;
		
		if (cameras != null)
		{
			for (i in 0...cameras.length)
			{
				if (_buffers[i] != null)
				{
					_buffers[i].updateColumns(_tileWidth, widthInTiles, scale.x, cameras[i]);
				}
			}
		}
	}
	
	private function setScaleYCallback(Scale:FlxPoint):Void
	{
		_scaledTileHeight = _tileHeight * scale.y;
		_scaledTileDepth = _tileDepth * scale.y;
		height = heightInTiles * _scaledTileHeight;
		
		if (cameras != null)
		{
			for (i in 0...cameras.length)
			{
				if (_buffers[i] != null)
				{
					_buffers[i].updateRows(_tileHeight, heightInTiles, scale.y, cameras[i]);
				}
			}
		}
	}
}
