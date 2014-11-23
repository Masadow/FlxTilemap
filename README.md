FlxTilemap
==========

Isometric tilemap implementation for HaxeFlixel.

### Features to Implement

 * Heights
 * Slopes
 * Bridges
 * Bigger-than-tile objects;

### Known Bugs

 * [New] Removed sorting algorithm to implement map culling, must be fixed;
 * [New] Map culling broke camera zoom, must be fixed;
 * [New] Map culling broke autonomous sprite generation, must be fixed;
 * Pathfinding doesn't work, 'findPath()' will either return null or have weird behavior;
 * Floating-point tilemap tearing in Flash (very easy to spot when scrolling the camera);
 * Collisions not working correctly (callbacks dispatching regardless of position and tile type);

### Targets

 * [x] flash
 * [x] html5 (must disable openfl-bitfive html5 backend)
 * [x] desktop (cpp & neko)
 * [x] android
 * [ ] ios (should work, test needed)

### Misc

 * General performance improvement