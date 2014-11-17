package;
import flixel.FlxSprite;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class FlxIsoSprite extends FlxSprite
{
	//0 - E; 1 - SE; 2 - S; 3 - SW; 4 - W; 5 - NW; 6 - N; 7 - NE
	var isoFacing:Int;
	public var isoContainer:IsoContainer;
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		
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
		super.setPosition(X, Y - height / 2);
		
		adjustPosition();
	}
	
	/**
	 * Sets the world position of the sprite with tile index positions
	 * @param	X	The tile column position in the map
	 * @param	Y	The tile row position in the map
	 */
	public function setTilePosition(X:Int, Y:Int):Void
	{
		this.x = X * 48;
		this.y = X * 24;
		
		adjustPosition();
	}
	
	/**
	 * Internal method to adjust sprite position inside a FlxIsoTilemap
	 */
	function adjustPosition()
	{
		var motionDiffX = this.x - last.x;
		var motionDiffY = this.y - last.y;
		var newIsoX = isoContainer.isoPos.x + motionDiffX;
		var newIsoY = isoContainer.isoPos.y + motionDiffY;
		isoContainer.setIso(newIsoX, newIsoY);
		isoContainer.depth = Std.int(isoContainer.isoPos.y * isoContainer.depthModifier + isoContainer.isoPos.x);
	}
}