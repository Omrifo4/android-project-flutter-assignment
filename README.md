# hello_me

## HW3 Dry

1.) The class which is used to implement the pattern in this library is **SnappingSheetController**.
Using this controller, the develop can control the following features:
 - Read/modify the SnappingSheet's current snap position (using currentSnapPosition property or snapToPosition() method).
 - Access (read/write) the SnappingSheet's snapPositions list (using snapPositions property).

2.) The controller's SnapToPosition() method, which snaps the bottom sheet to a given SnapPosition,
receives a SnapPosition as an argument.
The SnapPosition class holds 'snappingCurve' and 'snappingDuration' properties,
which respectively determines the animation curve (controls the animation progress over time) and duration.

3.) Advantages:
Inkwell over GestureDetector: Inkwell supports 'ripple' effect animation on tap, while GestureDetector do not.
GestureDetector over Inkwell: GestureDetector supports much more control options than Inkwell.
For example, GestureDetector can specify a behaviour for dragging (using properties like onHorizontalDragStart), while Inkwell can't.