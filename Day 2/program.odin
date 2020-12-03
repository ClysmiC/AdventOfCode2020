package main

import "core:fmt"
import "core:os"

isDigit :: proc(c : byte) -> bool
{
    result : bool = c >= '0' && c <= '9';
    return result;
}

consumeInt :: proc(buffer : []byte,  pIndex : ^int) -> (int, bool)
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
            // Consume new line to prime us for the next consumeInt call
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

consumeSequence :: proc(buffer : []byte, pIndex : ^int, sequence: string) -> bool
{
    if pIndex^ < 0 || pIndex^ >= len(buffer)
    {
        return false;
    }

    iSequence : int;
    
    for iSequence < len(sequence) && pIndex^ < len(buffer)
    {
        charBuffer : byte = buffer[pIndex^];
        charSequence : byte = sequence[iSequence];

        if charBuffer != charSequence
        {
            return false;
        }

        pIndex^ += 1;
        iSequence += 1;
    }

    return iSequence == len(sequence);
}

main :: proc()
{
    inputStr, _ := os.read_entire_file("input.txt");
    iByte : int;

    part1Result : int;
    part2Result : int;
    
    for iByte < len(inputStr)
    {
        lowerBound : int;
        upperBound : int;
        charMatch : byte;
        
        {
            success : bool;

            lowerBound, success = consumeInt(inputStr, &iByte);
            assert(success);

            success = consumeSequence(inputStr, &iByte, "-");
            assert(success);

            upperBound, success = consumeInt(inputStr, &iByte);
            assert(success);

            success = consumeSequence(inputStr, &iByte, " ");
            assert(success);

            charMatch = inputStr[iByte];
            iByte += 1;

            success = consumeSequence(inputStr, &iByte, ": ");
            assert(success);

            countMatchPart1 : int;
            countMatchPart2 : int;
            iPasswordOneIndexed : int = 1;
            
            for true
            {
                charPassword : byte = inputStr[iByte];
                iByte += 1;

                if (charPassword == charMatch)
                {
                    countMatchPart1 += 1;

                    if (iPasswordOneIndexed == lowerBound || iPasswordOneIndexed == upperBound)
                    {
                        countMatchPart2 += 1;
                    }
                }
                else if (charPassword == '\n')
                {
                    break;
                }
                    
                iPasswordOneIndexed += 1;
            }

            if countMatchPart1 >= lowerBound && countMatchPart1 <= upperBound
            {
                part1Result += 1;
            }

            if countMatchPart2 == 1
            {
                part2Result += 1;
            }
        }
    }

    fmt.println("Part 1:", part1Result);
    fmt.println("Part 2:", part2Result);
}
