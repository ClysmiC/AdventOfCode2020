package main

import "core:fmt"
import scan "core:text/scanner"

Coord :: struct
{
    x, y, z, w : int,
}

filterAndCloneMap :: proc(map_ : $M/map[$K]$V, filter : proc(V) -> bool) -> M
{
    result : M;
    
    for key, value in map_
    {
        if filter(value)
        {
            result[key] = value;
        }
    }

    return result;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    // I prefer (0, 0) at the bottom left. Do an initial pass to know how many rows the input has

    cntRow : int;
    for !isEof(&scanner)
    {
        consumeThrough(&scanner, []rune{'#', '.'});
        consumeWhitespace(&scanner);
        cntRow += 1;
    }

    resetScanner(&scanner);

    cube1 : map[Coord]bool;
    cube2 : map[Coord]bool;
    
    row := cntRow - 1;
    col := 0;
    for !isEof(&scanner)
    {
        assert(row >= 0);
        
        c := scan.next(&scanner);

        switch c
        {
            case '#':
            {
                coord := Coord { x = col, y = row, z = 0, w = 0 };
                cube1[coord] = true;
                cube2[coord] = true;

                col += 1;
            }
            
            case '.': // Nop
            {
                col += 1;
            }
            
            case:
            {
                assert(c == '\n' || c == '\r');
                consumeWhitespace(&scanner);
                row -= 1;
                col = 0;
            }
        }
    }

    for part in 1..2
    {
        cube : ^map[Coord]bool = ---;
        if part == 1
        {
            cube = &cube1;
        }
        else
        {
            cube = &cube2;
        }
        
        for generation in 1..6
        {
            cubeNext : map[Coord]bool;
            defer delete(cubeNext);
            
            for coord, _ in cube
            {
                for dX in -1..1
                {
                    for dY in -1..1
                    {
                        for dZ in -1..1
                        {
                            dwMin := 0;
                            dwMax := 0;
                            if part == 2
                            {
                                dwMin = -1;
                                dwMax = 1;
                            }
                            
                            for dW in dwMin..dwMax
                            {
                                coordNext := Coord{
                                    coord.x + dX,
                                    coord.y + dY,
                                    coord.z + dZ,
                                    coord.w + dW};
                                
                                if coordNext in cubeNext
                                {
                                    continue;
                                }
                                
                                cntNeighborActive := 0;

                                for dXNeighbor in -1..1
                                {
                                    for dYNeighbor in -1..1
                                    {
                                        for dZNeighbor in -1..1
                                        {
                                            dwNeighborMin := 0;
                                            dwNeighborMax := 0;
                                            if part == 2
                                            {
                                                dwNeighborMin = -1;
                                                dwNeighborMax = 1;
                                            }
                                            
                                            for dWNeighbor in dwNeighborMin..dwNeighborMax
                                            {
                                                neighbor := Coord{
                                                    coordNext.x + dXNeighbor,
                                                    coordNext.y + dYNeighbor,
                                                    coordNext.z + dZNeighbor,
                                                    coordNext.w + dWNeighbor};
                                                
                                                if neighbor == coordNext
                                                {
                                                    continue;
                                                }

                                                if cube[neighbor]
                                                {
                                                    cntNeighborActive += 1;
                                                }
                                            }
                                        }
                                    }
                                }

                                wasActive := cube[coordNext];
                                isActive : bool = ---;
                                if wasActive
                                {
                                    isActive = (cntNeighborActive == 2) || (cntNeighborActive == 3);
                                }
                                else
                                {
                                    isActive = cntNeighborActive == 3;
                                }

                                cubeNext[coordNext] = isActive;
                            }
                        }
                    }
                }
            }
            
            // Cull non-active cells to keep the simulation as tight as possible
            cube^ = filterAndCloneMap(cubeNext, inline proc(b : bool) -> bool { return b; });
        }
        
        fmt.println("Part", part, ":", len(cube));
    }
}
