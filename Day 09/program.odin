package main

import "core:fmt"
import "core:strconv"
import scannerPkg "core:text/scanner"

XmasCircularBuffer :: struct
{
    values : [25]int,
    iCur : int,
}

consumePreamble :: proc(scanner : ^scannerPkg.Scanner, xbuf : ^XmasCircularBuffer)
{
    using strconv;
    
    for i in 0..<len(xbuf.values)
    {
        consumeWhitespace(scanner);
        valueStr := consumeUntilWhitespace(scanner);
        value, ok := parse_int(valueStr);
        assert(ok);

        xbuf.values[i] = value;
    }

    xbuf.iCur = 0;
}

consumeAndValidateInt :: proc(scanner : ^scannerPkg.Scanner, xbuf : ^XmasCircularBuffer) -> (int, bool)
{
    using strconv;
    
    consumeWhitespace(scanner);
    
    valueStr := consumeUntilWhitespace(scanner);

    // @Punt - EOF handling
    value, ok := parse_int(valueStr);
    assert(ok);

    defer
    {
        xbuf.values[xbuf.iCur] = value;
        xbuf.iCur += 1;
        xbuf.iCur %= len(xbuf.values);
    }

    for i in 0..<len(xbuf.values)
    {
        // NOTE - No need to offset i or j by xbuf.iCur since we are just looking for *any*
        //  valid pair. We don't care how recent they were (as long as they are within 25!)
        
        valI := xbuf.values[i];
        
        for j in (i + 1)..<len(xbuf.values)
        {
            valJ := xbuf.values[j];

            if valI + valJ == value
            {
                return value, true;
            }
        }
    }

    return value, false;
}

findInvalidNumber :: proc(scanner : ^scannerPkg.Scanner) -> int
{
    xbuf : XmasCircularBuffer;
    consumePreamble(scanner, &xbuf);

    for
    {
        value, ok := consumeAndValidateInt(scanner, &xbuf);
        if !ok
        {
            return value;
        }
    }

    assert(false);
    return -1;
}

findPart2Range :: proc(scanner : ^scannerPkg.Scanner, part1Result : int) -> (small : int, big : int)
{
    using strconv;
    
    input : [dynamic]int;
    defer(delete(input));

    for
    {
        consumeWhitespace(scanner);
        valueStr := consumeUntilWhitespace(scanner);

        if value, ok := parse_int(valueStr); ok
        {
            append(&input, value);
        }
        else
        {
            // EOF
            
            break;
        }
    }

    for i0 in 0..<len(input) - 1
    {
        sum := input[i0];
        
        small = input[i0];
        big = input[i0];

        for i1 in i0 + 1..<len(input)
        {
            sum += input[i1];
            small = min(small, input[i1]);
            big = max(big, input[i1]);

            if sum == part1Result
            {
                return small, big;
            }
            else if sum > part1Result
            {
                break;
            }
        }
    }

    return -1, -1;
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));


    part1Result := findInvalidNumber(&scanner);
    fmt.println("Part 1:", part1Result);
    
    resetScanner(&scanner);
    part2Small, part2Big := findPart2Range(&scanner, part1Result);
    part2Result := part2Small + part2Big;
    fmt.println("Part 2:", part2Result);
}
