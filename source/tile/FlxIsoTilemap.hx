package tile;

import experimental.IsoUtils;
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
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.tile.FlxDrawTilesItem;
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
import haxe.Json;
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
	 * Rendering helper, minimize new object instantiation on repetitive methods
	 * Note: Currently being used only as a (_scaledTileWidth / 2, _scaledTileHeight / 2) point reference in draw() to draw the buffer.
	 * TODO: Investigate if we can throw this in draw again and stop messing with _point in drawTilemap()
	 */
	private var _flashPoint:Point;
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	private var _isoObject:IsoContainer;
	/**
	 * Internal list of buffers, one for each camera, used for drawing the tilemaps.
	 */
	private var _buffers:Array<FlxIsoTilemapBuffer>;
	
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
	private var _blendInt:Int = 0;
	
	private var _matrix:FlxMatrix;
	#end
	
	/**
	 * Internal helper point used for convenience inside drawTilemap()
	 */
	private var drawPt:Point;
	
	/**
	 * Helper to store tile frame rect (will always be 0,0,tileWidth,tileDepth + tileHeight)
	 */
	private var frameRect:Rectangle;
	
	/**
	 * Rectangle storing map frame for culling
	 */
	private var _mapFrameRect:Rectangle;
	
	/**
	 * Stores all tile containers in a 2D array
	 */
	private var _mapContainers:Array<Array<IsoContainer>>;
	
	/**
	 * Layer system variables (work in progress)
	 */
	private var _layers:Array<MapLayer>;
	
	private var doSort:Bool;
	
	//Helper point to draw sprites with offset
	//TODO: Is it really needed?
	private var _flashSpritePt:Point;
	
	/**
	 * Helper var to prevent allocating FlxIsoTile every frame
	 */
	private var _tile:FlxIsoTile;
	
	/**
	 * The tilemap constructor just initializes some basic variables.
	 * @param frame The rectangle to be used as the culling frame for the map
	 */
	public function new(frame:Rectangle)
	{
		_mapFrameRect = frame;
		super();
		
		drawPt = new Point(0, 0);
		_flashSpritePt = new Point(0, 0);
		
		_layers = new Array<MapLayer>();
		
		doSort = true;
		
		_buffers = new Array<FlxIsoTilemapBuffer>();
		_flashPoint = new Point(0, 0);
		_isoObject = new IsoContainer(null);
		#if FLX_RENDER_TILE
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
		_isoObject = null;
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
			return;
		}
		
		var graph:FlxGraphic = FlxG.bitmap.add(cast TileGraphic);
		
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
	 * position of the tiles` IsoContainers.
	 */
	public function adjustTiles():Void
	{
		var row = 0;
		var column = 0;
		var rowIndex = 0;
		var columnIndex = 0;
		var isoPoint = new Point(0, 0);
		
		_mapContainers = new Array<Array<IsoContainer>>();
		
		while (row < heightInTiles)
		{
			columnIndex = rowIndex;
			column = 0;
			
			_mapContainers[row] = new Array<IsoContainer>();
			
			while (column < widthInTiles)
			{
				var screenOffsetX = FlxG.stage.stageWidth / 2;
				var screenOffsetY = FlxG.stage.stageHeight / 2;
				
				isoPoint.x = screenOffsetX + (column - row) * (_scaledTileWidth / 2);
				isoPoint.y = screenOffsetY + (column + row) * (_scaledTileDepth / 2);
				
				var container = new IsoContainer(null);
					
				//TODO: Experimenting with depthModifier var. Remove this and allow depthModifier to be set through setTileProperties()
				if (_data[columnIndex] == 0 || _data[columnIndex] == 1) {
					container.depthModifier = 500;	//Floor tiles
				} else {
					container.depthModifier = 1000;	//Wall tiles
				}
				
				//Storing isometric position for tiles
				container.setIso(isoPoint.x, isoPoint.y);
				
				//Calculating and storing sorting depth
				container.depth = Std.int(isoPoint.y * container.depthModifier + isoPoint.x);
				
				//Storing tile type (index relative to its position inside the tileset)
				container.index = _data[columnIndex];
				
				//Storing column and row position
				container.setMap(column, row);
				
				_mapContainers[row][column] = container;
				
				column++;
				columnIndex++;
			}
			
			
			rowIndex += widthInTiles;
			row++;
		}
		
		//Buffer offset 
		#if FLX_RENDER_BLIT
		_flashPoint.x -= _scaledTileWidth / 2;
		_flashPoint.y -= _scaledTileHeight / 2;
		#end
	}
	
	/**
	 * Adds a FlxIsoSprite to be used in conjunction with this FlxIsoTilemap.
	 * The sprite will get sorted with the tiles and will be drawn according
	 * to its position inside the sorted array
	 * @param	Sprite	The FlxIsoSprite to be added to the map
	 */
	public function add(Sprite:FlxIsoSprite, layer:Int):Void
	{
		spriteGroup.add(Sprite);
		Sprite.map = this;
		Sprite.layer = layer;
		Sprite.cameras = [];
	}
	
	/**
	 * Adds a layer to the map. Currently layers work with only one tileset,
	 * loaded through one of 'loadMap' methods
	 * @param	layer	A MapLayer typedef to be added
	 */
	public function addLayer(layer:MapLayer)
	{
		_layers.push(layer);
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		var scaleX:Float = scale.x * camera.totalScaleX;
		var scaleY:Float = scale.y * camera.totalScaleY;
		
		var hackScaleX:Float = tileScaleHack * scaleX;
		var hackScaleY:Float = tileScaleHack * scaleY;
		
		//Screen size (we add one tile width / height to increase screen size and prevent columns and rows from appearing / disappearing)
		var vpWidth = (_mapFrameRect.width + _scaledTileWidth) / hackScaleX;
		var vpHeight = (_mapFrameRect.height + (_scaledTileDepth + _scaledTileHeight)) / hackScaleY;
		
		//Screen center (world position)
		var screenX:Float = camera.scroll.x - (vpWidth / 2);
		var screenY:Float = camera.scroll.y - (vpHeight / 2);
		
		//Center tile position
		var tileX:Int = Std.int((screenX + (2 * screenY) - (_scaledTileWidth / 2)) / (_scaledTileWidth - 1));
		var tileY:Int = Std.int((screenX - (2 * screenY) - (_scaledTileDepth / 2)) / (-_scaledTileWidth - 1));
		
		//Number of rows and columns (we add 1 tile to row and column to prevent columsn and rows from appearing / disappearing
		var rowCount = Std.int(vpHeight / (_scaledTileDepth / 2) + 1);
		var colCount = Std.int((vpWidth / _scaledTileWidth) + 1);
		
		var mapX:Int = 0;
		var mapY:Int = 0;
		
		for (layer in _layers) {
			layer.drawStack = [];
		}
		
		for (k in 0..._layers.length) {
			var layerCount:Int = 0;
			for (i in 0...rowCount) {
				for (j in 0...colCount) {
					mapX = tileX + j + Std.int(i / 2) + (i % 2);
					mapY = tileY - j + Std.int(i / 2);
					
					if (mapY < 0 || mapX < 0 || mapY >= heightInTiles || mapX >= widthInTiles) {
						continue;
					} else {
						var layer = _layers[k];
						if (layer.data[mapY][mapX].index > -1) {
							layer.drawStack[layerCount] = layer.data[mapY][mapX];
							layerCount++;
						}
					}
				}
			}
		}
		
		for (spr in spriteGroup.members)
		{
			spr.update(elapsed);
			var layer = _layers[spr.layer];
			layer.drawStack[layer.drawStack.length] = spr.isoContainer;
			
			if (spr.mustSort)
				doSort = true;
		}
		
		if (doSort) {
			for (layer in _layers) {
				if (layer.type == 1)
					IsoUtils.sortRange(layer.drawStack, IsoUtils.compareNumberRise, 0, layer.drawStack.length);
			}
		}
	}
	
	#if !FLX_NO_DEBUG
	override public function drawDebugOnCamera(Camera:FlxCamera):Void
	{
		#if FLX_RENDER_TILE
		
		//It seems we don't need buffers for FLX_RENDER_TILE anymore?
		
/*		var buffer:FlxIsoTilemapBuffer = null;
		var l:Int = FlxG.cameras.list.length;
		
		for (i in 0...l)
		{
			trace('Camera $i : ${FlxG.cameras.list[i]}');
			if (FlxG.cameras.list[i] == Camera)
			{
				buffer = _buffers[i];
				trace('Buffer for camera $i : $buffer');
				break;
			}
		}
		
		if (buffer == null)	
		{
			return;
		}*/
		
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
		
		_point.x = (Camera.scroll.x * scrollFactor.x) - x; //modified from getScreenXY()
		_point.y = (Camera.scroll.y * scrollFactor.y) - y;
		
		for (i in 0..._layers.length) {
			for (j in 0..._layers[i].drawStack.length) {
					
					var isoCont = _layers[i].drawStack[j];
					
					if (isoCont == null || isoCont.index == -1)
						continue;
						
					drawX = (isoCont.isoPos.x - _point.x) - _scaledTileWidth / 2;
					drawY = (isoCont.isoPos.y - _point.y) - ((_scaledTileHeight) / 2);
					
					_tile = _tileObjects[isoCont.index];
					
					if (_tile != null)
					{
						if (_tile.allowCollisions <= FlxObject.NONE)
						{
							debugColor = FlxColor.BLUE;
						}
						else if (_tile.allowCollisions != FlxObject.ANY)
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
			
			//TODO: Check if using this could remove interaction with _point in drawTilemap()
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

	public function setIsoTile(X:Int, Y:Int, Index:Int, layer:Int = 0):Void
	{
		var isoContainer = _layers[layer].data[X][Y];
		isoContainer.index = Index;
	}
	
	/**
	 * Returns a point in tile coordinates
	 * @param	Coord	World position to be converted
	 * @return
	 */
	public function getIsoPointByCoords(Coord:FlxPoint):FlxPoint
	{
		//Map offset
		var screenOffsetX = _mapFrameRect.width / 2;
		var screenOffsetY = _mapFrameRect.height / 2;
		
		var cX = Coord.x - screenOffsetX;
		var cY = Coord.y - screenOffsetY - (_scaledTileDepth / 2);
		
		//World to Map coordinates
		var mapX = (cX / (_scaledTileWidth / 2) + cY / (_scaledTileDepth / 2)) / 2;
		var mapY = (cY / (_scaledTileDepth / 2) - cX / (_scaledTileWidth / 2)) / 2;
		
		return FlxPoint.weak(mapY, mapX);
	}
	
	/**
	 * Returns a point in world coordinates
	 * @param	pt	The tile coordinates to be converted
	 * @return
	 */
	public function getIsoCoordsByPoint(pt:FlxPoint):FlxPoint
	{
		var x = (pt.x - pt.y) * (_scaledTileWidth / 2);
		var y = (pt.x + pt.y) * (_scaledTileDepth / 2);
		
		return FlxPoint.weak(x, y);
	}
	
	/**
	 * Returns an iso container object through world coordinates
	 * @param	Coord	The world coordinates of the tile
	 * @return
	 */
	public function getIsoTileByCoords(Coord:FlxPoint, layer:Int = 0):IsoContainer
	{
		//Map offset
		var screenOffsetX = _mapFrameRect.width / 2;
		var screenOffsetY = _mapFrameRect.height / 2;
		
		var cX = Coord.x - screenOffsetX;
		var cY = Coord.y - screenOffsetY - (_scaledTileDepth / 2);
		
		//World to Map coordinates
		var mapX = Std.int((cX / (_scaledTileWidth / 2) + cY / (_scaledTileDepth / 2)) / 2);
		var mapY = Std.int((cY / (_scaledTileDepth / 2) - cX / (_scaledTileWidth / 2)) / 2);
		
		var isoContainer = null;
		if (mapX >= 0 && mapX < widthInTiles - 1 && mapY >=0 && mapY < heightInTiles - 1) {
			isoContainer = _layers[layer].data[mapY][mapX];
		}
		
		return isoContainer;
	}
	
	public function getLayerAt(index:Int):MapLayer
	{
		return _layers[index];
	}
	
	public function getIsoTileByMapCoords(X:Int, Y:Int, layer:Int = 0):IsoContainer
	{
		return _layers[layer].data[Y][X];
	}
	
	/**
	 * Creates 2D map data layer from an array of tiles
	 * @param	tileIds	An array containing tileset indices
	 * @param	type Layer type (0 = Static, 1 = Dynamic)
	 * @param	fillIndex The tile id to use for blank spaces in the map (-1 does not get drawn)
	 * @return	A MapLayer object
	 */
	public function createLayerFromTileArray(tileIds:Array<Int>, type:Int, fillIndex:Int = -1):MapLayer
	{
		var data = new Array<Array<IsoContainer>>();
		
		if (_mapContainers == null)
			return null;
			
		for (i in 0...heightInTiles) {
			data[i] = new Array<IsoContainer>();
			for (j in 0...widthInTiles) {
				data[i][j] = _mapContainers[i][j].clone();
				var changeIndex = true;
				for (k in 0...tileIds.length) {
					if (tileIds[k] == _mapContainers[i][j].index)
						changeIndex = false;
				}
				if (changeIndex)
					data[i][j].index = fillIndex;
			}
		}
			
		var mapLayer = { data:data, drawStack:new Array<IsoContainer>(), type:type };
		return mapLayer;
	}
	
	public function loadFromTiledJson(data:String, layerTypes:Array<Int>, ?heightMap:Array<Array<Int>>):Void
	{
		var tiledData = Json.parse(data);
		
		widthInTiles = Std.int(tiledData.width);
		heightInTiles = Std.int(tiledData.height);
		
		var tWidth = Std.int(tiledData.tilewidth);
		_tileDepth = Std.int(tiledData.tileheight);
		
		//Supports only single tileset for now
		var tHeight = Std.int(tiledData.tilesets[0].tileheight) - _tileDepth;
		
		var tGraphic = tiledData.tilesets[0].image;
		var tiledLayers:Array<Dynamic> = tiledData.layers;
		
		cacheGraphics(tWidth, tHeight, tGraphic);
		postGraphicLoad();
		
		for (i in 0...tiledData.layers.length) {
			
			var row = 0;
			var column = 0;
			var rowIndex = 0;
			var columnIndex = 0;
			var isoPoint = new Point(0, 0);
			
			var layerData = new Array<Array<IsoContainer>>();
			var rawLayerData = tiledLayers[i];
			
			while (row < heightInTiles)
			{
				columnIndex = rowIndex;
				column = 0;
				
				layerData[row] = new Array<IsoContainer>();
				
				while (column < widthInTiles)
				{
					
					var screenOffsetX = FlxG.stage.stageWidth / 2;
					var screenOffsetY = FlxG.stage.stageHeight / 2;
					
					isoPoint.x = screenOffsetX + (column - row) * (_scaledTileWidth / 2);
					isoPoint.y = screenOffsetY + (column + row) * (_scaledTileDepth / 2);
					
					var container = new IsoContainer(null);
						
					//TODO: Experimenting with depthModifier var. Remove this and allow depthModifier to be set through setTileProperties()
					if (rawLayerData.data[columnIndex] == 0 || rawLayerData.data[columnIndex] == 1) {
						container.depthModifier = 500;	//Floor tiles
					} else {
						container.depthModifier = 1000;	//Wall tiles
					}
					
					//Height map
					if (heightMap != null)
						container.heightLevel = heightMap[row][column];
					
					container.depthModifier += 200 * container.heightLevel;
					
					//Storing isometric position for tiles
					container.setIso(isoPoint.x, isoPoint.y);
					
					//Calculating and storing sorting depth
					container.depth = Std.int(isoPoint.y * container.depthModifier + isoPoint.x);
					
					//Storing tile type (index relative to its position inside the tileset)
					//Subtract 1 because Tiled index count starts with 1 instead of 0
					container.index = Std.int(rawLayerData.data[columnIndex] - 1);
					
					//Storing column and row position
					container.setMap(column, row);
					
					layerData[row][column] = container;
					
					column++;
					columnIndex++;
				}
				
				rowIndex += widthInTiles;
				row++;
			}
			
			_layers[i] = { data:layerData, drawStack:new Array<IsoContainer>(), type:layerTypes[i] };
		}
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
		var scaleX:Float = scale.x * Camera.totalScaleX;
		var scaleY:Float = scale.y * Camera.totalScaleY;
		var hackScaleX:Float = tileScaleHack * scaleX;
		var hackScaleY:Float = tileScaleHack * scaleY;
		
		var drawItem:FlxDrawTilesItem;
	#end
		
		var isColored:Bool = ((alpha != 1) || (color != 0xffffff));
		
		_point.x = (Camera.scroll.x * scrollFactor.x) - x; //modified from getScreenXY()
		_point.y = (Camera.scroll.y * scrollFactor.y) - y;
		
		#if (FLX_RENDER_BLIT && !FLX_NO_DEBUG)
		var debugTile:BitmapData;
		#end 
		
		var heightOffset = _tileHeight - _tileDepth;
		
		for (i in 0..._layers.length) {
			var layer = _layers[i];
			for (j in 0...layer.drawStack.length) {
				
				_isoObject = layer.drawStack[j];
				
				if (_isoObject == null || _isoObject.index == -1)
					continue;
				
				drawPt.x = _isoObject.isoPos.x - _point.x;
				drawPt.y = (_isoObject.isoPos.y - _point.y) + (_isoObject.heightLevel * heightOffset);
				
				_tile = _tileObjects[_isoObject.index];
				
				#if FLX_RENDER_BLIT
				//Checks for sprites over the tile
				if (_isoObject.sprite != null) 
				{
					_isoObject.sprite.draw();
					_flashSpritePt.x = _isoObject.sprite.x - _point.x;
					_flashSpritePt.y = (_isoObject.sprite.y - (_scaledTileDepth / 2) - _point.y) + (_isoObject.heightLevel * heightOffset);
					
					//Sprite
					Buffer.pixels.copyPixels(_isoObject.sprite.getFlxFrameBitmapData() , frameRect, _flashSpritePt, null, null, true);
				} else {
					Buffer.pixels.copyPixels(_tile.frame.getBitmap(), frameRect, drawPt, null, null, true);
				}
				
					#if !FLX_NO_DEBUG
					if (FlxG.debugger.drawDebug && !ignoreDrawDebug) 
					{
						if (_tile != null)
						{
							if (_tile.allowCollisions <= FlxObject.NONE)
							{
								// Blue
								debugTile = _debugTileNotSolid;
							}
							else if (_tile.allowCollisions != FlxObject.ANY)
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
					
					if (_tile.frame.angle != FlxFrameAngle.ANGLE_0)
					{
						_tile.frame.prepareFrameMatrix(_matrix);
					}
						
					drawItem = Camera.getDrawTilesItem(graphic, isColored, _blendInt);
					
					//Checks for sprites over the tile
					if (_isoObject.sprite != null) {
						
						var flipX = _isoObject.sprite.flipX ? -1 : 1;
						var flipY = _isoObject.sprite.flipY ? -1 : 1;
						var translateX = _isoObject.sprite.flipX ? _isoObject.sprite.width : 0;
						var translateY = _isoObject.sprite.flipY ? _isoObject.sprite.height : 0;
						
						_matrix.scale(hackScaleX * flipX, hackScaleY * flipY);
						_matrix.translate(translateX, translateY);
						
						_isoObject.sprite.draw();
						
						var charDrawItem = Camera.getDrawTilesItem(_isoObject.sprite.frame.parent, isColored, _blendInt);
						
						//Sprite position
						var charX = (_isoObject.sprite.x - _point.x) * hackScaleX;
						var charY = ((_isoObject.sprite.y - (_scaledTileDepth / 2) - _point.y) * hackScaleY) + (_isoObject.heightLevel * heightOffset);
							
						//Sprite
						charDrawItem.setDrawData(FlxPoint.weak(charX, charY), _isoObject.sprite.frame.tileID, _matrix, isColored, color, alpha);
					} else {
						_matrix.scale(hackScaleX, hackScaleY);
						drawItem.setDrawData(FlxPoint.weak(drawPt.x * hackScaleX, drawPt.y * hackScaleY), _isoObject.index, _matrix, isColored, color, alpha);
					}
				#end
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
	
	override public function findPath(Start:FlxPoint, End:FlxPoint, Simplify:Bool = true, RaySimplify:Bool = false, WideDiagonal:Bool = true):Array<FlxPoint>
	{
		trace('findPath method does not work with FlxIsoTilemap. Use external class tile.AStar instead');
		return null;
	}
	
	override public function computePathDistance(StartIndex:Int, EndIndex:Int, WideDiagonal:Bool, StopOnEnd:Bool = true):Array<Int>
	{
		trace('computePathDistance method does not work with FlxIsoTilemap. Use external class tile.AStar instead');
		return null;
	}
}

typedef MapLayer = {
	data:Array<Array<IsoContainer>>,
	drawStack:Array<IsoContainer>,
	type:Int
}
