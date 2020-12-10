package main

import "core:fmt"
import "core:os"
import scannerPkg "core:text/scanner"

consumeCharactersAndReturnLast :: proc(scanner : ^scannerPkg.Scanner, n : int) -> rune
{
    using scannerPkg;
    
    result : rune = EOF;
    
    for i in 0..<n
    {
        result = next(scanner);
        
        if result == EOF
        {
            break;
        }
    }
    
    return result;
}

consumeThroughNewLine :: proc(scanner : ^scannerPkg.Scanner) -> int
{
    using scannerPkg;

    result : int;
    
    for
    {
        c : rune = next(scanner);
        result += 1;
        
        if c == EOF || c == '\n'
        {
            break;
        }
        else if c == '\r' && peek(scanner) == '\n'
        {
            next(scanner); // Consume \n
            break;
        }
    }

    return result;
}

countTreesOnSlope :: proc(
    scanner : ^scannerPkg.Scanner,
    inputWidth : int,
    dCol : int,
    dRow : int)
    -> int
{
    // Reset scanner
    
    scannerPkg.init(scanner, scanner.src);

    col : int;
    result : int;
    
fileLoop:
    for
    {
        char : rune = consumeCharactersAndReturnLast(scanner, col + 1);
        
        switch char
        {
            case '.':
            {
            }
            
            case '#':
            {
                result += 1;
            }
            
            case scannerPkg.EOF:
            {
                break fileLoop;
            }
            
            case:
            {
                assert(false);
            }
        }
        
        col += dCol;
        col %= inputWidth;

        for iRow in 1..dRow
        {
            consumeThroughNewLine(scanner);
        }
    }

    return result;
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));

    // NOTE - Width does not count the new line character
    
    inputWidth : int = consumeThroughNewLine(&scanner) - 1;

    part1Result : int = countTreesOnSlope(&scanner, inputWidth, 3, 1);
    part2Result : int =
        countTreesOnSlope(&scanner, inputWidth, 1, 1) *
        part1Result *
        countTreesOnSlope(&scanner, inputWidth, 5, 1) *
        countTreesOnSlope(&scanner, inputWidth, 7, 1) *
        countTreesOnSlope(&scanner, inputWidth, 1, 2);
        
    fmt.println("Part 1:", part1Result);
    fmt.println("Part 2:", part2Result);
}
