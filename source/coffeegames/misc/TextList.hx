package coffeegames.misc;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class TextList extends FlxGroup
{
	static inline var ITEM_HEIGHT:Float = 30;
	static inline var ITEM_OFFSET:Float = 10;
	
	public var pos:FlxPoint;
	public var width:Int;
	public var height:Int;
	
	var descriptions:Array<String>;
	var panel:FlxSprite;
	var title:FlxText;
	var items:Array<FlxText>;
	
	var selectedId:Int;
	
	public function new(x:Float, y:Float, w:Int, name:String, descr:Array<String>) 
	{
		super();
		
		pos = FlxPoint.get(x, y);
		width = w;
		descriptions = descr;
		height = Std.int(2 * ITEM_OFFSET + (descriptions.length + 1) * ITEM_HEIGHT);
		
		selectedId = 0;
		
		init(name);
	}
	
	function init(name:String)
	{
		panel = new FlxSprite(pos.x, pos.y);
		panel.makeGraphic(Std.int(2 * ITEM_OFFSET + width), height, 0xFF876581);
		panel.scrollFactor.set(0, 0);
		add(panel);
		
		title = new FlxText(ITEM_OFFSET + pos.x, pos.y + 10, width, '== $name ==', 16);
		title.setBorderStyle(FlxTextBorderStyle.OUTLINE_FAST, 0x222222, 2);
		title.color = FlxColor.RED;
		title.alignment = FlxTextAlign.CENTER;
		title.scrollFactor.set(0, 0);
		add(title);
		
		items = new Array<FlxText>();
		for (i in 0...descriptions.length) {
			var txt = new FlxText(ITEM_OFFSET + pos.x, ITEM_OFFSET + pos.y + ITEM_HEIGHT * (i + 1), width, descriptions[i], 16);
			txt.setBorderStyle(FlxTextBorderStyle.OUTLINE_FAST, 0x222222, 2);
			txt.alignment = FlxTextAlign.LEFT;
			txt.scrollFactor.set(0, 0);
			add(txt);
			items.push(txt);
		}
		
		setSelection(0, true);
	}
	
	public function setPosition(scrX:Float, scrY:Float)
	{
		var distX = pos.x - scrX; // distX < 0 -> to the right 
		var distY = pos.y - scrY;
		
		if (distX < 0)
			pos.x += distX * -1;
		else 
			pos.x -= distX;
			
		if (distY < 0)
			pos.y += distY * -1;
		else 
			pos.y -= distY;
			
		panel.setPosition(pos.x, pos.y);
		title.setPosition(ITEM_OFFSET + pos.x, pos.y + 10);
		for (i in 0...items.length)
			items[i].setPosition(ITEM_OFFSET + pos.x, ITEM_OFFSET + pos.y + ITEM_HEIGHT * (i + 1));
	}
	
	public function setSelection(id:Int, changeColor:Bool = true, ?text:String)
	{
		//Deselection
		if (id < 0) {
			items[selectedId].color = FlxColor.WHITE;
			return;
		}
		
		if (changeColor) {
			items[selectedId].color = FlxColor.WHITE;
			items[id].color = FlxColor.GREEN;
		}
		
		if (text != null)
			items[id].text = text;
			
		selectedId = id;
	}
	
	override private function set_cameras(Value:Array<FlxCamera>):Array<FlxCamera>
	{
		for (i in 0...members.length) {
			members[i].cameras = Value;
		}
		
		return _cameras = Value;
	}
	
}