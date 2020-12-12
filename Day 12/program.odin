package main

import "core:fmt"
import scan "core:text/scanner"
import "core:mem"

Heading :: enum
{
    E,
    S,
    W,
    N,
}

Ferry :: struct
{
    x, y : int,
    heading : Heading,
}

Waypoint :: struct
{
    dX, dY : int,
}

rotate90DegRight :: proc(x : int, y : int) -> (xOut : int, yOut : int)
{
    xOut = y;
    yOut = -x;
    return;
}

rotate90DegLeft :: proc(x : int, y : int) -> (xOut : int, yOut : int)
{
    xOut = -y;
    yOut = x;
    return;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));


    for part in 1..2
    {
        ferry : Ferry;
        waypoint := Waypoint
        {
            dX = 10,
            dY = 1
        };

        resetScanner(&scanner);
        
        for !isEof(&scanner)
        {
            instruction := scan.next(&scanner);
            arg, ok := tryConsumeInt(&scanner);
            assert(ok);

            consumeWhitespace(&scanner);

            if part == 1
            {
                // Treat F as a psuedo-instruction that translates to something else
                if instruction == 'F'
                {
                    // HMM - Built-in way to get enum field names as strings/chars?
                    switch ferry.heading
                    {
                        case .E: instruction = 'E';
                        case .S: instruction = 'S';
                        case .W: instruction = 'W';
                        case .N: instruction = 'N';
                        case: assert(false);
                    }
                }
            }
            
            switch instruction
            {
                case 'N':
                {
                    if part == 1
                    {
                        ferry.y += arg;
                    }
                    else
                    {
                        assert(part == 2);
                        waypoint.dY += arg;
                    }
                }

                case 'S':
                {
                    if part == 1
                    {
                        ferry.y -= arg;
                    }
                    else
                    {
                        assert(part == 2);
                        waypoint.dY -= arg;
                    }
                }

                case 'E':
                {
                    if part == 1
                    {
                        ferry.x += arg;
                    }
                    else
                    {
                        assert(part == 2);
                        waypoint.dX += arg;
                    }
                }

                case 'W':
                {
                    if part == 1
                    {
                        ferry.x -= arg;
                    }
                    else
                    {
                        assert(part == 2);
                        waypoint.dX -= arg;
                    }
                }

                case 'L':
                {
                    assert(arg % 90 == 0);
                    dHeading := -(arg / 90);

                    if part == 1
                    {
                        ferry.heading += auto_cast dHeading;
                        for ferry.heading < auto_cast 0
                        {
                            ferry.heading += auto_cast len(Heading);
                        }
                    }
                    else
                    {
                        assert(part == 2);
                        for i in 0..<abs(dHeading)
                        {
                            waypoint.dX, waypoint.dY = rotate90DegLeft(waypoint.dX, waypoint.dY);
                        }
                    }
                }

                case 'R':
                {
                    assert(arg % 90 == 0);
                    dHeading := arg / 90;

                    if part == 1
                    {
                        ferry.heading += auto_cast dHeading;
                        for ferry.heading >= auto_cast len(Heading)
                        {
                            ferry.heading -= auto_cast len(Heading);
                        }
                    }
                    else
                    {
                        assert(part == 2);
                        for i in 0..<dHeading
                        {
                            waypoint.dX, waypoint.dY = rotate90DegRight(waypoint.dX, waypoint.dY);
                        }
                    }
                }

                case 'F':
                {
                    assert(part == 2);
                    ferry.x += waypoint.dX * arg;
                    ferry.y += waypoint.dY * arg;
                }

                case: assert(false);
            }
        }
        
        manhattanDistance := abs(ferry.x) + abs(ferry.y);
        fmt.println("Part", part, ":", manhattanDistance);
    }
}
