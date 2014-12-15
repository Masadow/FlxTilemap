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
	
	public function new(sprite:FlxIsoSprite) 
	{
		this.sprite = sprite;
		isoPos = new Point( -1, -1);
		depth = -1;
		depthModifier = -1;
		index = -1;
		mapPos = { x: 0, y: 0 };
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
	
	public function clone():IsoContainer
	{
		var container = new IsoContainer(null);
		
		container.isoPos = this.isoPos;
		container.depth = this.depth;
		container.sprite = this.sprite;
		container.depthModifier = this.depthModifier;
		container.index = this.index;
		container.mapPos = this.mapPos;
		
		return container;
	}
	
	public function toString():String
	{
		return "IsoContainer at '" + mapPos.x + "," + mapPos.y + "' - index : '" + index + "' - pos : " + isoPos.toString() + " - depth : " + depth + " - modifier : " + depthModifier + " - sprite : " + sprite;
	}
}

typedef MapPos = {
	x:Int,
	y:Int
}