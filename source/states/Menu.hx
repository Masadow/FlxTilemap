package states;
import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;
import coffeegames.misc.TextList;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Menu extends FlxState
{
	var states:Array<Class<FlxState>>;

	override public function create()
	{
		super.create();

		#if (flash || html5)
		states = [Generator, Heights];
		var listEntries = ['1 - Map generator', '2 - Height Maps'];
		#else
		states = [Generator, Heights, Editor];
		var listEntries = ['1 - Map generator', '2 - Height Maps', '3 - Map Editor'];
		#end
		
		var list = new TextList(0, 0, 230, 'Choose a sample', listEntries);
		list.setPosition(FlxG.width / 2 - list.width / 2, FlxG.height / 2 - list.height / 2);
		list.setSelection( -1);
		add(list);
	}
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.ONE) {
			gotoState(0);
		}
		
		if (FlxG.keys.justPressed.TWO) {
			gotoState(1);
		}
		
		#if (!flash || html5)
		if (FlxG.keys.justPressed.THREE) {
			gotoState(2);
		}
		#end
	}
	
	public function gotoState(id:Int)
	{
		FlxG.camera.fade(FlxColor.BLACK, 0.3, false, function () { FlxG.switchState(Type.createInstance(states[id], [])); } );
	}
	
}