// Author's note
// This code is pretty confusing an inconsistent. I wouldn't recommend trying to understand how it works. I made a few mistakes
//  regarding winding directions and orientations when initially implementing. I cleaned it mostly up and started expressing things
//  in terms of local space and world space, but there is still a lot of places where I handle flips/turns in a pretty ad-hoc way. I
//  have a pretty good idea of where it all went wrong, but I'm kind of sick of day 20 so I'm not going to spend time fixing it!

package main

import "core:fmt"
import scan "core:text/scanner"
import "core:os"

TILE_DIM :: 10;

Tile :: struct
{
    id: int,
    pixels: [TILE_DIM][TILE_DIM] bool,

    // Note - Indexed non-flipped in local space
    neighborsLocked: [len(Side)]^Tile,
    
    orientation: Orientation,

    x: int,
    y: int,
}

XY :: struct
{
    x, y: int,
}

TileGrid :: struct
{
    lookup: map[XY]^Tile,

    topLeft: XY,
    width: int,
    height: int,
}

isLocked :: proc(tile: ^Tile) -> bool
{
    return tile.orientation != .None;
}

Orientation :: enum
{
    // Flip: 0 = unflipped. 1 = flipped horizontally (e.g. rotated 180 degrees about the vertical axis)
    //  Applied before rotation

    // Rotate: 0 = unrotated, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees
    //  All rotations CW
    //  Applied after flip

    None,

    // @Sync - Order matters!
    Flip0Rotate0,
    Flip0Rotate1,
    Flip0Rotate2,
    Flip0Rotate3,

    Flip1Rotate0,
    Flip1Rotate1,
    Flip1Rotate2,
    Flip1Rotate3,

    BeginFlip = Flip1Rotate0
}

buildOrientation :: proc(isFlipped_: bool, cntRotation: int, startingOrientation := Orientation.Flip0Rotate0) -> Orientation
{
    if (cntRotation < 0 || cntRotation > 3)
    {
        assert(false);
        return .None;
    }

    // @Hack - This function is totally whack and it is very unclear whether "isFlipped" and cntRotation are local space, world
    //  space, etc. I am pretty sick of day 20 though so I'm not going to clean it up.
    
    result := startingOrientation;
    if isFlipped_
    {
        result = flipOrientation(result);
    }

    if isFlipped(startingOrientation)
    {
        for _ in 1..cntRotation
        {
            result = rotateOrientationCcw(result);
        }
    }
    else
    {
        for _ in 1..cntRotation
        {
            result = rotateOrientationCw(result);
        }
    }
          

    return result;
}

flipOrientation :: proc(orientation: Orientation) -> Orientation
{
    // Note - This should actually satisfy a complete switch, but the compiler complains at me.
    //  I think it is a bug in the combination with complete switching on enums and using the .. operator.
    //  I filed a bug for it here: https://github.com/odin-lang/Odin/issues/814
    #partial switch orientation
    {
        case .Flip0Rotate0 .. .Flip0Rotate3: return orientation + auto_cast 4;
        case .Flip1Rotate0 .. .Flip1Rotate3: return orientation - auto_cast 4;
        
        case .None: fallthrough;
        case: assert(false); return .None;
    }

    return .None; // Needed to satisfy compiler despite having a default case??
}

isFlipped :: proc(orientation: Orientation) -> bool
{
    // https://github.com/odin-lang/Odin/issues/814
    #partial switch orientation
    {
        case .Flip0Rotate0 .. .Flip0Rotate3: return false;
        case .Flip1Rotate0 .. .Flip1Rotate3: return true;

        case .None: fallthrough;
        case: assert(false); return false;
    }

    return false; // Needed to satisfy compiler despite having a default case??
}

cntRotationCw :: proc(orientation: Orientation) -> int
{
    // https://github.com/odin-lang/Odin/issues/814
    #partial switch orientation
    {
        case .Flip0Rotate0 .. .Flip0Rotate3: return int(orientation - .Flip0Rotate0);
        case .Flip1Rotate0 .. .Flip1Rotate3: return int(orientation - .Flip1Rotate0);

        case .None: fallthrough;
        case: assert(false); return 0;
    }

    return 0; // Needed to satisfy compiler despite having a default case??
}

rotateOrientationCw :: proc(orientation: Orientation) -> Orientation
{
    // https://github.com/odin-lang/Odin/issues/814
    #partial switch orientation
    {
        case .Flip0Rotate0 .. .Flip0Rotate2: fallthrough;
        case .Flip1Rotate0 .. .Flip1Rotate2: return orientation + auto_cast 1;
        
        case .Flip0Rotate3: fallthrough;
        case .Flip1Rotate3: return orientation - auto_cast 3;

        case .None: fallthrough;
        case: assert(false); return .None;
    }

    return .None; // Needed to satisfy compiler despite having a default case??
}

rotateOrientationCcw :: proc(orientation: Orientation) -> Orientation
{
    // https://github.com/odin-lang/Odin/issues/814
    #partial switch orientation
    {
        case .Flip0Rotate1 .. .Flip0Rotate3: fallthrough;
        case .Flip1Rotate1 .. .Flip1Rotate3: return orientation - auto_cast 1;
        
        case .Flip0Rotate0: fallthrough;
        case .Flip1Rotate0: return orientation + auto_cast 3;

        case .None: fallthrough;
        case: assert(false); return .None;
    }

    return .None; // Needed to satisfy compiler despite having a default case??
}

Side :: enum
{
    None,

    // @Sync - Cw winding matters!
    Top,
    Right,
    Bottom,
    Left,
}

flipSideHorizontally :: proc(side: Side) -> Side
{
    switch side
    {
        case .Top: fallthrough;
        case .Bottom: return side;
        
        case .Right: return .Left;
        case .Left: return .Right;

        case .None: fallthrough;
        case: assert(false); return .None;
    }

    return .None; // Needed to satisfy compiler despite having a default case??
}

oppositeSide :: proc(side: Side) -> Side
{
    switch side
    {
        case .Top: fallthrough;
        case .Right: return side + auto_cast 2;
        
        case .Bottom: fallthrough;
        case .Left: return side - auto_cast 2;

        case .None: fallthrough;
        case: assert(false); return .None;
    }

    return .None; // Needed to satisfy compiler despite having a default case??
}

rotateSideCw :: proc(side: Side) -> Side
{
    // https://github.com/odin-lang/Odin/issues/814
    #partial switch side
    {
        case .Top: fallthrough;
        case .Right: fallthrough;
        case. Bottom: return side + auto_cast 1;

        case .Left: return .Top;

        case .None: fallthrough;
        case: assert(false); return .None;
    }

    return .None; // Needed to satisfy compiler despite having a default case??
}

rotateSideCcw :: proc(side: Side) -> Side
{
    // https://github.com/odin-lang/Odin/issues/814
    #partial switch side
    {
        case .Right: fallthrough;
        case. Bottom: fallthrough;
        case .Left: return side - auto_cast 1;
        
        case .Top: return .Left;

        case .None: fallthrough;
        case: assert(false); return .None;
    }

    return .None; // Needed to satisfy compiler despite having a default case??
}

rotationsCwRequiredToAlignBorders :: proc(locked: Side, movable: Side) -> int
{
    movableTarget := oppositeSide(locked);
    
    result := int(movableTarget - movable);
    if result < 0
    {
        result += 4;
    }

    assert(result >= 0);
    assert(result <= 3);

    return result;
}

sideWorldFromLocal :: proc(local: Side, orientation: Orientation) -> Side
{
    result := local;
    if isFlipped(orientation)
    {
        result = flipSideHorizontally(result);
    }

    cntRotation := cntRotationCw(orientation);

    for _ in 1..cntRotation
    {
        result = rotateSideCw(result);
    }

    return result;
}

sideLocalFromWorld :: proc(world: Side, orientation: Orientation) -> Side
{
    result := world;

    cntRotationCw := cntRotationCw(orientation);

    for _ in 1..cntRotationCw
    {
        // Note - Rotate the opposite direction because we are doing the inverse transformation (world to local)
        result = rotateSideCcw(result);
    }

    if isFlipped(orientation)
    {
        result = flipSideHorizontally(result);
    }

    return result;
}

Border :: [TILE_DIM]bool;

// Cw = Clockwise
getBorderCw :: proc(tile: ^Tile, side: Side) -> Border
{
    result: Border;

    switch side
    {
        case .Top: result = tile.pixels[0];
        
        case .Right:
        {
            for iResult in 0..<TILE_DIM
            {
                result[iResult] = tile.pixels[iResult][TILE_DIM - 1];
            }
        }
        
        case .Bottom:
        {
            for iResult in 0..<TILE_DIM
            {
                result[iResult] = tile.pixels[TILE_DIM - 1][TILE_DIM - 1 - iResult];
            }
        }
        
        case .Left:
        {
            for iResult in 0..<TILE_DIM
            {
                result[iResult] = tile.pixels[TILE_DIM - 1 - iResult][0];
            }
        }

        case .None: fallthrough;
        case: assert(false);
    }

    return result;
}

BorderMatch :: struct
{
    sideLocked: Side,
    sideMovable: Side,
    isMovableFlipped: bool,
}

TileAndBorderMatch :: struct
{
    // Note - Would rather do it this way but debugger support is terrible/nonexistant for it
    /* using borderMatch_: BorderMatch, */

    match: BorderMatch,
    
    tileLocked: ^Tile,  // Guaranteed to be locked
    tileMatched: ^Tile, // May or may not be locked
}

// All possible ways that a movable tile can match against a locked tile
AllBorderMatches :: [32]BorderMatch;

testBorders :: proc(
    border0: ^Border,
    border1: ^Border,
    isBorder1Flipped: bool)
    -> bool
{
    // Note - Somewhat counter-intuitively, if we are checking against a flipped border,
    //  we iterate forwards. This is because two abutting borders with the same windings
    //  will run in different directions (unless flipped). See the common border in the two CW
    //  windings below.
    //
    //  ---> --->
    //  ^  | ^  |
    //  |  v |  v
    //  <--- <---

    if isBorder1Flipped
    {
        for iCursor in 0..<TILE_DIM
        {
            if border0[iCursor] != border1[iCursor]
            {
                return false;
            }
        }
    }
    else
    {
        for iCursor in 0..<TILE_DIM
        {
            if border0[iCursor] != border1[TILE_DIM - 1 - iCursor]
            {
                return false;
            }
        }
    }

    return true;
}

findMatchingBorders :: proc(
    tileLocked: ^Tile,
    tileCandidate: ^Tile)
    ->
    (AllBorderMatches,
    int) // Number of matches
{
    assert(tileLocked != tileCandidate);
    assert(isLocked(tileLocked));
    assert(!isLocked(tileCandidate));
    
    result : AllBorderMatches;
    cntResult := 0;

    for sideLocked in Side.None + auto_cast 1 ..< Side(len(Side))
    {
        if tileLocked.neighborsLocked[sideLocked] != nil
        {
            continue;
        }

        lockedBorder := getBorderCw(tileLocked, sideLocked);
        
        for sideCandidate in Side.None + auto_cast 1 ..< Side(len(Side))
        {
            assert(tileCandidate.neighborsLocked[sideCandidate] == nil);
            
            candidateBorder := getBorderCw(tileCandidate, sideCandidate);

            // Unflipped
            if testBorders(&lockedBorder, &candidateBorder, false)
            {
                result[cntResult] = BorderMatch {
                    sideLocked = sideLocked,
                    sideMovable = sideCandidate,
                    isMovableFlipped = false,
                };
                
                cntResult += 1;
            }

            // Flipped
            if testBorders(&lockedBorder, &candidateBorder, true)
            {
                result[cntResult] = BorderMatch {
                    sideLocked = sideLocked,
                    sideMovable = sideCandidate,
                    isMovableFlipped = true,
                };
                
                cntResult += 1;
            }
        }
    }

    return result, cntResult;
}

lockTile :: proc(grid: ^TileGrid, tile: ^Tile, orientation: Orientation, x: int, y: int)
{
    xy := XY{ x, y };
    
    assert(!isLocked(tile));
    assert(orientation != .None);
    assert(!(xy in grid.lookup));
    
    tile.orientation = orientation;
    tile.x = x;
    tile.y = y;

    // Insert into table
    grid.lookup[xy] = tile;

    // Link neighbors
    for sideWorld in Side.None + auto_cast 1 ..< Side(len(Side))
    {
        sideLocal := sideLocalFromWorld(sideWorld, orientation);

        xyNeighbor := xy;
        #partial switch sideWorld
        {
            case .Top: xyNeighbor.y -= 1;
            case .Right: xyNeighbor.x += 1;
            case .Bottom: xyNeighbor.y += 1;
            case .Left: xyNeighbor.x -= 1;
            case: assert(false);
        }

        neighbor := grid.lookup[xyNeighbor];

        if neighbor != nil
        {
            assert(tile.neighborsLocked[sideLocal] == nil || tile.neighborsLocked[sideLocal] == neighbor);
            tile.neighborsLocked[sideLocal] = neighbor; 

            sideNeighborWorld := oppositeSide(sideWorld);
            sideNeighborLocal := sideLocalFromWorld(sideNeighborWorld, neighbor.orientation);
            assert(neighbor.neighborsLocked[sideNeighborLocal] == nil || neighbor.neighborsLocked[sideNeighborLocal] == tile);
            neighbor.neighborsLocked[sideNeighborLocal] = tile;
        }
    }

    // @Cleanup
    if grid.width == 0
    {
        grid.topLeft = xy;
        grid.width = 1;
        grid.height = 1;
    }
    else
    {
        // Track corner
        if xy.x < grid.topLeft.x
        {
            dX := xy.x - grid.topLeft.x;

            grid.topLeft.x += dX;
            grid.width -= dX;
        }

        if xy.y < grid.topLeft.y
        {
            dY := xy.y - grid.topLeft.y;

            grid.topLeft.y += dY;
            grid.height -= dY;
        }

        if xy.x > grid.topLeft.x + grid.width - 1
        {
            dX := xy.x - (grid.topLeft.x + grid.width - 1);
            grid.width += dX;
        }

        if xy.y > grid.topLeft.y + grid.height - 1
        {
            dY := xy.y - (grid.topLeft.y + grid.height - 1);
            grid.height += dY;
        }
    }
}

lockMatch :: proc(grid: ^TileGrid, match: TileAndBorderMatch)
{
    tileLocked := match.tileLocked;
    tileMatched := match.tileMatched;

    assert(isLocked(tileLocked));
    assert(!isLocked(tileMatched));
    assert(tileLocked.neighborsLocked[match.match.sideLocked] == nil);
    assert(tileMatched.neighborsLocked[match.match.sideMovable] == nil);

    orientationMatchedTarget: Orientation;
    {
        sideMatchedMaybeFlipped := match.match.sideMovable;
        if match.match.isMovableFlipped
        {
            sideMatchedMaybeFlipped = flipSideHorizontally(sideMatchedMaybeFlipped);
        }
        
        cntRotationCw := rotationsCwRequiredToAlignBorders(match.match.sideLocked, sideMatchedMaybeFlipped);
        orientationMatchedTarget = buildOrientation(match.match.isMovableFlipped, cntRotationCw, tileLocked.orientation);
    }
    
    sideWorldLocked := sideWorldFromLocal(match.match.sideLocked, tileLocked.orientation);

    x := tileLocked.x;
    y := tileLocked.y;

    #partial switch sideWorldLocked
    {
        case .Top: y -= 1;
        case .Bottom: y += 1;
        case .Right: x += 1;
        case .Left: x -= 1;

        case: assert(false);
    }

    lockTile(grid, tileMatched, orientationMatchedTarget, x, y);
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    tiles : [dynamic]Tile;
    
    for !isEof(&scanner)
    {
        // Parse tile id
        ok := tryConsume(&scanner, "Tile ");
        assert(ok);

        id: int;
        id, ok = tryConsumeInt(&scanner);
        assert(ok);

        ok = tryConsume(&scanner, ":");
        assert(ok);

        consumeWhitespace(&scanner);

        // Parse pixels

        tile : ^Tile;
        {
            append_nothing(&tiles);
            tile = &tiles[len(tiles) - 1];
            tile^ = Tile{}; // Zero-initialize (I'm not sure if append_nothing zero-initializes. A brief glance suggests no?)
            tile.id = id;
        }
        
        for iRow in 0..<TILE_DIM
        {
            for iCol in 0..<TILE_DIM
            {
                c := scan.next(&scanner);
                switch c
                {
                    case '#': tile.pixels[iRow][iCol] = true;
                    case '.': ; // Nop... zero-initialized to false
                    case: assert(false);
                }
            }

            consumeWhitespace(&scanner);
        }

        consumeWhitespace(&scanner);
    }

    grid: TileGrid;
    lockTile(&grid, &tiles[0], .Flip0Rotate0, 0, 0);
    
    lockedTiles: [dynamic]^Tile;
    append(&lockedTiles, &tiles[0]);

    anyMatchLocked := true;
    for anyMatchLocked
    {
        anyMatchLocked = false;
        
        for _, iTileLocked in lockedTiles
        {
            tileLocked := lockedTiles[iTileLocked];
            assert(isLocked(tileLocked));

            mapSideLockedToCntMatch: [len(Side)]int;
            mapSideLockedToFirstMatch: [len(Side)]TileAndBorderMatch;

            for _, iTileCandidate in tiles
            {
                tileCandidate := &tiles[iTileCandidate];
                if isLocked(tileCandidate)
                {
                    continue;
                }
                
                matches, cntMatch := findMatchingBorders(tileLocked, tileCandidate);

                for iMatch in 0..<cntMatch
                {
                    match := matches[iMatch];

                    mapSideLockedToCntMatch[match.sideLocked] += 1;
                    if mapSideLockedToCntMatch[match.sideLocked] == 1
                    {
                        mapSideLockedToFirstMatch[match.sideLocked] = TileAndBorderMatch{
                            match = match,
                            tileLocked = tileLocked,
                            tileMatched = tileCandidate
                        };
                    }
                }
            }

            for side in Side.None + auto_cast 1 ..< Side(len(Side))
            {
                if mapSideLockedToCntMatch[side] == 1
                {
                    // Underscore fixes debugger issue. Holy shit is debugger support bad...
                    match_ := mapSideLockedToFirstMatch[side];

                    if !isLocked(match_.tileMatched)
                    {
                        append(&lockedTiles, match_.tileMatched);
                    }
                    
                    lockMatch(&grid, match_);
                    anyMatchLocked = true;
                }
            }
        }
    }

    fmt.println("Locked tiles", len(lockedTiles));
    fmt.println("All tiles", len(tiles));
    
    topLeftXy := grid.topLeft;
    topRightXy := XY{ topLeftXy.x + grid.width - 1, topLeftXy.y };
    bottomRightXy := XY{ topLeftXy.x + grid.width - 1, topLeftXy.y + grid.height - 1 };
    bottomLeftXy := XY{ topLeftXy.x, topLeftXy.y + grid.height - 1 };

    cornerTl := grid.lookup[topLeftXy];
    cornerTr := grid.lookup[topRightXy];
    cornerBl := grid.lookup[bottomLeftXy];
    cornerBr := grid.lookup[bottomRightXy];

    // NOTE - I chose a pretty awful way to store the grid tile data in part 1. I am making a clean break
    //  for part 2 to make life a little bit easier on me my treating part 2 as a separate problem without
    //  all of the gross technical debt from part 1.
    
    fmt.println("Part 1:", cornerTl.id * cornerTr.id * cornerBl.id * cornerBr.id);
    fmt.println("Writing grid to ../Part2/input.txt - Run program2.odin to solve part 2.");

    file, error := os.open("../Part2/input.txt", os.O_WRONLY | os.O_CREATE);
    assert(error == os.ERROR_NONE);
    defer os.close(file);
    
    writeGridWithoutBordersToFile(&grid, file);
}

writeGridWithoutBordersToFile :: proc(grid: ^TileGrid, file: os.Handle)
{
    for iRowTile in 0..<grid.height
    {
        for iRowPx in 1 ..< (TILE_DIM - 1)
        {
            for iColTile in 0..<grid.width
            {
                tile := grid.lookup[ XY{ grid.topLeft.x + iColTile, grid.topLeft.y + iRowTile } ];
                assert(tile != nil);
                writeTileRowWithoutBordersToFile(tile, iRowPx, file);
            }

            os.write_byte(file, '\n');
        }
    }

    os.write_byte(file, '\n');
}

writeTileRowWithoutBordersToFile :: proc(tile: ^Tile, iRowWorld: int, file: os.Handle)
{
    cntRotation := cntRotationCw(tile.orientation);
    // Note - rotate CCW to undo orientation

    iLocal := iRowWorld;
    isRowLocal := true;
    
    for _ in 1..cntRotation
    {
        iLocal, isRowLocal = rotateCcw(iLocal, isRowLocal);
    }

    if isRowLocal
    {
        assert(cntRotation == 0 || cntRotation == 2);
        isLeftToRight := cntRotation == 0;
        
        if isFlipped(tile.orientation)
        {
            isLeftToRight = !isLeftToRight;
        }
        
        if isLeftToRight
        {
            for iColPx in 1 ..< TILE_DIM - 1
            {
                printPixel(tile.pixels[iLocal][iColPx], file);
            }
        }
        else
        {
            for iColPx := TILE_DIM - 2; iColPx >= 1; iColPx -= 1
            {
                printPixel(tile.pixels[iLocal][iColPx], file);
            }
        }
    }
    else
    {
        assert(cntRotation == 1 || cntRotation == 3);

        isTopToBottom := cntRotation == 3;
        
        if isFlipped(tile.orientation)
        {
            iLocal = TILE_DIM - iLocal - 1;
        }

        if isTopToBottom
        {
            for iRowPx in 1 ..< TILE_DIM - 1
            {
                printPixel(tile.pixels[iRowPx][iLocal], file);
            }
        }
        else
        {
            for iRowPx := TILE_DIM - 2; iRowPx >= 1; iRowPx -= 1
            {
                printPixel(tile.pixels[iRowPx][iLocal], file);
            }
        }
    }

    // ---
    rotateCcw :: proc(i: int, isRow: bool) -> (int, bool)
    {
        if isRow
        {
            return i, !isRow;
        }
        else
        {
            return TILE_DIM - i - 1, !isRow;
        }
    }

    printPixel :: proc(b: bool, file: os.Handle)
    {
        if b
        {
            os.write_byte(file, '#');
        }
        else
        {
            os.write_byte(file, '.');
        }
    }
}

