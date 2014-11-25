package;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import tile.FlxIsoTilemap;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class FlxIsoSprite extends FlxSprite
{
	//0 - E; 1 - SE; 2 - S; 3 - SW; 4 - W; 5 - NW; 6 - N; 7 - NE
	var isoFacing:Int;
	public var motionDiffX:Float;
	public var motionDiffY:Float;
	public var isoContainer:IsoContainer;
	public var map:FlxIsoTilemap;
	
	public var mustSort:Bool;
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		
		mustSort = true;
		
		isoContainer = new IsoContainer(this);
		isoContainer.depthModifier = 1000;
		isoContainer.index = 0;
		isoFacing = 0;
	}
	
	/**
	 * Sets the world position of the sprite in world coordinates
	 * @param	X	The sprite x position in world coordinates
	 * @param	Y	The sprite y position in world coordinates
	 */
	override public function setPosition(X:Float = 0, Y:Float = 0):Void
	{
		super.setPosition(X, Y);
		
		adjustPosition();
	}
	
	/**
	 * Internal method to adjust sprite position inside a FlxIsoTilemap
	 */
	function adjustPosition()
	{
		motionDiffX = this.x - last.x;
		motionDiffY = this.y - last.y;
		
		var newIsoX = isoContainer.isoPos.x + motionDiffX;
		var newIsoY = isoContainer.isoPos.y + motionDiffY;
		
		var newTile = map.getIsoTileByCoords(FlxPoint.weak(newIsoX, newIsoY), false);
		
		isoContainer.mapPos = newTile.mapPos;
		isoContainer.depth = Std.int(newIsoY * isoContainer.depthModifier + newIsoX);
		
		isoContainer.setIso(newIsoX, newIsoY);
	}
}