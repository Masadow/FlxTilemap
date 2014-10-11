package ;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxPath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import tile.FlxIsoTilemap;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class FlxIsoSprite extends FlxSprite
{
	//0 - R; 1 - SE; 2 - S; 3 - SW; 4 - L; 5 - NW; 6 - N; 7 - NE
	var isoFacing:Int;
	public var isoRect:IsoRect;
	public var automaton:Bool;
	
	public var controller:Void->Void;
	
	//Automaton
	var isWalking:Bool;
	var destination:FlxPoint;
	var lastFacing:Int;
	var path:FlxPath;
	var movementRanges:Array<Int> = [30, 60, 120, 150, 180];
	
	public function new(X:Float = 0, Y:Float = 0, automaton:Bool, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		this.automaton = automaton;
		init();
	}
	
	function init() 
	{
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
		
		maxVelocity.x = 240;
		maxVelocity.y = 120;
		
		isoRect = new IsoRect(this.x, this.y, this.width, this.height, this);
		isoRect.depthModifier = 1000;
		
		controller = automaton ? handleMovement : handleInput;
		
		if (automaton)
		{
			isWalking = false;
			destination = FlxPoint.get(0, 0);
			lastFacing = -1;
			path = new FlxPath(null, [], 240, FlxPath.FORWARD, false);
		}
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		velocity.x = velocity.y = 0;
		
		controller();
	}
	
	function handleInput() 
	{
		if (FlxG.keys.pressed.UP) {
			animation.play("walk_ne");
			velocity.x = 120;
			velocity.y = -60;
			isoFacing = 0;
		}
		if (FlxG.keys.pressed.DOWN) {
			animation.play("walk_sw");
			velocity.x = -120;
			velocity.y = 60;
			isoFacing = 1;
		}
		if (FlxG.keys.pressed.LEFT) {
			animation.play("walk_nw");
			velocity.x = -120;
			velocity.y = -60;
			isoFacing = 2;
		}
		if (FlxG.keys.pressed.RIGHT) {
			animation.play("walk_se");
			velocity.x = 120;
			velocity.y = 60;
			isoFacing = 3;
		}
		
		if (FlxG.keys.anyPressed(["UP", "DOWN", "LEFT", "RIGHT"])) {
			adjustPosition();
		}
		
		if (FlxG.keys.anyJustReleased(["UP", "DOWN", "LEFT", "RIGHT"])) {
			setAnimation();
		}
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
	
	function resetPath(path:FlxPath) 
	{
		isWalking = false;
		path.reset();
	}
	
	function move() 
	{
		path.update(FlxG.elapsed);
		adjustPosition();
	}
	
	function setAnimation()
	{
		switch (isoFacing) {
			case 0:
				animation.play("idle_ne");
			case 1:
				animation.play("idle_sw");
			case 2:
				animation.play("idle_nw");
			case 3:
				animation.play("idle_se");
			default:
				animation.play("idle_ne");
		}
		
	}
	
	override public function setPosition(X:Float = 0, Y:Float = 0):Void
	{
		super.setPosition(X, Y);
		
		adjustPosition();
	}
	
	public function setTilePosition(X:Int, Y:Int):Void
	{
		this.x = X * 48;
		this.y = X * 24;
		
		adjustPosition();
	}
	
	/**
	 * Keeps track and adjusts position inside a FlxIsoTilemap
	 */
	function adjustPosition()
	{
		var motionDiffX = this.x - last.x;
		var motionDiffY = this.y - last.y;
		var newIsoX = isoRect.isoPos.x + motionDiffX;
		var newIsoY = isoRect.isoPos.y + motionDiffY;
		isoRect.setIso(newIsoX, newIsoY);
		isoRect.depth = Std.int(isoRect.isoPos.y * isoRect.depthModifier + isoRect.isoPos.x);
	}
}