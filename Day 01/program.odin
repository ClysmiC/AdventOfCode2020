package main

import "core:fmt"
import "core:os"

isDigit :: proc(c : byte) -> bool
{
    result : bool = c >= '0' && c <= '9';
    return result;
}

parseInt :: proc(buffer : []byte,  pIndex : ^int) -> (int, bool)
{
    if pIndex^ < 0 || pIndex^ >= len(buffer)
    {
        return 0, false;
    }

    result : int;
    hasParsedDigit : bool = false;
    
    for ; pIndex^ < len(buffer); pIndex^ += 1
    {
        c : byte = buffer[pIndex^];
        
        if isDigit(c)
        {
            hasParsedDigit = true;
            
            result *= 10;
            result += auto_cast (c - '0');
        }
        else
        {
            // Consume new line to prime us for the next parseInt call
            // HMM - Do this for any white space?
            
            if c == '\n'
            {
                pIndex^ += 1;
            }
            else if c == '\r' && buffer[pIndex^ + 1] == '\n'
            {
                // PUNT - This will read outside of file if file ends in \r... Not worried about that for AoC...
                
                pIndex^ += 2;
            }
            
            break;
        }
    }

    return result, hasParsedDigit;
}

main :: proc()
{
    // Process input
    
    inputStr, _ := os.read_entire_file("input.txt");
    iByte : int;

    input := make([dynamic]int);

    for true
    {
        value, success := parseInt(inputStr, &iByte);
        
        if success
        {
            append(&input, value);
        }
        else
        {
            break;
        }
    }

    // Part 1
    
part1Outer:
    for i0 in 0..<len(input) - 1
    {
        val0 := input[i0];
        
        for i1 in (i0 + 1)..<len(input)
        {
            val1 := input[i1];
            
            if val0 + val1 == 2020
            {
                fmt.println("Part 1:", val0 * val1);
                break part1Outer;
            }
        }
    }


    // Part 2

part2Outer:
    for i0 in 0..<len(input) - 2
    {
        val0 := input[i0];
        
        for i1 in (i0 + 1)..<len(input) - 1
        {
            val1 := input[i1];

            for i2 in (i1 + 1)..<len(input)
            {
                val2 := input[i2];
                
                if val0 + val1 + val2 == 2020
                {
                    fmt.println("Part 2:", val0 * val1 * val2);
                    break part2Outer;
                }
            }
        }
    }
}
