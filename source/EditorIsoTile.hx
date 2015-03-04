package;
import flixel.addons.display.shapes.FlxShape;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;
import openfl.geom.Matrix;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class EditorIsoTile extends FlxShape
{
	var tile_w:Float;
	var tile_h:Float;
	var tile_d:Float;
	
	public function new(X:Float, Y:Float, w:Float, h:Float, d:Float, LineStyle_:LineStyle) 
	{
		tile_w = w;
		tile_h = h;
		tile_d = d;
		
		super(X, Y, 0, 0, LineStyle_, FlxColor.TRANSPARENT, w, h + d);
		
		
	}
	
	override public function drawSpecificShape(?matrix:Matrix):Void 
	{
		FlxSpriteUtil.drawLine(this, x + tile_w / 2, y + tile_h, x + tile_w, y + tile_h + tile_d / 2, lineStyle, { matrix: matrix } );
		
		FlxSpriteUtil.drawLine(this, x + tile_w, y + tile_h + tile_d / 2, x + tile_w / 2, y + tile_h + tile_d, lineStyle, { matrix: matrix });
		FlxSpriteUtil.drawLine(this, x + tile_w / 2, y + tile_h + tile_d, x, y + tile_h + tile_d / 2, lineStyle, { matrix: matrix });
		FlxSpriteUtil.drawLine(this, x, y + tile_h + tile_d / 2, x + tile_w / 2, y + tile_h, lineStyle, { matrix: matrix });
	}
	
/*	private inline function onSetPoint(p:FlxPoint):Void 
	{
		updatePoint();
	}
	
	private function updatePoint():Void
	{
		shapeWidth = Math.abs(point.x - point2.x);
		shapeHeight = Math.abs(point.y - point2.y);
		if (shapeWidth <= 0) shapeWidth = 1;
		if (shapeHeight <= 0) shapeHeight = 1;
		shapeDirty = true;
	}*/
	
	override public function get_strokeBuffer():Float
	{
		return lineStyle.thickness * 2.0;
	}
	
	private override function getStrokeOffsetX():Float
	{
		return strokeBuffer / 2;
	}
	
	private override function getStrokeOffsetY():Float
	{
		return strokeBuffer / 2;
	}
	
}