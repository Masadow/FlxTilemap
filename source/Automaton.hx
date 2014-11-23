package;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxPath;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Automaton extends FlxIsoSprite
{
	var isWalking:Bool;
	var destination:FlxPoint;
	var lastFacing:Int;
	var path:FlxPath;
	var movementRanges:Array<Int> = [30, 60, 120, 150, 180];
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		
		//loadGraphic("images/char_3.png", true, 48, 48);
		loadGraphic("images/char_4.png", true, 48, 72);
		
		animation.add("idle_se", [0], 12, true);
		animation.add("idle_sw", [3], 12, true);
		animation.add("idle_nw", [6], 12, true);
		animation.add("idle_ne", [9], 12, true);
		
		animation.add("walk_se", [0, 1, 2], 12, true);
		animation.add("walk_sw", [3, 4, 5], 12, true);
		animation.add("walk_nw", [6, 7, 8], 12, true);
		animation.add("walk_ne", [9, 10, 11], 12, true);
		
		animation.play("idle_se");
		
		isWalking = false;
		destination = FlxPoint.get(0, 0);
		lastFacing = -1;
		path = new FlxPath();
	}
	
	function handleMovement()
	{
		if (!isWalking)
		{
			setDestination();
		}
		
		if (isWalking)
		{
			move();
		}
	}
	
	function setDestination()
	{
		lastFacing = isoFacing;
		isoFacing = FlxG.random.int(0, 3, [lastFacing]);
		
		var dirX:Int = 0;
		var dirY:Int = 0;
		switch (isoFacing)
		{
			case 0:	//NE
				dirX = 1;
				dirY = -1;
				animation.play("walk_ne");
			case 1:	//SW
				dirX = -1;
				dirY = 1;
				animation.play("walk_sw");
			case 2:	//NW
				dirX = -1;
				dirY = -1;
				animation.play("walk_nw");
			case 3:	//SE
				dirX = 1;
				dirY = 1;
				animation.play("walk_se");
		}
		
		var range:Int = FlxG.random.getObject(movementRanges);
		destination.x = Math.floor(this.x) + range * dirX;
		destination.y = Math.floor(this.y) + (range / 2) * dirY;
		path.start(this, [destination], 80, FlxPath.FORWARD);
		path.onComplete = resetPath;
		
		isWalking = true;
	}

	function move() 
	{
		path.update(FlxG.elapsed);
		adjustPosition();
	}
	
	function resetPath(path:FlxPath) 
	{
		isWalking = false;
		path.reset();
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		handleMovement();
	}
}