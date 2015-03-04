package states;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.system.System;
import tile.FlxIsoTilemap;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Editor extends FlxUIState
{
	var map:FlxIsoTilemap;
	var mapCam:FlxCamera;
	var initial:FlxPoint;
	var final:FlxPoint;
	var wPos:FlxPoint;
	var isZooming:Bool;
	var mapCursor:FlxIsoSprite;
	var uiCam:flixel.FlxCamera;
	
	var currentTool:Int;
	var currentLayer:Int;
	var isPanning:Bool;
	var stPanelGroup:FlxUIGroup;
	var createMapGroup:flixel.addons.ui.FlxUIGroup;
	var confirmGroup:flixel.addons.ui.FlxUIGroup;
	
	override public function create()
	{
		_xml_id = "editor";
		
		super.create();
		
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
		
		FlxG.mouse.load('images/arrow_cursor.png');
		
		//FlxG.debugger.drawDebug = true;
		this.bgColor = 0xFF444444;
		
		isZooming = false;
		currentTool = 0;
		currentLayer = 0;
		
		//Map mouse / touch scrolling helpers
		wPos = FlxPoint.get(0, 0);
		initial = FlxPoint.get(0, 0);
		final = FlxPoint.get(0, 0);
		
		//Map camera
		mapCam = new FlxCamera(0, 0, 1280, 720, 1);
		FlxG.cameras.add(mapCam);
		
		uiCam = new FlxCamera(0, 0, 1280, 720, 1);
		uiCam.bgColor = 0x0;
		FlxG.cameras.add(uiCam);
		
		
		//FlxG.mouse._cursor.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		for (i in -10...0) {
			var n = -i;
			trace('n : $n');
		}
		
		setupUI();
		
		var isoTile = new EditorIsoTile(700, 500, 64, 64, 32, flixel.util.FlxSpriteUtil.getDefaultLineStyle());
		isoTile.drawSpecificShape(new Matrix());
		add(isoTile);
	}
	
/*	private function onMouseMove(e:MouseEvent):Void 
	{
		if (FlxG.mouse.
	}*/
	
	function createMap(width:Int, height:Int, tWidth:Int, tHeight:Int, tDepth:Int)
	{
		var mapSize = { w:width, h:height };
		
		var gridLayer = [];
		var userLayer = [];
		var initialData = [];
		for (i in 0...mapSize.h) {
			gridLayer[i] = [];
			userLayer[i] = [];
			initialData[i] = [];
			for (j in 0...mapSize.w) {
				//Tile outline
				gridLayer[i][j] = 20;
				//Blank tile
				userLayer[i][j] = 21;
				//Debug
				initialData[i][j] = 7;
			}
		}
		
		//Must create a grid to show the size of the map
		map = new FlxIsoTilemap(new Rectangle(0, 0, FlxG.width, FlxG.height));
		map.tileDepth = tDepth;
		map.loadMapFrom2DArray(initialData, "images/iso_64_32_b.png", tWidth, tHeight, FlxTilemapAutoTiling.OFF, 0, 0, 1);
		map.adjustTiles();
		
		//var tileRange = [0, 1, 2, 20];
		//var groundLayer = map.createLayerFromTileArray(tileRange, 0, 1);
		//map.addLayer(groundLayer);
		//
		////Dynamic layer
		//tileRange = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
		//var midLayer = map.createLayerFromTileArray(tileRange, 1, -1);
		//map.addLayer(midLayer);
		
		map.addLayer(map.createLayerFrom2DArray(userLayer, 0), 0);
		map.addLayer(map.createLayerFrom2DArray(gridLayer, 0), 1);
		
		map.cameras = [mapCam];
		#if debug
		map.ignoreDrawDebug = true;
		#end
		add(map);
		
		//Cursor to show mouse click position
		mapCursor = new FlxIsoSprite(0, 0);
		mapCursor.set_camera(mapCam);
		mapCursor.loadGraphic("images/iso_64_32_b.png", true, 64, 96);
		for (i in 0...22) {
			mapCursor.animation.add(Std.string(i), [i]);
		}
		mapCursor.animation.play("0");
		
		mapCursor.ignoreDrawDebug = true;
		add(mapCursor);
	}
	
	function setupUI()
	{
		var tileGfx = cast(_ui.getAsset('tile_img'), FlxSprite);
		tileGfx.loadGraphic('images/iso_64_32_b.png', true, 64, 96);
		for (i in 0...22) {
			tileGfx.animation.add(Std.string(i), [i]);
		}
		tileGfx.animation.play('0');
		
		var btBack = cast(_ui.getAsset("tile_back"), FlxUIButton);
		btBack.onUp.callback = onTileBack;
		btBack.visible = false;
		
		var btNext = cast(_ui.getAsset("tile_next"), FlxUIButton);
		btNext.onUp.callback = onTileNext;
		
		var btSelect = cast(_ui.getAsset("btn_select"), FlxUIButton);
		btSelect.onUp.callback = onBtnSelect;
		
		var btStamp = cast(_ui.getAsset("btn_stamp"), FlxUIButton);
		btStamp.onUp.callback = onBtnStamp;
		
		var btErase = cast(_ui.getAsset("btn_erase"), FlxUIButton);
		btErase.onUp.callback = onBtnErase;
		
		var layerTxt = cast(_ui.getAsset('layers_label'), FlxText);
		layerTxt.text = map != null ? 'Layer : $currentLayer / ${map.layers.length - 1}' : '0';
		
		var btnStartup = cast(_ui.getAsset("btn_startup"), FlxUIButton);
		btnStartup.visible = false;
		btnStartup.onUp.callback = onBtnShowStartup;
		
		//Startup panel
		stPanelGroup = new FlxUIGroup();
		
		var stChrome = _ui.getAsset('startup_chrome');
		stPanelGroup.add(cast(stChrome, FlxSprite));
		var stLabel = _ui.getAsset('startup_label');
		stPanelGroup.add(cast(stLabel, FlxSprite));
		
		var btnCreate = cast(_ui.getAsset('startup_create'), FlxUIButton);
		btnCreate.onUp.callback = onBtnStartupCreate;
		stPanelGroup.add(cast(btnCreate, FlxSprite));
		var btnLoad = cast(_ui.getAsset('startup_load'), FlxUIButton);
		btnLoad.onUp.callback = onBtnStartupLoad;
		stPanelGroup.add(cast(btnLoad, FlxSprite));
		var btnQuit = cast(_ui.getAsset('startup_quit'), FlxUIButton);
		btnQuit.onUp.callback = onBtnStartupQuit;
		stPanelGroup.add(cast(btnQuit, FlxSprite));
		
		//stPanelGroup.kill();
		
		
		//Create Map
		createMapGroup = new FlxUIGroup();
		
		var crtChrome = _ui.getAsset('create_map_chrome');
		createMapGroup.add(cast(crtChrome, FlxSprite));
		var crtLabel = _ui.getAsset('create_map_label');
		createMapGroup.add(cast(crtLabel, FlxSprite));
		
		var mapWInput = cast(_ui.getAsset('width_input'), FlxUIInputText);
		createMapGroup.add(cast(mapWInput, FlxUIInputText));
		
		var mapXLabel = _ui.getAsset('x_label');
		createMapGroup.add(cast(mapXLabel, FlxSprite));
		
		var mapHInput = cast(_ui.getAsset('height_input'), FlxUIInputText);
		createMapGroup.add(cast(mapHInput, FlxUIInputText));
		
		var crtTileLabel = _ui.getAsset('create_map_tile_label');
		createMapGroup.add(cast(crtTileLabel, FlxSprite));
		
		var tileWInput = cast(_ui.getAsset('tile_width_input'), FlxUIInputText);
		createMapGroup.add(cast(tileWInput, FlxUIInputText));
		
		var tileXLabel = _ui.getAsset('tile_x_label');
		createMapGroup.add(cast(tileXLabel, FlxSprite));
		
		var tileHInput = cast(_ui.getAsset('tile_height_input'), FlxUIInputText);
		createMapGroup.add(cast(tileHInput, FlxUIInputText));
		
		var btnCreateMapOk = cast(_ui.getAsset('create_map_ok'), FlxUIButton);
		btnCreateMapOk.onUp.callback = onBtnCreateOk;
		createMapGroup.add(cast(btnCreateMapOk, FlxSprite));
		
		createMapGroup.kill();
		
		
		var cg = _ui.getAsset('confirm_group');
		trace('cg : $cg');
		
		//Confirmation Dialog
		confirmGroup = new FlxUIGroup();
		
		var cfmChrome = _ui.getAsset('confirm_chrome');
		confirmGroup.add(cast(cfmChrome, FlxSprite));
		
		var cfmLabel = _ui.getAsset('confirm_label');
		confirmGroup.add(cast(cfmLabel, FlxSprite));
		
		var btnConfirmYes = cast(_ui.getAsset('confirm_yes'), FlxUIButton);
		btnConfirmYes.onUp.callback = onBtnConfirmYes;
		confirmGroup.add(cast(btnConfirmYes, FlxSprite));
		
		var btnConfirmCancel = cast(_ui.getAsset('confirm_cancel'), FlxUIButton);
		btnConfirmCancel.onUp.callback = onBtnConfirmCancel;
		confirmGroup.add(cast(btnConfirmCancel, FlxSprite));
		
		confirmGroup.kill();
		
		
		_ui.cameras = [uiCam];
	}
	
	function onBtnShowStartup() {
		stPanelGroup.revive();
	}
	
	function onBtnStartupCreate() {
		
		//Hide startup panel
		stPanelGroup.kill();
		
		createMapGroup.revive();
		
		var btnStartup = cast(_ui.getAsset("btn_startup"), FlxUIButton);
		btnStartup.visible = true;
	}
	
	function onBtnStartupLoad() {
		
		//Open load file dialog
	}
	
	function onBtnStartupQuit() {
		
		//Quit
		stPanelGroup.kill();
		
		confirmGroup.revive();
		
		//System.exit(0);
		
	}
	
	function onBtnCreateOk() {
		var wInput = cast(_ui.getAsset('width_input'), FlxUIInputText);
		var hInput = cast(_ui.getAsset('height_input'), FlxUIInputText);
		
		var tWInput = cast(_ui.getAsset('tile_width_input'), FlxUIInputText);
		var tHInput = cast(_ui.getAsset('tile_width_input'), FlxUIInputText);
		
		var mapW = wInput.text != null && wInput.text.length > 0 ? Std.parseInt(wInput.text) : 32;
		var mapH = hInput.text != null && hInput.text.length > 0 ? Std.parseInt(hInput.text) : 32;
		
		var tileW = tWInput.text != null && tWInput.text.length > 0 ? Std.parseInt(tWInput.text) : 64;
		var tileH = tHInput.text != null && tHInput.text.length > 0 ? Std.parseInt(tHInput.text) : 64;
		var tileD = 32;
		
		createMap(mapW, mapH, tileW, tileH, tileD);
		
		createMapGroup.kill();
	}
	
	function onBtnConfirmYes() {
		
		confirmGroup.kill();
		
		System.exit(0);
	}
	
	function onBtnConfirmCancel() {
		
		confirmGroup.kill();
		
		stPanelGroup.revive();
	}
	
	function onTileBack()
	{
		var tileGfx = cast(_ui.getAsset('tile_img'), FlxSprite);
		var curAnim = Std.parseInt(tileGfx.animation.name);
		var newAnim = curAnim - 1;
		if (newAnim >= 0)
		{
			tileGfx.animation.play(Std.string(newAnim));
			
			var tileTxt = cast(_ui.getAsset('tile_label'), FlxText);
			tileTxt.text = 'Tile : $newAnim';
			
			if (currentTool == 1)
				mapCursor.animation.play(Std.string(newAnim));
		}
		
		if (newAnim == 0) {
			//Disable the button
			var btBack = cast(_ui.getAsset("tile_back"), FlxUIButton);
			btBack.visible = false;
		}
		
		if (newAnim < 21) {
			//Enable next button
			var btNext = cast(_ui.getAsset("tile_next"), FlxUIButton);
			btNext.visible = true;
		}
	}
	
	function onTileNext()
	{
		var tileGfx = cast(_ui.getAsset('tile_img'), FlxSprite);
		var curAnim = Std.parseInt(tileGfx.animation.name);
		var newAnim = curAnim + 1;
		if (newAnim <= 21)
		{
			tileGfx.animation.play(Std.string(newAnim));
			
			var tileTxt = cast(_ui.getAsset('tile_label'), FlxText);
			tileTxt.text = 'Tile : $newAnim';
			
			if (currentTool == 1)
				mapCursor.animation.play(Std.string(newAnim));
		}
		
		if (newAnim == 21) {
			//Disable the button
			var btNext = cast(_ui.getAsset("tile_next"), FlxUIButton);
			btNext.visible = false;
		}
		
		if (newAnim > 0) {
			//Enable back button
			var btBack = cast(_ui.getAsset("tile_back"), FlxUIButton);
			btBack.visible = true;
		}
	}
	
	function onBtnSelect() 
	{
		FlxG.mouse.load('images/arrow_cursor.png');
		
		currentTool = 0;
		
		var btStamp = cast(_ui.getAsset("btn_stamp"), FlxUIButton);
		btStamp.toggled = false;
		
		var btErase = cast(_ui.getAsset("btn_erase"), FlxUIButton);
		btErase.toggled = false;
	}
	
	function onBtnStamp() 
	{
		FlxG.mouse.load('images/stamp_cursor.png');
		
		currentTool = 1;
		var btSelect = cast(_ui.getAsset("btn_select"), FlxUIButton);
		btSelect.toggled = false;
		
		var btErase = cast(_ui.getAsset("btn_erase"), FlxUIButton);
		btErase.toggled = false;
		
		//var tileGfx = cast(_ui.getAsset('tile_img'), FlxSprite);
		//mapCursor.animation.play(tileGfx.animation.name);
	}
	
	function onBtnErase() 
	{
		
		FlxG.mouse.load('images/erase_cursor.png');
		
		currentTool = 2;
		var btSelect = cast(_ui.getAsset("btn_select"), FlxUIButton);
		btSelect.toggled = false;
		
		var btStamp = cast(_ui.getAsset("btn_stamp"), FlxUIButton);
		btStamp.toggled = false;
		
		//var tileGfx = cast(_ui.getAsset('tile_img'), FlxSprite);
		//mapCursor.animation.play('21');
	}
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		
		handleTouchInput(elapsed);
		
		handleKeyInput(elapsed);
		
		handleCursor();
	}
	
	function handleCursor()
	{
		if (map == null)
			return;
		
		//Mouse world position
		FlxG.mouse.getWorldPosition(mapCam, wPos);
		
		var tPos = map.getIsoPointByCoords(wPos);
		if (tPos.x >= 0 && tPos.x < map.widthInTiles && tPos.y >= 0 && tPos.y < map.heightInTiles) {
			var cPos = map.getIsoCoordsByPoint(tPos);
		
			mapCursor.x = cPos.x - mapCursor.width / 2;
			mapCursor.y = cPos.y - mapCursor.height / 2;
		}
	}
	
	function handleTouchInput(elapsed:Float)
	{
		if (map == null)
			return;
			
		//Mouse click
		if (FlxG.mouse.justPressed) {
			
			if (isPanning) {
				//Get initial mouse press position
				initial = FlxG.mouse.getScreenPosition();
			} else {
				FlxG.mouse.getWorldPosition(mapCam, wPos);
				var tile = map.getIsoTileByCoords(wPos);
				
				if (tile != null) {
					switch (currentTool) {
						case 0:
							//Update information panel with tile params
						case 1:
							map.setIsoTile(tile.mapPos.y, tile.mapPos.x, Std.parseInt(mapCursor.animation.name), currentLayer);
						case 2:
							map.setIsoTile(tile.mapPos.y, tile.mapPos.x, -1, currentLayer);
					}
				}
			}
		}
		
		if (FlxG.mouse.justReleased) {
			
			//Gets final mouse position after releasing press
			final = FlxG.mouse.getScreenPosition();
		}
		
		//Mouse drag to scroll camera
		if (FlxG.mouse.pressed && isPanning) {
			
			var delta = FlxG.mouse.getScreenPosition().subtractPoint(initial);
			mapCam.scroll.x -= delta.x;
			mapCam.scroll.y -= delta.y;
			initial = FlxG.mouse.getScreenPosition();
		}
		
		//Camera zoom in
		if (FlxG.mouse.wheel > 0 && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom + 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				//instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
			}} );
		}
		
		//Camera zoom out
		if (FlxG.mouse.wheel < 0 && !isZooming) {
			isZooming = true;
			FlxTween.tween(mapCam, { zoom:mapCam.zoom - 0.2 }, 0.2, { type:FlxTween.ONESHOT, ease:FlxEase.quintOut, onComplete:function (t:FlxTween) {
				//instructions.text = StringTools.replace(instructions.text, instructions.text.substring(instructions.text.indexOf("ZOOM"), instructions.text.length), "ZOOM : " + Std.string(mapCam.zoom).substr(0, 3));
				isZooming = false;
			}} );
		}
	}
	
	function handleKeyInput(elapsed:Float)
	{
		//Cycle through layers
		if (FlxG.keys.justPressed.TAB) {
			currentLayer = currentLayer < map.layers.length - 1 ? currentLayer + 1 : 0;
			//trace('Current layer : $currentLayer');
			
			var layerTxt = cast(_ui.getAsset('layers_label'), FlxText);
			layerTxt.text = 'Layer : $currentLayer / ${map.layers.length - 1}';
		}
		
		if (FlxG.keys.justPressed.SPACE) {
			//TODO: Turn pan on
			isPanning = true;
			FlxG.mouse.load('images/pan_cursor_n.png');
		}
		
		if (FlxG.keys.justReleased.SPACE) {
			isPanning = false;
			FlxG.mouse.load('images/arrow_cursor.png');
		}
	}
	
	override public function destroy()
	{
		super.destroy();
	}
	
}