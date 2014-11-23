package ;
import flash.geom.Point;
import flixel.FlxSprite;

/**
 * Container class to hold iso tile properties, 
 * used with a FlxIsoTilemap
 * @author Tiago Ling Alexandre
 */
class IsoContainer
{
	/**
	 * Transformed x and y position in isometric coordinates
	 */
	public var isoPos:Point;
	
	/**
	 * Sorting depth inside the map array
	 */
	public var depth:Int;
	
	/**
	 * Reference to the sprite containing this IsoContainer
	 */
	//public var sprite:FlxSprite;
	public var sprite:FlxIsoSprite;
	
	/**
	 * Modifier to keep certain types of tiles always above or below other types
	 */
	public var depthModifier:Int;
	
	/**
	 * Reference to the tile index in the tileset
	 */
	public var index:Int;
	
	/**
	 * Stores row and column references
	 */
	public var mapPos:MapPos;
	
	//TEMP
	public var dataIndex:Int;
	
	//public function new(sprite:FlxSprite) 
	public function new(sprite:FlxIsoSprite) 
	{
		this.sprite = sprite;
		isoPos = new Point( -1, -1);
		depth = -1;
		depthModifier = -1;
		index = -1;
		mapPos = { x: -1, y: -1 };
	}
	
	/**
	 * Helper method to set the isometric x and y position
	 * @param	x	The isometric X position
	 * @param	y	The isometric Y position
	 */
	public function setIso(x:Float, y:Float):Void
	{
		isoPos.x = x;
		isoPos.y = y;
	}
	
	/**
	 * Helper method to set the position in the map (column,row)
	 * @param	x	The column this object is in the map
	 * @param	y	The row this object is in the map
	 */
	public function setMap(x:Int, y:Int):Void
	{
		mapPos.x = x;
		mapPos.y = y;
	}
	
	public function toString():String
	{
		return "IsoContainer at '" + mapPos.x + "," + mapPos.y + "' - type : '" + index + "' - pos : " + isoPos.toString() + " - depth : " + depth + " - modifier : " + depthModifier + " - sprite : " + sprite;
	}
}

typedef MapPos = {
	x:Int,
	y:Int
}