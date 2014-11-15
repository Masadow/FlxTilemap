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
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.tile.FlxDrawStackItem;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxTilemapGraphicAsset;
import flixel.tile.FlxBaseTilemap;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import openfl.display.BlendMode;
import openfl.display.Tilesheet;
import openfl.geom.ColorTransform;

@:bitmap("assets/images/tile/autotiles.png")
class GraphicAuto extends BitmapData {}

@:bitmap("assets/images/tile/autotiles_alt.png")
class GraphicAutoAlt extends BitmapData { }

// TODO: try to solve "tile tearing problem" (1px gap between tile at certain conditions) on native targets

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
	public var tileScaleHack:Float = 1.00;
	
	/**
	 * Changes the size of this tilemap. Default is (1, 1). 
	 * Anything other than the default is very slow with blitting!
	 */
	public var scale(default, null):FlxPoint;
	
	/**
	 * Rendering variables.
	 */
	public var frames(default, set):FlxFramesCollection;
	public var graphic(default, set):FlxGraphic;
	
	/**
	 * Tints the whole sprite to a color (0xRRGGBB format) - similar to OpenGL vertex colors. You can use
	 * 0xAARRGGBB colors, but the alpha value will simply be ignored. To change the opacity use alpha. 
	 */
	public var color(default, set):FlxColor = 0xffffff;
	
	/**
	 * Set alpha to a number between 0 and 1 to change the opacity of the sprite.
	 */
	public var alpha(default, set):Float = 1.0;
	
	public var colorTransform(default, null):ColorTransform;
	
	/**
	 * Blending modes, just like Photoshop or whatever, e.g. "multiply", "screen", etc.
	 */
	public var blend(default, set):BlendMode = null;
	
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	private var _flashPoint:Point;
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	//private var _flashRect:Rectangle;
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
	
	private var _blendInt:Int = 0;
	
	private var _matrix:FlxMatrix;
	#end
	
	/**
	 * Internal helper point used for convenience inside drawTilemap()
	 */
	private var drawPt:Point;
	
	//Helper to store tile frame rect (will always be 0,0,tileWidth,tileDepth + tileHeight)
	private var frameRect:Rectangle;
	
	var hasDrawn:Bool = false;
	
	/**
	 * The tilemap constructor just initializes some basic variables.
	 */
	public function new()
	{
		super();
		
		drawPt = new Point(0, 0);
		
		_buffers = new Array<FlxIsoTilemapBuffer>();
		_flashPoint = new Point();
		_flashRect = new IsoRect(0, 0, 0, 0, null);
		#if FLX_RENDER_TILE
		_helperPoint = new Point();
		_matrix = new FlxMatrix();
		#end
		
		colorTransform = new ColorTransform();
		
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
		
		_tileObjects = FlxDestroyUtil.destroyArray(_tileObjects);
		_buffers = FlxDestroyUtil.destroyArray(_buffers);
		
		#if FLX_RENDER_BLIT
		#if !FLX_NO_DEBUG
		_debugRect = null;
		_debugTileNotSolid = null;
		_debugTilePartial = null;
		_debugTileSolid = null;
		#end
		#else
		_helperPoint = null;
		_matrix = null;
		#end
		
		frames = null;
		graphic = null;
		
		// need to destroy FlxCallbackPoints
		scale = FlxDestroyUtil.destroy(scale);
		
		colorTransform = null;
		
		FlxG.signals.gameResized.remove(onGameResize);
		
		super.destroy();
	}
	
	private function set_frames(value:FlxFramesCollection):FlxFramesCollection
	{
		frames = value;
		
		if (value != null)
		{
			_tileWidth = Std.int(value.frames[0].sourceSize.x);
			_tileHeight = Std.int(value.frames[0].sourceSize.y);
			_flashRect.setTo(0, 0, _tileWidth, _tileDepth + _tileHeight);
			graphic = value.parent;
			postGraphicLoad();
		}
		
		return value;
	}
	
	override private function cacheGraphics(TileWidth:Int, TileHeight:Int, TileGraphic:FlxTilemapGraphicAsset):Void 
	{
		if (Std.is(TileGraphic, FlxTileFrames))
		{
			frames = cast(TileGraphic, FlxTileFrames);
			trace( "frames : " + frames );
			return;
		}
		
		var graph:FlxGraphic = FlxG.bitmap.add(cast TileGraphic);
		trace( "graph : " + graph.width + " x " + graph.height );
		// Figure out the size of the tiles
		_tileWidth = TileWidth;
		
		if (_tileWidth <= 0)
		{
			_tileWidth = graph.height;
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
		
		frames = FlxTileFrames.fromGraphic(graph, new FlxPoint(_tileWidth, _tileDepth + _tileHeight));
		//trace( "frames : " + frames );
	}
	
	override private function initTileObjects():Void 
	{
		_tileObjects = FlxDestroyUtil.destroyArray(_tileObjects);
		// Create some tile objects that we'll use for overlap checks (one for each tile)
		_tileObjects = new Array<FlxIsoTile>();
		
		var length:Int = frames.numFrames;
		length += _startingIndex;
		
		for (i in 0...length)
		{
			_tileObjects[i] = new FlxIsoTile(this, i, _tileWidth, _tileDepth, _tileHeight, (i >= _drawIndex), (i >= _collideIndex) ? allowCollisions : FlxObject.NONE);
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
		
		frameRect = new Rectangle(0, 0, _tileWidth, _tileDepth + _tileHeight);
	}
	
	override private function updateMap():Void 
	{
		_rects = new Array<IsoRect>();
		FlxArrayUtil.setLength(_rects, totalTiles);
		
		#if (!FLX_NO_DEBUG && FLX_RENDER_BLIT)
		_debugRect = new Rectangle(0, 0, _tileWidth, (_tileDepth + _tileHeight));
		#end
		
		var numTiles:Int = _tileObjects.length;
		
		for (i in 0...numTiles)
		{
			updateTile(i);
		}
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
				
				if (_rects[columnIndex] == null) {
					
					var rx:Float = (_data[columnIndex] - _startingIndex) * _tileWidth;
					var ry:Float = 0;
					
					if (rx >= _tileWidth)
					{
						ry = Std.int(rx / _tileWidth) * (_tileDepth + _tileHeight);
						rx %= _tileWidth;
					}
					_rects[columnIndex] = new IsoRect(rx + _flashPoint.x, ry + _flashPoint.y, _tileWidth, _tileDepth + _tileHeight, null);
					
					//TODO: Experimenting with depthModifier var. Remove this and allow depthModifier to be set through setTileProperties()
					if (_data[columnIndex] == 0 || _data[columnIndex] == 1) {
						_rects[columnIndex].depthModifier = 500;
					} else {
						_rects[columnIndex].depthModifier = 1000;
					}
					
					
					if (_rects[columnIndex].depth == -1) {
						_rects[columnIndex].setIso(_flashPoint.x, _flashPoint.y);
						_rects[columnIndex].depth = Std.int(_flashPoint.y * _rects[columnIndex].depthModifier + _flashPoint.x);
						_rects[columnIndex].index = _data[columnIndex];
					}
					
					//trace( "rect : " + _rects[columnIndex].toString() );
				}
				
				column++;
				columnIndex++;
			}
			
			_flashPoint.y += (_tileDepth + _tileHeight);
			
			rowIndex += widthInTiles;
			row++;
		}
		
		trace( "_rects : " + _rects.length );
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
		
		_helperPoint.x *= Camera.totalScaleX;
		_helperPoint.y *= Camera.totalScaleY;
		
		var debugColor:FlxColor;
		var drawX:Float;
		var drawY:Float;
		
		var rectWidth:Float = _scaledTileWidth * Camera.totalScaleX;
		var rectHeight:Float = (_scaledTileDepth + _scaledTileHeight) * Camera.totalScaleY;
		
		//Copied from drawTilemap
		var scaleX:Float = scale.x * Camera.totalScaleX;
		var scaleY:Float = scale.y * Camera.totalScaleY;
		var hackScaleX:Float = tileScaleHack * scaleX;
		var hackScaleY:Float = tileScaleHack * scaleY;
	
		// Copy tile images into the tile buffer
		// Modified from getScreenXY()
		_point.x = (Camera.scroll.x * scrollFactor.x) - x; 
		_point.y = (Camera.scroll.y * scrollFactor.y) - y;
		
		var screenXInTiles:Int = Math.floor(_point.x / _scaledTileWidth);
		var screenYInTiles:Int = Math.floor(_point.y / (_scaledTileDepth + _scaledTileHeight));
		var screenRows:Int = buffer.rows;
		var screenColumns:Int = buffer.columns;
		
		// Bound the upper left corner
		screenXInTiles = Std.int(FlxMath.bound(screenXInTiles, 0, widthInTiles - screenColumns));
		screenYInTiles = Std.int(FlxMath.bound(screenYInTiles, 0, (_scaledTileDepth + _scaledTileHeight) - screenRows));
		
		var rowIndex:Int = screenYInTiles * widthInTiles + screenXInTiles;
		var columnIndex:Int;
		var tile:FlxIsoTile;
		var debugTile:BitmapData;
		
		var totalRects:Int = _rects.length;
		for (i in 0...totalRects) {
			drawX = (_rects[i].isoPos.x - _point.x) - _scaledTileWidth / 2;
			drawY = (_rects[i].isoPos.y + _point.y) - (_scaledTileDepth + _scaledTileHeight) / 2;
			
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
				gfx.drawRect(drawX * hackScaleX, drawY * hackScaleY, rectWidth, rectHeight);
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
		if (graphic == null)
		{
			return;
		}
		
		var camera:FlxCamera;
		var buffer:FlxIsoTilemapBuffer;
		var l:Int = cameras.length;
		
		for (i in 0...l)
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
			
			buffer = _buffers[i];
			
			#if FLX_RENDER_BLIT
			getScreenPosition(_point, camera).add(buffer.x, buffer.y);
			buffer.dirty = buffer.dirty || _point.x > 0 || (_point.y > 0) || (_point.x + buffer.width < camera.width) || (_point.y + buffer.height < camera.height);
			
			if (buffer.dirty)
			{
				drawTilemap(buffer, camera);
			}
			
			//getScreenPosition(_point, camera).add(buffer.x, buffer.y).copyToFlash(_flashPoint);
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
		var column:Int;
		var tile:FlxIsoTile;
		var overlapFound:Bool;
		var deltaX:Float = X - last.x;
		var deltaY:Float = Y - last.y;
		
		for (row in selectionY...selectionHeight)
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
		}
		
		return results;
	}

	public function getIsoRectAt(Index:Int):IsoRect
	{
		return _rects[Index];
	}
	
	override public function getTileIndexByCoords(Coord:FlxPoint):Int
	{
		var result = Std.int((Coord.y - y) / (_scaledTileDepth + _scaledTileHeight)) * widthInTiles + Std.int((Coord.x - x) / _scaledTileWidth);
		Coord.putWeak();
		return result;
	}
	
	override public function getTileCoordsByIndex(Index:Int, Midpoint:Bool = true):FlxPoint
	{
		var point = FlxPoint.get(x + (Index % widthInTiles) * _scaledTileWidth, y + Std.int(Index / widthInTiles) * (_scaledTileDepth + _scaledTileHeight));
		if (Midpoint)
		{
			point.x += _scaledTileWidth * 0.5;
			point.y += (_scaledTileDepth + _scaledTileHeight) * 0.5;
		}
		return point;
	}
	
	/**
	 * Returns a new array full of every coordinate of the requested tile type.
	 * 
	 * @param	Index		The requested tile type.
	 * @param	Midpoint	Whether to return the coordinates of the tile midpoint, or upper left corner. Default is true, return midpoint.
	 * @return	An Array with a list of all the coordinates of that tile type.
	 */
	public function getTileCoords(Index:Int, Midpoint:Bool = true):Array<FlxPoint>
	{
		var array:Array<FlxPoint> = null;
		
		var point:FlxPoint;
		var l:Int = widthInTiles * heightInTiles;
		
		for (i in 0...l)
		{
			if (_data[i] == Index)
			{
				point = FlxPoint.get(x + (i % widthInTiles) * _scaledTileWidth, y + Std.int(i / widthInTiles) * _scaledTileHeight);
				
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
	 * @param	Result		An optional point containing the first wall impact if there was one. Null otherwise.
	 * @param	Resolution	Defaults to 1, meaning check every tile or so.  Higher means more checks!
	 * @return	Returns true if the ray made it from Start to End without hitting anything. Returns false and fills Result if a tile was hit.
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
					
					Result.set(rx, ry);
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
					
					Result.set(rx, ry);
					return false;
				}
				
				return true;
			}
			i++;
		}
		
		return true;
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
		
		var tile:FlxIsoTile = _tileObjects[_data[rowIndex]];
		var tileSprite:FlxSprite = new FlxSprite();
		tileSprite.x = X * _tileWidth + x;
		tileSprite.y = Y * _tileHeight + y;
		
		if (tile != null && tile.visible)
		{
			var image:FlxImageFrame = FlxImageFrame.fromFrame(tile.frame);
			tileSprite.frames = image;
		}
		else
		{
			tileSprite.makeGraphic(_tileWidth, _tileHeight, FlxColor.TRANSPARENT, true);
		}
		
		tileSprite.scale.copyFrom(scale);
		tileSprite.dirty = true;

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
		_buffers = FlxDestroyUtil.destroyArray(_buffers);
		_buffers = [];
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
		getScreenPosition(_point, Camera).copyToFlash(_helperPoint);
		
		_helperPoint.x *= Camera.totalScaleX;
		_helperPoint.y *= Camera.totalScaleY;
		
		_helperPoint.x = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.x) : _helperPoint.x;
		_helperPoint.y = isPixelPerfectRender(Camera) ? Math.floor(_helperPoint.y) : _helperPoint.y;
		
		var scaleX:Float = scale.x * Camera.totalScaleX;
		var scaleY:Float = scale.y * Camera.totalScaleY;
		
		var hackScaleX:Float = tileScaleHack * scaleX;
		var hackScaleY:Float = tileScaleHack * scaleY;
		
		var drawItem:FlxDrawStackItem;
	#end
		
		var isColored:Bool = ((alpha != 1) || (color != 0xffffff));
		
		// Copy tile images into the tile buffer
		_point.x = (Camera.scroll.x * scrollFactor.x) - x; //modified from getScreenXY()
		_point.y = (Camera.scroll.y * scrollFactor.y) - y;
		
		var tile:FlxIsoTile;
		var frame:FlxFrame;
		
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
				
				
				tile = _tileObjects[_flashRect.index];
				frame = tile.frame;
				
				if (tile != null && tile.visible && tile.frame.type != FlxFrameType.EMPTY)
				{
					#if FLX_RENDER_BLIT
					if (_flashRect.sprite == null) 
					{
						Buffer.pixels.copyPixels(frame.getBitmap(), frameRect, drawPt, null, null, true);
					} else {
						_flashRect.sprite.draw();
						Buffer.pixels.copyPixels(_flashRect.sprite.framePixels, _flashRect, drawPt, null, null, true);
					}
					
						#if !FLX_NO_DEBUG
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
					#else
						_matrix.identity();
						
						if (frame.angle != FlxFrameAngle.ANGLE_0)
						{
							frame.prepareFrameMatrix(_matrix);
						}
						
						_matrix.scale(hackScaleX, hackScaleY);
						
						drawItem = Camera.getDrawStackItem(graphic, isColored, _blendInt);
						
						//Chars
						if (_flashRect.sprite != null) {
							_flashRect.sprite.draw();
							var charDrawItem = Camera.getDrawStackItem(_flashRect.sprite.frame.parent, isColored, _blendInt);
							charDrawItem.setDrawData(FlxPoint.weak(drawPt.x * hackScaleX, drawPt.y * hackScaleY), _flashRect.sprite.frame.tileID, _matrix, isColored, color, alpha);
						} else {
							drawItem.setDrawData(FlxPoint.weak(drawPt.x * hackScaleX, drawPt.y * hackScaleY), _flashRect.index, _matrix, isColored, color, alpha);
						}
					#end
				}
			}
		}
		
		#if FLX_RENDER_BLIT
		if (isColored)
		{
			Buffer.colorTransform(colorTransform);
		}
		Buffer.blend = blend;
		#end
		
		Buffer.dirty = false;
	}
	
	/**
	 * Internal function to clean up the map loading code.
	 * Just generates a wireframe box the size of a tile with the specified color.
	 */
	#if (FLX_RENDER_BLIT && !FLX_NO_DEBUG)
	private function makeDebugTile(Color:FlxColor):BitmapData
	{
		var debugTile:BitmapData;
		debugTile = new BitmapData(_tileWidth, (_tileDepth + _tileHeight), true, 0);

		var gfx:Graphics = FlxSpriteUtil.flashGfx;
		gfx.clear();
		gfx.moveTo(0, 0);
		gfx.lineStyle(1, Color, 0.5);
		gfx.lineTo(_tileWidth - 1, 0);
		gfx.lineTo(_tileWidth - 1, (_tileDepth + _tileHeight) - 1);
		gfx.lineTo(0, _tileHeight - 1);
		gfx.lineTo(0, 0);
		
		debugTile.draw(FlxSpriteUtil.flashGfxSprite);
		
		return debugTile;
	}
	#end

	/**
	 * Internal function used in setTileByIndex() and the constructor to update the map.
	 * 
	 * @param	Index		The index of the tile object in _tileObjects internal array you want to update.
	 */
	override private function updateTile(Index:Int):Void
	{
		var tile:FlxIsoTile = _tileObjects[Index];
		
		if ((tile == null) || !tile.visible)
		{
			return;
		}
		
		tile.frame = frames.frames[Index - _startingIndex];
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
	 * Internal function for setting graphic property for this object. 
	 * It changes graphic' useCount also for better memory tracking.
	 */
	private function set_graphic(Value:FlxGraphic):FlxGraphic
	{
		//If graphics are changing
		if (graphic != Value)
		{
			//If new graphic is not null, increase its use count
			if (Value != null)
			{
				Value.useCount++;
			}
			//If old graphic is not null, decrease its use count
			if (graphic != null)
			{
				graphic.useCount--;
			}
		}
		
		return graphic = Value;
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
	
	private function set_alpha(Alpha:Float):Float
	{
		alpha = FlxMath.bound(Alpha, 0, 1);
		updateColorTransform();
		return alpha;
	}
	
	private function set_color(Color:FlxColor):Int
	{
		if (color == Color)
		{
			return Color;
		}
		color = Color;
		updateColorTransform();
		
		return color;
	}
	
	private function updateColorTransform():Void
	{
		if ((alpha != 1) || (color != 0xffffff))
		{
			colorTransform.redMultiplier = color.redFloat;
			colorTransform.greenMultiplier = color.greenFloat;
			colorTransform.blueMultiplier = color.blueFloat;
			colorTransform.alphaMultiplier = alpha;
		}
		else
		{
			colorTransform.redMultiplier = 1;
			colorTransform.greenMultiplier = 1;
			colorTransform.blueMultiplier = 1;
			colorTransform.alphaMultiplier = 1;
		}
		
		#if FLX_RENDER_BLIT
		setDirty();
		#end
	}
	
	private function set_blend(Value:BlendMode):BlendMode 
	{
		#if FLX_RENDER_TILE
		if (Value != null)
		{
			switch (Value)
			{
				case BlendMode.ADD:
					_blendInt = Tilesheet.TILE_BLEND_ADD;
				#if !flash
				case BlendMode.MULTIPLY:
					_blendInt = Tilesheet.TILE_BLEND_MULTIPLY;
				case BlendMode.SCREEN:
					_blendInt = Tilesheet.TILE_BLEND_SCREEN;
				#end
				default:
					_blendInt = Tilesheet.TILE_BLEND_NORMAL;
			}
		}
		else
		{
			_blendInt = 0;
		}
		#else
		setDirty();
		#end	
		
		return blend = Value;
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
