package coffeegames.mapgen;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class MapGenerator {
	
	//Mini-map colors
	private var cNW_CORNER:UInt;
	private var cNE_CORNER:UInt;
	private var cSE_CORNER:UInt;
	private var cSW_CORNER:UInt;
	private var cN_WALL:UInt;
	private var cE_WALL:UInt;
	private var cS_WALL:UInt;
	private var cW_WALL:UInt;
	private var cS_DOOR:UInt;
	private var cE_DOOR:UInt;
	private var cENTRANCE:UInt;
	private var cFLOOR:UInt;
	private var cNOTHING:UInt;
	
	//Indices
	private var iNW_CORNER:Int;
	private var iNE_CORNER:Int;
	private var iSE_CORNER:Int;
	private var iSW_CORNER:Int;
	private var iN_WALL:Int;
	private var iE_WALL:Int;
	private var iS_WALL:Int;
	private var iW_WALL:Int;
	private var iS_DOOR:Int;
	private var iE_DOOR:Int;
	private var iENTRANCE:Int;
	private var iFLOOR:Int;
	private var iNOTHING:Int;
	
	public var display:Bitmap;
	public var debugDisplay:Bitmap;
	
	public var width:Int;
	public var height:Int;
	private var numRooms:Int;
	
	private var currentRoomEntrance:Door;
	private var currentRoomSize:Point;
	private var map:BitmapData;
	private var debugOverlay:BitmapData;
	
	public var rooms:Array<Room>;
	private var doorIndex:Int;
	private var unusedDoors:Array<Door>;
	
	private var oldDoorWallSize:Int;
	
	public var lowestX:Int;
	
	public var mapData:Array<Array<Int>>;
	
	private var totalLoops:Int;
	private var maxLoops:Int;
	private var showDebug:Bool;
	private var minRoomSize:Int;
	private var maxRoomSize:Int;
	
	/**
	 * Create a new instance of the map generator
	 * @param	width		Width in tiles
	 * @param	height		Height in tiles
	 * @param	maxLoops	Max number of loops over doors
	 * @param	minRoomSize	Max number of loops over doors
	 * @param	maxRoomSize	Max number of loops over doors
	 * @param	showDebug	Show Debug overlay
	 */
	public function new(width:Int, height:Int, maxLoops:Int, minRoomSize:Int, maxRoomSize:Int, showDebug:Bool) {
		this.width = width;
		this.height = height;
		numRooms = 0;
		
		rooms = new Array<Room>();
		unusedDoors = new Array<Door>();
		doorIndex = 0;
		lowestX = 0;
		
		totalLoops = 0;
		this.maxLoops = maxLoops;
		this.showDebug = showDebug;
		this.minRoomSize = minRoomSize;
		this.maxRoomSize = maxRoomSize;
		
		cNW_CORNER = 0xFFA30008;
		cNE_CORNER = 0xFFBC2F36;
		cSE_CORNER = 0xFFFD3F49;
		cSW_CORNER = 0xFFFD7279;
		cN_WALL = 0xFF1D0772;
		cE_WALL = 0xFF3F2D84;
		cS_WALL = 0xFF6749D7;
		cW_WALL = 0xFF856FD7;
		cS_DOOR = 0xFFFFD100;
		cE_DOOR = 0xFFBFA530;
		cENTRANCE = 0xFF82217A;
		cFLOOR = 0xFFFFFFFF;
		cNOTHING = 0xFF333333;
		
		iNW_CORNER = 0;
		iNE_CORNER = 0;
		iSE_CORNER = 0;
		iSW_CORNER = 0;
		iN_WALL = 0;
		iE_WALL = 0;
		iS_WALL = 0;
		iW_WALL = 0;
		iS_DOOR = 0;
		iE_DOOR = 0;
		iENTRANCE = 0;
		iFLOOR = 0;
		iNOTHING = 0;
		
		currentRoomEntrance = new Door(0, 0, DoorType.North);
		init();
	}
	
	/**
	 * Sets the colors for the tiles in the mini-map
	 * @param	nWC	North West Corner
	 * @param	nEC	North East Corner
	 * @param	sEC	South East Corner
	 * @param	sWC	South West Corner
	 * @param	nW	North Wall
	 * @param	eW	East Wall
	 * @param	sW	South Wall
	 * @param	wW	West Wall
	 * @param	dS	South Door
	 * @param	dE	East Door
	 * @param	e	Entrance
	 * @param	f	Floor
	 * @param	n	Nothing (Empty space)
	 */
	public function setColors(nWC:Int, nEC:Int, sEC:Int, sWC:Int, nW:Int, eW:Int, sW:Int, wW:Int, dS:Int, dE:Int, e:Int, f:Int, n:Int):Void {
		cNW_CORNER = nWC;
		cNE_CORNER = nEC;
		cSE_CORNER = sEC;
		cSW_CORNER = sWC;
		cN_WALL = nW;
		cE_WALL = eW;
		cS_WALL = sW;
		cW_WALL = wW;
		cS_DOOR = dS;
		cE_DOOR = dE;
		cENTRANCE = e;
		cFLOOR = f;
		cNOTHING = n;
	}
	
	/**
	 * Sets the tileset indices for extracting map data
	 * @param	nWC	North West Corner
	 * @param	nEC	North East Corner
	 * @param	sEC	South East Corner
	 * @param	sWC	South West Corner
	 * @param	nW	North Wall
	 * @param	eW	East Wall
	 * @param	sW	South Wall
	 * @param	wW	West Wall
	 * @param	dS	South Door
	 * @param	dE	East Door
	 * @param	e	Entrance
	 * @param	f	Floor
	 * @param	n	Nothing (Empty space)
	 */
	public function setIndices(nWC:Int, nEC:Int, sEC:Int, sWC:Int, nW:Int, eW:Int, sW:Int, wW:Int, dS:Int, dE:Int, e:Int, f:Int, n:Int):Void {
		iNW_CORNER = nWC;
		iNE_CORNER = nEC;
		iSE_CORNER = sEC;
		iSW_CORNER = sWC;
		iN_WALL = nW;
		iE_WALL = eW;
		iS_WALL = sW;
		iW_WALL = wW;
		iS_DOOR = dS;
		iE_DOOR = dE;
		iENTRANCE = e;
		iFLOOR = f;
		iNOTHING = n;
	}
	
	public function dispose(parent:Sprite):Void {
		parent.removeChild(display);
		
		if (showDebug) {
			parent.removeChild(debugDisplay);
			debugOverlay = null;
		}
		
		map = null;
		rooms = null;
		unusedDoors = null;
		currentRoomEntrance = null;
		currentRoomSize = null;
	}
	
	private function init():Void {
		map = new BitmapData(width, height, false, 0xFF333333);
		if (showDebug) {
			debugOverlay = new BitmapData(width, height, true, 0x4400CC00);
		}
	}
	
	public function showColorCodes():Void {
		trace("NW CORNER (" + iNW_CORNER + ") : " + cNW_CORNER);
		trace("NE CORNER (" + iNE_CORNER + ") : " + cNE_CORNER);
		trace("SE CORNER (" + iSE_CORNER + ") : " + cSE_CORNER);
		trace("SW CORNER (" + iSW_CORNER + ") : " + cSW_CORNER);
		trace("N WALL (" + iN_WALL + ") : " + cN_WALL);
		trace("E WALL (" + iE_WALL + ") : " + cE_WALL);
		trace("S WALL (" + iS_WALL + ") : " + cS_WALL);
		trace("W WALL (" + iW_WALL + ") : " + cW_WALL);
		trace("DOOR SOUTH (" + iS_DOOR + ") : " + cS_DOOR);
		trace("DOOR EAST (" + iE_DOOR + ") : " + cE_DOOR);
		trace("ENTRANCE (" + iENTRANCE + ") : " + cENTRANCE);
		trace("FLOOR (" + iFLOOR + ") : " + cFLOOR);
		var eSpace:UInt = 0xFF333333;
		trace("EMPTY SPACE : " + eSpace);
	}
	
	public function showMinimap(parent:DisplayObjectContainer, scale:Int, align:MapAlign, add:Bool = false):Bitmap {
		display = new Bitmap(map);
		if (add)
			parent.addChild(display);
		
		if (showDebug) {
			debugDisplay = new Bitmap(debugOverlay);
			parent.addChild(debugDisplay);
		}
		
		display.scaleX = scale;
		display.scaleY = scale;
		switch (align) {
			case MapAlign.TopLeft:
				display.x = 10;
				display.y = 10;
			case MapAlign.TopRight:
				display.x = (parent.stage.stageWidth - display.width) - 10;
				display.y = 10;
			case MapAlign.BottomLeft:
				display.x = 10;
				display.y = (parent.stage.stageHeight - display.height) - 10;
			case MapAlign.BottomRight:
				display.x = (parent.stage.stageWidth - display.width) - 10;
				display.y = (parent.stage.stageHeight - display.height) - 10;
			case MapAlign.Center:
				display.x = (parent.stage.stageWidth / 2) - (display.width / 2);
				display.y = (parent.stage.stageHeight / 2) - (display.height / 2);
		}
		
		if (showDebug) {
			debugDisplay.scaleX = debugDisplay.scaleY = display.scaleX;
			debugDisplay.x = display.x;
			debugDisplay.y = display.y;
		}
		
		return display;
	}
	
	public function generate():Void {
		
		while (totalLoops <= maxLoops) {
			if (numRooms == 0) { //First room
				var dType:DoorType = getRand(0, 1) == 0 ? DoorType.North : DoorType.West;
				currentRoomEntrance = new Door(0, 0, dType);
			} else {
				if (currentRoomEntrance.type == DoorType.South) {
					currentRoomEntrance.y++;
				} else {
					currentRoomEntrance.x++;
				}
			}
			
			currentRoomSize = getRoomSize();
			
			if (showDebug) {
				trace("Current room entrance : (" + currentRoomEntrance.x + "," + currentRoomEntrance.y + ")");
				//trace("Current room size : " + currentRoomSize.toString());
			}
			
			var room:Room = new Room(Std.int(currentRoomEntrance.x), Std.int(currentRoomEntrance.y), Std.int(currentRoomSize.x), Std.int(currentRoomSize.y));
			
			room.entrance = currentRoomEntrance;
			
			if (numRooms == 0) {
				if (room.entrance.type == DoorType.North) {
					room.entrance.x = Std.int(room.originX + (room.width / 2));
					room.entrance.y = 0;
				} else if (room.entrance.type == DoorType.West) {
					room.entrance.x = 0;
					room.entrance.y = Std.int(room.originY + (room.height / 2));
				}
			}
			
			//Compare currentRoomSize with previousRoomSize and align them
			//TODO: ALIGN CORRECTLY ACCORDING TO EVEN / ODD PREVIOUS AND CURRENT ROOM SIZES.
			if (numRooms != 0) {
				if (currentRoomEntrance.type == DoorType.South) {
					room.originX -= Std.int(room.width / 2);
				} else {
					room.originY -= Std.int(room.height / 2);
				}
			}
			
			//Door placement
			var southDoor:Door = new Door(Std.int(room.originX + (room.width / 2)), Std.int(room.originY + (room.height - 1)), DoorType.South);
			var eastDoor:Door = new Door(Std.int(room.originX + (room.width - 1)), Std.int(room.originY + (room.height / 2)), DoorType.East);
			room.doors = new Array<Door>();
			room.doors.push(southDoor);
			room.doors.push(eastDoor);
			
			if (checkRoomSpace(room) == true) {
				//Choose one the rooms' doors to be the currentRoomEntrance
				var nextDoorID:Int = getRand(0, 1);
				if (nextDoorID == 0) {
					currentRoomEntrance = room.doors[0];
					unusedDoors.push(room.doors[1]);
				} else {
					currentRoomEntrance = room.doors[1];
					unusedDoors.push(room.doors[0]);
				}
				
				//Print room
				printRoom(room);
				numRooms++;
				rooms.push(room);
			} else {
				//Try to reduce size of the room to make it fit
				if (reduceRoom(room) == true) {
					var nextDoorID:Int = getRand(0, 1);
					if (nextDoorID == 0) {
						currentRoomEntrance = room.doors[0];
						unusedDoors.push(room.doors[1]);
					} else {
						currentRoomEntrance = room.doors[1];
						unusedDoors.push(room.doors[0]);
					}
					
					//Print room
					printRoom(room);
					numRooms++;
					rooms.push(room);
				} else {
					if (unusedDoors[doorIndex] != null) {
						currentRoomEntrance = new Door(unusedDoors[doorIndex].x, unusedDoors[doorIndex].y, unusedDoors[doorIndex].type);
						doorIndex++;
					} else {
						doorIndex = 0;
						//currentRoomEntrance = new Door(unusedDoors[doorIndex].x, unusedDoors[doorIndex].y, unusedDoors[doorIndex].type);
						totalLoops++;
					}
				}
			}
		}
		
		trace("TOTAL ROOMS IN THE MAP : " + numRooms);
	}
	
	private function reduceRoom(room:Room):Bool {
		//Try to reduce -1w, then -1h, -2w & finally -2h
		//Then check to see if room is equal or larger than minimal space
		var minSize = 5;
		
		while (room.width > minSize || room.height > minSize) {
			room.width--;
			if (room.width < minSize) {
				room.width = minSize;
			}
			if (checkRoomSpace(room) == true) {
				var southDoor:Door = new Door(Std.int(room.originX + (room.width / 2)), Std.int(room.originY + (room.height - 1)), DoorType.South);
				var eastDoor:Door = new Door(Std.int(room.originX + (room.width - 1)), Std.int(room.originY + (room.height / 2)), DoorType.East);
				room.doors[0] = southDoor;
				room.doors[1] = eastDoor;
				//trace("reduceRoom -> ROOM FIT - final room size : " + room.width + "," + room.height);
				return true;
			}
			
			room.height--;
			if (room.height < minSize) {
				room.height = minSize;
			}
			if (checkRoomSpace(room) == true) {
				var southDoor:Door = new Door(Std.int(room.originX + (room.width / 2)), Std.int(room.originY + (room.height - 1)), DoorType.South);
				var eastDoor:Door = new Door(Std.int(room.originX + (room.width - 1)), Std.int(room.originY + (room.height / 2)), DoorType.East);
				room.doors[0] = southDoor;
				room.doors[1] = eastDoor;
				//trace("reduceRoom -> ROOM FIT - final room size : " + room.width + "," + room.height);
				return true;
			}
		}
		
		//trace("reduceRoom -> DID NOT FIT! final room size : " + room.width + "," + room.height);
		return false;
	}
	
	private function printRoom(room:Room):Void {
		var startX:Int = room.originX;
		var startY:Int = room.originY;
		var endX:Int = startX + room.width;
		var endY:Int = startY + room.height;
		
		room.layout = new Array<Array<Int>>();
		
		var indexCountX:Int = 0;
		var indexCountY:Int = 0;
		
		for (countY in startY...endY) {
			room.layout[indexCountY] = new Array<Int>();
			for (countX in startX...endX) {
				if (countX == startX && countY == startY) { // NW CORNER
					map.setPixel32(countX, countY, cNW_CORNER);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iNW_CORNER;
					
				} else if (countX == (endX - 1) && countY == startY) { // NE CORNER
					map.setPixel32(countX, countY, cNE_CORNER);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iNE_CORNER;
					
				} else if (countX == startX && countY == (endY - 1)) { // SW CORNER
					map.setPixel32(countX, countY, cSW_CORNER);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iSW_CORNER;
					
				} else if (countX == (endX - 1) && countY == (endY - 1)) { // SE CORNER
					map.setPixel32(countX, countY, cSE_CORNER);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iSE_CORNER;
					
				} else if (countX == room.entrance.x && countY == room.entrance.y) { //ENTRANCE
					map.setPixel32(room.entrance.x, room.entrance.y, cENTRANCE);
					room.layout[indexCountY][indexCountX] = iENTRANCE;
					
				} else if (countX == startX) { // WEST WALL
					map.setPixel32(countX, countY, cW_WALL);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iW_WALL;
					
				} else if (countY == startY) { // NORTH WALL
					map.setPixel32(countX, countY, cN_WALL);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iN_WALL;
					
				} else if (countX == room.doors[1].x && countY == room.doors[1].y) { //DOOR EAST
					map.setPixel32(countX, countY, cE_DOOR);
					//map.setPixel32(countX, countY, 0xFFFFD100);
					room.layout[indexCountY][indexCountX] = iE_DOOR;
					
				} else if (countX == (endX - 1)) { // EAST WALL
					map.setPixel32(countX, countY, cE_WALL);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iE_WALL;
					
				} else if (countX == room.doors[0].x && countY == room.doors[0].y) { //DOOR SOUTH
					map.setPixel32(countX, countY, cS_DOOR);
					room.layout[indexCountY][indexCountX] = iS_DOOR;
					
				} else if (countY == (endY - 1)) { // SOUTH WALL
					map.setPixel32(countX, countY, cS_WALL);
					//map.setPixel32(countX, countY, 0xFF4C57D8);
					room.layout[indexCountY][indexCountX] = iS_WALL;
					
				} else { // GROUND
					map.setPixel32(countX, countY, cFLOOR);
					room.layout[indexCountY][indexCountX] = iFLOOR;
				}
				
				indexCountX++;
			}
			
			indexCountX = 0;
			indexCountY++;
		}
	}
	
	public function extractData():Array<Array<Int>>
	{
		var w = map.width;
		var h = map.height;
		mapData = new Array<Array<Int>>();
		
		/*
		cNW_CORNER = 0xFFA30008;
		cNE_CORNER = 0xFFBC2F36;
		cSE_CORNER = 0xFFFD3F49;
		cSW_CORNER = 0xFFFD7279;
		cN_WALL = 0xFF1D0772;
		cE_WALL = 0xFF3F2D84;
		cS_WALL = 0xFF6749D7;
		cW_WALL = 0xFF856FD7;
		cS_DOOR = 0xFFFFD100;
		cE_DOOR = 0xFFBFA530;
		cENTRANCE = 0xFF82217A;
		cFLOOR = 0xFFFFFFFF;
		cNOTHING = 0xFF333333;
		 * */
		for (i in 0...h) {
			mapData[i] = new Array<Int>();
			for (j in 0...w) {
				#if (neko || cpp || html5)
				var pixel:UInt = map.getPixel32(j, i);
				#elseif flash
				var pixel:Float = map.getPixel32(j, i);
				#end
				switch (pixel) {
					
					#if (neko || cpp || html5)
					case 0xFFA30008: //NW CORNER
						mapData[i][j] = iNW_CORNER;
					case 0xFFBC2F36: //NE CORNER
						mapData[i][j] = iNE_CORNER;
					case 0xFFFD3F49: //SE CORNER
						mapData[i][j] = iSE_CORNER;
					case 0xFFFD7279: //SW CORNER
						mapData[i][j] = iSW_CORNER;
					case 0xFF1D0772: //NORTH WALL
						mapData[i][j] = iN_WALL;
					case 0xFF3F2D84: //EAST WALL
						mapData[i][j] = iE_WALL;
					case 0xFF6749D7: //SOUTH WALL
						mapData[i][j] = iS_WALL;
					case 0xFF856FD7: //WEST WALL
						mapData[i][j] = iW_WALL;
					case 0xFFFFD100: //SOUTH DOOR
						mapData[i][j] = iS_DOOR;
					case 0xFFBFA530: //EAST DOOR
						mapData[i][j] = iE_DOOR;
					case 0xFF82217A: //ENTRANCE
						mapData[i][j] = iENTRANCE;
					case 0xFFFFFFFF: //GROUND
						mapData[i][j] = iFLOOR;
					default: //EMPTY SPACE
						mapData[i][j] = iNOTHING;
					#elseif flash
					case 4288872456: //NW CORNER
						mapData[i][j] = iNW_CORNER;
					case 4290522934: //NE CORNER
						mapData[i][j] = iNE_CORNER;
					case 4294786889: //SE CORNER
						mapData[i][j] = iSE_CORNER;
					case 4294799993: //SW CORNER
						mapData[i][j] = iSW_CORNER;
					case 4280092530: //NORTH WALL
						mapData[i][j] = iN_WALL;
					case 4282330500: //EAST WALL
						mapData[i][j] = iE_WALL;
					case 4284959191: //SOUTH WALL
						mapData[i][j] = iS_WALL;
					case 4286934999: //WEST WALL
						mapData[i][j] = iW_WALL;
					case 4294955264: //SOUTH DOOR
						mapData[i][j] = iS_DOOR;
					case 4290749744: //EAST DOOR
						mapData[i][j] = iE_DOOR;
					case 4286718330: //ENTRANCE
						mapData[i][j] = iENTRANCE;
					case 4294967295: //GROUND
						mapData[i][j] = iFLOOR;
					default: //EMPTY SPACE
						mapData[i][j] = iNOTHING;
					#end
				}
			}
		}
		
		return mapData;
	}
	
	//HELPERS
	private function checkRoomSpace(room:Room):Bool {
		var startX:Int = room.originX;
		var startY:Int = room.originY;
		var endX:Int = startX + room.width;
		var endY:Int = startY + room.height;
		
		if (endX < 0 || endX > map.width || endY < 0 || endY > map.height) {
			if (showDebug) {
				//trace("checkRoomSpace -> Room out of boundaries");
				debugOverlay.fillRect(new Rectangle(0, 0, debugOverlay.width, debugOverlay.height), 0x4400CC00);
				debugOverlay.fillRect(new Rectangle(room.originX, room.originY, room.width, room.height), 0xFFFFFF66);
			}
			return false;
		}
		
		for (i in startY...endY) {
			for (j in startX...endX) {
				var pixel:UInt = map.getPixel32(j, i);
				if (pixel != 4281545523) {
					if (showDebug) {
						//trace("checkRoomSpace -> Room is overlaping other room");
						debugOverlay.fillRect(new Rectangle(0, 0, debugOverlay.width, debugOverlay.height), 0x4400CC00);
						debugOverlay.fillRect(new Rectangle(room.originX, room.originY, room.width, room.height), 0xFFFFFF66);
					}
					return false;
				}
			}
		}
		
		return true;
	}
	
	private function getRoomSize():Point {
/*		var minSize = 5;
		var maxSize = 11;*/
		var width:Int = getRand(minRoomSize, maxRoomSize);
		var height:Int = getRand(minRoomSize, maxRoomSize);
		return new Point(width, height);
	}
	
	private function getRand(min:Int, max:Int):Int {
		return Math.floor(min + (Math.random() * (max + 1 - min)));
	}
	
}