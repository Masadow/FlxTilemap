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
class Player extends FlxIsoSprite
{
	public var isWalking:Bool;
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		init();
	}
	
	function init() 
	{
		isWalking = false;
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
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		velocity.x = velocity.y = 0;
		
		handleInput();
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
}