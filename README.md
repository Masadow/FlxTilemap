FlxTilemap
==========

Isometric tilemap implementation for HaxeFlixel.

### Current status / features

Currently in alpha, not recommended for production environments. Big refactoring / breaking changes are very likely to happen!

 * Map culling, supports map sizes of up to 1000x1000 with constant draw time (maps can be bigger in theory but beware of memory consumption)
 * Sprite and dynamic tile sorting, allowing moving objects to appear behind or in front of walls, doors, etc
 * Pathfinding with simple A* implementation
 * Map scrolling and zoom
 
### To do:

 * Heights
 * Slopes
 * Bridges
 * Bigger-than-tile objects
 * Improve performance
 * Better demo
 * Live demo and binaries here

### Known Bugs

 * Sometimes when scrolling the leftmost column on the screen appears / disappears (floating point maybe?);
 * Tilemap tearing in Flash (very easy to spot when scrolling the camera, some tiles will be drawn 1px off their position) - might be on flixel side;
 * Collisions not working correctly (callbacks dispatching regardless of position and tile type);

### Targets

 * [x] flash
 * [x] html5 (must disable openfl-bitfive html5 backend)
 * [x] desktop (cpp & neko)
 * [x] android
 * [ ] ios (should work, test needed)