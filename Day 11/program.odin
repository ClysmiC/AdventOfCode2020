package main

import "core:fmt"
import scannerPkg "core:text/scanner"
import "core:mem"

Tile :: enum
{
    Floor,
    Empty,
    Occupied
}

TileGrid :: struct
{
    tiles : [dynamic]Tile,
    width : int,
    height : int,
}

makeTileGrid :: proc(scanner : ^scannerPkg.Scanner) -> TileGrid
{
    result : TileGrid;

    for !isEof(scanner)
    {
        row := consumeUntilWhitespace(scanner);
        consumeWhitespace(scanner);
        
        if result.width == 0
        {
            result.width = len(row);
        }
        
        assert(result.width == len(row));

        for tileChar in row
        {
            tile : Tile = ---;
            switch tileChar
            {
                case '.': tile = .Floor;
                case 'L': tile = .Empty;
                case '#': tile = .Occupied;
                case: assert(false);
            }

            append(&result.tiles, tile);
        }

        result.height += 1;
    }
    
    return result;
}

deepCopyTileGrid :: proc(grid : TileGrid) -> TileGrid
{
    // HMM - More idiomatic way to deep copy?
    
    result := TileGrid
    {
        width = grid.width,
        height = grid.height,
    };
    
    for tile in grid.tiles
    {
        append(&result.tiles, tile);
    }

    return result;
}

SimRules :: enum
{
    Part1,
    Part2
}

simulate :: proc(grid : TileGrid, rules : SimRules) -> (stabilized : bool)
{
    isDirectionOccupied :: proc(grid : TileGrid, i : int, dX : int, dY: int, rules : SimRules) -> bool
    {
        assert(dX != 0 || dY != 0);
        
        col := i % grid.width;
        row := i / grid.width;

        colOther := col;
        rowOther := row;
        
        for
        {
            colOther += dX;
            rowOther += dY;

            if colOther < 0 || colOther >= grid.width || rowOther < 0 || rowOther >= grid.height
            {
                return false;
            }

            iOther := rowOther * grid.width + colOther;
            assert(iOther >= 0 && iOther < len(grid.tiles));

            tileOther := grid.tiles[iOther];

            if tileOther == .Occupied
            {
                return true;
            }
            else if tileOther == .Empty
            {
                return false;
            }
            
            assert(tileOther == .Floor);
            if rules == .Part1
            {
                return false;
            }
        }
    }
    
    prevGrid := deepCopyTileGrid(grid);
    defer delete(prevGrid.tiles);
    
    stabilized = true;
    
    for i in 0..<len(prevGrid.tiles)
    {
        countNeighbors := 0;

        // Left
        if isDirectionOccupied(prevGrid, i, -1, 0, rules)
        {
            countNeighbors += 1;
        }

        // Right
        if isDirectionOccupied(prevGrid, i, +1, 0, rules)
        {
            countNeighbors += 1;
        }

        // Top
        if isDirectionOccupied(prevGrid, i, 0, -1, rules)
        {
            countNeighbors += 1;
        }

        // Bottom
        if isDirectionOccupied(prevGrid, i, 0, +1, rules)
        {
            countNeighbors += 1;
        }

        // Top-Left
        if isDirectionOccupied(prevGrid, i, -1, -1, rules)
        {
            countNeighbors += 1;
        }

        // Top-Right
        if isDirectionOccupied(prevGrid, i, +1, -1, rules)
        {
            countNeighbors += 1;
        }

        // Bot-Left
        if isDirectionOccupied(prevGrid, i, -1, +1, rules)
        {
            countNeighbors += 1;
        }

        // Bot-Right
        if isDirectionOccupied(prevGrid, i, +1, +1, rules)
        {
            countNeighbors += 1;
        }

        tooCrowded := 4;
        if rules == .Part2
        {
            tooCrowded = 5;
        }
        
        tile := prevGrid.tiles[i];
        if tile == .Empty && countNeighbors == 0
        {
            stabilized = false;
            tile = .Occupied;
        }
        else if tile == .Occupied && countNeighbors >= tooCrowded
        {
            stabilized = false;
            tile = .Empty;
        }

        grid.tiles[i] = tile;
    }
    
    return stabilized;
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));

    grid1 : TileGrid = makeTileGrid(&scanner);
    grid2 := deepCopyTileGrid(grid1);
    
    defer delete(grid1.tiles);
    defer delete(grid2.tiles);

    // Part 1
    for !simulate(grid1, .Part1)
    { ; }
    
    part1Occupied : int;
    for tile in grid1.tiles
    {
        if tile == .Occupied
        {
            part1Occupied += 1;
        }
    }
    
    fmt.println("Part 1:", part1Occupied);

    // Part 2
    for !simulate(grid2, .Part2)
    { ; }
    
    part2Occupied : int;
    for tile in grid2.tiles
    {
        if tile == .Occupied
        {
            part2Occupied += 1;
        }
    }
    
    fmt.println("Part 2:", part2Occupied);
}
