FlxTilemap
==========

### Features to Implement

 * Heights
 * Slopes
 * Bridges
 * Bigger-than-tile objects;

### Known Bugs

 * Pathfinding don't work, 'findPath()' returns null;
 * Floating-point tilemap tearing in Flash (very easy to spot when scrolling the camera);
 * Collisions not working correctly (callbacks dispatching regardless of position and tile type);

### Targets

 * [x] flash
 * [x] html5 (must disable openfl-bitfive html5 backend)
 * [x] desktop (cpp & neko)
 * [x] android
 * [ ] ios (should work, test needed)

### Misc

 * Sorting optimization - Currently sorting the entire tilemap (huge impact on performance)
 * General performance improvement