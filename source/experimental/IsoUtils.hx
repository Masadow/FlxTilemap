package experimental;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class IsoUtils
{
	/**
	 * Sorts a range of tiles inside an array using the insertion sort algorithm.
	 * Adapted from the original code by
	 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
	 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
	 * @param	a		The array to be sorted
	 * @param	compare	The comparing function to be used
	 * @param	first	Starting index for the comparison
	 * @param	count	The length of items to be compared starting from 'first'
	 */
	public static function sortRange(a:Array<IsoContainer>, compare:IsoContainer->IsoContainer->Int, first:Int, count:Int)
	{
		var k = a.length;
		if (k > 1)
		{
			_insertionSort(a, first, count, compare);
		}
	}
	
	private static function _insertionSort(a:Array<IsoContainer>, first:Int, k:Int, cmp:IsoContainer->IsoContainer->Int)
	{
		for (i in first + 1...first + k)
		{
			var x = a[i];
			var j = i;
			while (j > first)
			{
				var y = a[j - 1];
				if (cmp(y, x) > 0)
				{
					a[j] = y;
					j--;
				}
				else
					break;
			}
			
			a[j] = x;
		}
	}
	
	/**
	 * Internal, simple function used to compare two values from an array
	 * Used by sortRange function
	 * @param	a	The first value to compare
	 * @param	b	The second value to compare
	 * @return		An int representing the difference between values a and b
	 */
	private static function compareNumberRise(a:IsoContainer, b:IsoContainer):Int
	{
		return a.depth - b.depth;
	}
	
	//Bucket sort - uncomment to return 1d flattened array
	//Currently returns a 2d array
	//public static function bucketSort(arr:Array<IsoContainer>):Array<IsoContainer>
	public static function bucketSort(arr:Array<IsoContainer>):Array<Array<IsoContainer>>
	{
		var highestDepthModifier:Int = 10;
		var maxDepth:Int = this.widthInTiles * highestDepthModifier + this.heightInTiles;
		
		var buckets = new Array<Array<IsoContainer>>();
		for (i in 0...maxDepth) {
			buckets[i] = new Array<IsoContainer>();
		}
		
		for (j in 0...arr.length) {
			buckets[arr[j].depth].push(arr[j]);
		}
		
		//Flatten - returns a sorted 1D array
/*		var result = new Array<IsoContainer>();
		for (i in 0...buckets.length) {
			for (j in 0...buckets[i].length) {
				result.push(buckets[i][j]);
			}
		}*/
		
		var count:Int = 0;
		var maxLength:Int = 0;
		for (k in 0...buckets.length) {
			if (buckets[k].length == 0) {
				count++;
			}
			
			if (buckets[k].length > maxLength) {
				maxLength = buckets[k].length;
			}
		}
		
		trace("Total empty buckets : " + count);
		trace("Max bucket size : " + count);
		
		//return result;
		return buckets;
	}
}