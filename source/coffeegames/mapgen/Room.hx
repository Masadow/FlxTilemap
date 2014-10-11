package coffeegames.mapgen;
import flash.geom.Point;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Room
{
	public var originX:Int;
	public var originY:Int;
	public var width:Int;
	public var height:Int;
	public var depth:Int;
	public var entrance:Door;
	public var doors:Array<Door>;
	public var layout:Array<Array<Int>>;
	
	public function new(x:Int, y:Int, width:Int, height:Int)
	{
		originX = x;
		originY = y;
		this.width = width;
		this.height = height;
		depth = 0;
		entrance = null;
		doors = null;
		layout = null;
	}
	
/*	public function toString():Void
	{
		trace(" ### Room data ### ");
		trace(" ### Origin : " + originX + "," + originY + " | size : " + width + " x " + height);
		trace(" ### Depth : " + depth + " | entrance " + entrance);
		trace(" ### Doors : " + doors + " | layout : ");
		if (layout != null)
		{
			for (i in 0...layout.length)
			{
				trace(layout[i]);
			}
		} else {
			trace("layout is null");
		}
	}*/
}