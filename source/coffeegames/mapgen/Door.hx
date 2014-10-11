package coffeegames.mapgen;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Door
{
	public var x:Int;
	public var y:Int;
	public var type:DoorType;
	
	public function new(x:Int, y:Int, type:DoorType) 
	{
		this.x = x;
		this.y = y;
		this.type = type;
	}
	
}