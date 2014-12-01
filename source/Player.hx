package ;
import flixel.FlxG;
import flixel.FlxObject;
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
class Player extends FlxIsoSprite
{
	public var isWalking:Bool;
	
	var path:FlxPath;
	var pathPoints:Array<FlxPoint>;
	var pathSpeed:Float;
	var pathPos:Int;
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		init();
	}
	
	function init() 
	{
		isWalking = false;
		loadGraphic("images/new_char.png", true, 64, 96);
		
		setFacingFlip(FlxObject.RIGHT, false, false);
		setFacingFlip(FlxObject.LEFT, true, false);
		
		animation.add("idle_n", [0], 12, true);
		animation.add("idle_s", [5], 12, true);
		
		animation.add("walk_n", [0, 1, 2, 3, 4], 12, true);
		animation.add("walk_s", [5, 6, 7, 8, 9], 12, true);
		
		animation.play("idle_s");
		
		maxVelocity.x = 240;
		maxVelocity.y = 120;
		
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		//Disabled keyboard input
		//velocity.x = velocity.y = 0;
		//handleInput();
		
		switch (isoFacing) {
			case 0:
				set_facing(FlxObject.RIGHT);
			case 1:
				set_facing(FlxObject.LEFT);
			case 2:
				set_facing(FlxObject.LEFT);
			case 3:
				set_facing(FlxObject.RIGHT);
			default:
				set_facing(FlxObject.RIGHT);
		}
		
		if (isWalking) {
			adjustPosition();
			mustSort = true;
		} else {
			mustSort = false;
		}
	}
	
	function handleInput() 
	{
		if (FlxG.keys.pressed.UP) {
			animation.play("walk_n");
			set_facing(FlxObject.RIGHT);
			velocity.x = 120;
			velocity.y = -60;
			isoFacing = 0;
		}
		if (FlxG.keys.pressed.DOWN) {
			animation.play("walk_s");
			set_facing(FlxObject.LEFT);
			velocity.x = -120;
			velocity.y = 60;
			isoFacing = 1;
		}
		if (FlxG.keys.pressed.LEFT) {
			animation.play("walk_n");
			set_facing(FlxObject.LEFT);
			velocity.x = -120;
			velocity.y = -60;
			isoFacing = 2;
		}
		if (FlxG.keys.pressed.RIGHT) {
			animation.play("walk_s");
			set_facing(FlxObject.RIGHT);
			
			velocity.x = 120;
			velocity.y = 60;
			isoFacing = 3;
		}
		
		if (FlxG.keys.anyPressed(["UP", "DOWN", "LEFT", "RIGHT"])) {
			isWalking = true;
			adjustPosition();
		}
		
		if (FlxG.keys.anyJustReleased(["UP", "DOWN", "LEFT", "RIGHT"])) {
			isWalking = false;
			setAnimation();
		}
	}
	
	function setAnimation()
	{
		switch (isoFacing) {
			case 0:
				animation.play("idle_n");
				set_facing(FlxObject.RIGHT);
			case 1:
				animation.play("idle_s");
				set_facing(FlxObject.LEFT);
			case 2:
				animation.play("idle_n");
				set_facing(FlxObject.LEFT);
			case 3:
				animation.play("idle_s");
				set_facing(FlxObject.RIGHT);
			default:
				animation.play("idle_n");
				set_facing(FlxObject.RIGHT);
		}
		
	}
	
	public function walkPath(points:Array<FlxPoint>, speed:Float)
	{
		pathPoints = points;
		pathSpeed = speed;
		pathPos = 0;
		
		if (path == null)
			path = new FlxPath();
			
		setDirection();
		
		path.start(this, [pathPoints[pathPos]], pathSpeed, FlxPath.FORWARD, false);
		path.onComplete = checkPath;
		isWalking = true;
	}
	
	function checkPath(p:FlxPath)
	{
		pathPos++;
		if (pathPos >= pathPoints.length) {
			isWalking = false;
			path.reset();
			setAnimation();
			
			trace("Player final position : " + isoContainer.toString());
		} else {
			
			setDirection();
			
			path.reset();
			path.start(this, [pathPoints[pathPos]], pathSpeed, FlxPath.FORWARD, false);
			path.onComplete = checkPath;
		}
	}
	
	/**
	 * Check new direction and adjust facing / animation
	 */
	function setDirection()
	{
		var dirX:Int = 0;
		var dirY:Int = 0;
		if (pathPos > 0) {
			dirX = Std.int(pathPoints[pathPos].x - pathPoints[pathPos - 1].x);
			dirY = Std.int(pathPoints[pathPos].y - pathPoints[pathPos - 1].y);
		} else {
			dirX = Std.int(pathPoints[pathPos].x - isoContainer.isoPos.x);
			dirY = Std.int(pathPoints[pathPos].y - isoContainer.isoPos.y);
		}
		
		if (dirX > 0 && dirY > 0) { //SE
			isoFacing = 3;
			animation.play("walk_s");
			set_facing(FlxObject.RIGHT);
		}
		
		if (dirX < 0 && dirY > 0) { //SW
			isoFacing = 1;
			animation.play("walk_s");
			set_facing(FlxObject.LEFT);
		} 
		
		if (dirX < 0 && dirY < 0) { //NW
			isoFacing = 2;
			animation.play("walk_n");
			set_facing(FlxObject.LEFT);
		} 
		if (dirX > 0 && dirY < 0) { //NE
			isoFacing = 0;
			animation.play("walk_n");
			set_facing(FlxObject.RIGHT);
		}
	}
}