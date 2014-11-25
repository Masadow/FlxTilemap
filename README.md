FlxTilemap
==========

Isometric tilemap implementation for HaxeFlixel.

### Features to Implement

 * Heights
 * Slopes
 * Bridges
 * Bigger-than-tile objects;

### Known Bugs

 * [New] Map culling broke camera zoom, must be fixed;
 * [New] Sorting is working only for the player sprite (to test with autonomous sprites press enter in the demo)
 * Pathfinding doesn't work, 'findPath()' will either return null or have weird behavior;
 * Floating-point tilemap tearing in Flash (very easy to spot when scrolling the camera) - might be on flixel side;
 * Collisions not working correctly (callbacks dispatching regardless of position and tile type);

### Targets

 * [x] flash
 * [x] html5 (must disable openfl-bitfive html5 backend)
 * [x] desktop (cpp & neko)
 * [x] android
 * [ ] ios (should work, test needed)

### Misc

 * General performance improvement