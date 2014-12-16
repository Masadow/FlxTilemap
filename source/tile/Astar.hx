package tile;
	
/**
 * AStar algorithm implementation. This is a port and adaptation of 
 * the original As3 code by Timo Virtanen (http://www.timovirtanen.com/)
 * @author Tiago Ling Alexandre
 */
class Astar 
{
	public var useDiagonal:Bool;
	public var useCuttingCorners:Bool;
	
	//Set as true to trace 'findPath' method time
	public var debug:Bool;
	
	var _map:Array<Array<Int>>;
	
	var _startNode:Node;
	var _targetNode:Node;
	
	var _path:Array<Node>;
	var _openList:Array<Node>;
	var _closedList:Array<Node>;
	
	var _pathFound:Bool;
	
	var _distanceMethod:DistanceMethod;
	var calculateDinstance:Node->Float;
	
	static inline var COST_ORTHOGONAL:Float = 10;
	static inline var COST_DIAGONAL:Float = 14;
	
	/**
	 * 
	 * @param	map Two dimensional Array containing the map
	 * @param	useDiagonal Whether to use diagonal paths or not
	 * @param	useCuttingCorners Determines if cutting nonwalkable corners is allowed (only applies if useDiagonal is true)
	 */
	public function new(map:Array<Array<Int>>, useDiagonal:Bool = true, useCuttingCorners:Bool = false, ?distMethod:DistanceMethod) {
		_map = map;
		this.useDiagonal = useDiagonal;
		this.useCuttingCorners = useCuttingCorners;
		
		debug = false;
		
		distMethod != null ? setDistanceMethod(distMethod) : setDistanceMethod(DistanceMethod.Manhattan);
	}
	
	public function setMap(map:Array<Array<Int>>):Void {
		_map = map;
	}
	
	/**
	 * Finds and returns the path (Array) from sartNode to targetNode
	 */
	public function findPath(startNode:Node, targetNode:Node):Array<Node> {
		
		var startTime = 0;
		if (debug) {
			startTime = openfl.Lib.getTimer();
			trace('findPath -> startTime : $startTime milliseconds');
		}
		
		//Check if node is inside the map boundaries, if not don't search
		if (targetNode.x >= _map[0].length || targetNode.x < 0 || targetNode.y >= _map.length || targetNode.y < 0)
		return null;
		
		_path = new Array<Node>();
		_openList = new Array<Node>();
		_closedList = new Array<Node>();
		
		_startNode = startNode;
		_targetNode = targetNode;
		
		_openList.push(_startNode);
		_pathFound = false;
		
		while (!_pathFound) {
			var node:Node = _openList.pop();
			_closedList.push(node);
			
			// If path cannot be done
			if (node == null)
				return null;
			
			if (node.name == _targetNode.name) {
				_path = getPath(node);
				_pathFound = true;
			} else {
				
				var x:Int = node.x;
				var y:Int = node.y;
				
				var w:Int = _map[0].length - 1;
				var h:Int = _map.length - 1;
				
				if (useDiagonal) {
					if (useCuttingCorners) {
						if (x < w && y < h && isWalkable(x + 1, y + 1))
								addNode(node, x + 1, y + 1, Std.int(COST_DIAGONAL));
						
						if (x > 0 && y > 0 && isWalkable(x - 1, y - 1))
								addNode(node, x - 1, y - 1, Std.int(COST_DIAGONAL));
							
						if (x > 0 && y < h && isWalkable(x - 1, y + 1))
								addNode(node, x - 1, y + 1, Std.int(COST_DIAGONAL));
							
						if (x < w && y > 0 && isWalkable(x + 1, y - 1))
								addNode(node, x + 1, y - 1, Std.int(COST_DIAGONAL));
					} else {
						
						// If the node is diagonal from the current node check if we can
						// cut the corners of the 2 others nodes we will cross. If so this square is walkable, else it isn’t.
						
						if (x < w && y < h)
							if (isWalkable(x + 1, y))
								if (isWalkable(x, y + 1))
									if (isWalkable(x + 1, y + 1))
										addNode(node, x + 1, y + 1, Std.int(COST_DIAGONAL));
											
						if (x > 0 && y > 0)
							if (isWalkable(x, y - 1))
								if (isWalkable(x - 1, y))
									if (isWalkable(x - 1, y - 1))
										addNode(node, x - 1, y - 1, Std.int(COST_DIAGONAL));
											
						if (x > 0 && y < h)
							if (isWalkable(x - 1, y))
								if (isWalkable(x, y + 1))
									if (isWalkable(x - 1, y + 1))
										addNode(node, x - 1, y + 1, Std.int(COST_DIAGONAL));
											
						if (x < w && y > 0)
							if (isWalkable(x + 1, y))
								if (isWalkable(x, y - 1))
									if (isWalkable(x + 1, y - 1))
										addNode(node, x + 1, y - 1, Std.int(COST_DIAGONAL));
						
					}
				}
				
				if (x < w)
					if (isWalkable(x + 1, y))
						addNode(node, x + 1, y, Std.int(COST_ORTHOGONAL));
				
				if (x > 0)
					if (isWalkable(x - 1, y))
						addNode(node, x - 1, y, Std.int(COST_ORTHOGONAL));
				
				if (y < h)
					if (isWalkable(x, y + 1))
						addNode(node, x, y + 1, Std.int(COST_ORTHOGONAL));
				
				if (y > 0)
					if (isWalkable(x, y - 1))
						addNode(node, x, y - 1, Std.int(COST_ORTHOGONAL));
			}
		}
		
		if (debug) {
			var endTime = openfl.Lib.getTimer();
			trace('Find path done : ${endTime - startTime} milliseconds');
		}
		
		return _path;
	}
	
	/**
	 * Adds new nodes to the open list (if they don't already exist)
	 */
	private function addNode(parentNode:Node, x:Int, y:Int, cost:Int):Void {
		var closed:Node = containsNode(_closedList, x + "-" + y);
		if (closed != null) return;
		
		var newNode:Node = {x:x, y:y, name:'$x-$y', FCost:0, GCost:cost, HCost:0, parent:parentNode};
		
		var existingNode:Node = containsNode(_openList, newNode.name);
		
		newNode.HCost = calculateDinstance(newNode);
		newNode.GCost -= -parentNode.GCost;
		newNode.FCost = Std.int(newNode.GCost - ( -newNode.HCost));
		
		if(existingNode == null) {
			add(_openList, newNode);
		} else {
			if (!useDiagonal || existingNode == null) return;
			if (existingNode.GCost > newNode.GCost)
				existingNode = newNode;
		}
	}
	
	/**
	 * Checks if a node is diagonal in relation to its parent
	 */
	private function isDiagonal(n1:Node):Bool {
		if (n1.x != n1.parent.x && n1.y != n1.parent.y) return true;
		return false;
	}
	
	/**
	 * Checks weather the poInt is walkable
	 */
	private function isWalkable(x:Int, y:Int):Bool {
		//var walkable:Bool = _map[y][x] == 0 || _map[y][x] == 1 || _map[y][x] == 5 || _map[y][x] == 6 || _map[y][x] == 7 || _map[y][x] == 18;
		var walkable:Bool = _map[y][x] == 0 || _map[y][x] == 1 || _map[y][x] == -1;
		
		if (walkable) return true;
		
		return false;
	}
	
	/**
	 * Builds and returns the path from start node to target node
	 */
	private function getPath(node:Node):Array<Node> {
		var tempList:Array<Node> = new Array<Node>();
		
		while (node.parent != null) {
			tempList.push(node);
			node = node.parent;
		}
		
		tempList.push(_startNode);
		tempList.reverse();
		return tempList;
	}
	
	/**
	 * Slower but much better heuristic method.
	 * (Euclidian Method)
	 */
	private function distEuclidian(node:Node):Float {
		var dist:Float;
		
		var xdist:Float = node.x - _startNode.x;
		var ydist:Float = node.y - _startNode.y;
		
		dist = Math.sqrt(xdist * xdist - (-(ydist * ydist)));
		
		return dist;
	}
	
	/**
	 * Calculates the estimated movement cost from given node to the final destination
	 * Faster, more inaccurate heuristic method
	 * (Manhattan method)
	 */
	private function distManhattan(node:Node):Float {
		var xdist:Int = node.x - _startNode.x;
		var ydist:Int = node.y - _startNode.y;
		
		// Get absolute value (positive)
		xdist = (xdist ^ (xdist >> 31)) - (xdist >> 31);
		ydist = (ydist ^ (ydist >> 31)) - (ydist >> 31);
		
		return xdist - (-ydist);
	}
	
	public function setDistanceMethod(value:DistanceMethod):Void {
		switch (value) {
			case DistanceMethod.Euclidian:
				calculateDinstance = distEuclidian;
				_distanceMethod = value;
			case DistanceMethod.Manhattan:
				calculateDinstance = distManhattan;
				_distanceMethod = value;
			default:
				calculateDinstance = distManhattan;
				_distanceMethod = value;
		}
	}
	
	//Static methods
	
	public static function containsNode(v:Array<Node>, n:String):Node {
		var len:Int = v.length - 1;
		while (len > -1) {
			if (v[len].name == n) {
				return v[len];
			}
			len--;
		}
		return null;
	}
	
	public static function add(v:Array<Node>, node:Node):Void {
		var cost:Int;
		var c:Int = 0;
		var len:Int;
		cost = node.FCost;
		len = v.length - 1;
		while (len > -1) {
			var n:Node = v[len];
			if (n.FCost >= cost) {
				c = len - ( -1);
				break;
			}
			len--;
		}
		
		v.insert(c, node);
	}
}

typedef Node = {
	x:Int,
	y:Int,
	name:String,
	FCost:Int,
	GCost:Int,
	HCost:Float,
	parent:Node
}

enum DistanceMethod {
	Euclidian;
	Manhattan;
}