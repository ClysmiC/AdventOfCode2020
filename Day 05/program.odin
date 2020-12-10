package main

import "core:fmt"
import "core:strconv"
import scannerPkg "core:text/scanner"
import "core:strings"

isEof :: proc(scanner : ^scannerPkg.Scanner) -> bool
{
    using scannerPkg;
    
    return peek(scanner) == EOF;
}

consumeUntilCharSet_ :: proc(scanner : ^scannerPkg.Scanner, untilSet : []rune) -> string
{
    using scannerPkg;
    
    start : int = position(scanner).offset;
    len : int;
    
    for
    {
        char : rune = peek(scanner);
        if char == EOF
        {
            break;
        }

        delimiterFound := false;
        for delimiter in untilSet
        {
            if char == delimiter
            {
                delimiterFound = true;
                break;
            }
        }

        if delimiterFound
        {
            break;
        }

        next(scanner);
        len += 1;
    }

    return scanner.src[start : start + len];
}

consumeUntilChar_ :: proc(scanner : ^scannerPkg.Scanner, until : rune) -> string
{
    result := consumeUntilCharSet_(scanner, []rune{until});
    return result;
}

consumeUntil :: proc{consumeUntilChar_, consumeUntilCharSet_};

computeSeatForNextBoardingPass :: proc(scanner : ^scannerPkg.Scanner) -> (row : int, col : int)
{
    using scannerPkg;
    using strings;
    
    assert(!isEof(scanner));

    code : string = consumeUntil(scanner, '\n');
    next(scanner); // Consume \n
    
    code = trim_right(code, "\r");
    assert(len(code) == 10);

    // Compute row
    
    {
        rowLower := 0;
        rowRange := 128;

        for i in 0..<7
        {
            char : byte = code[i];
            rowRange /= 2;
            
            if (char == 'F')
            {
                // Nothing
            }
            else
            {
                assert(char == 'B');
                rowLower += rowRange;
            }
        }

        assert(rowRange == 1);
        row = rowLower;
    }

    // Compute col
    
    {
        colLower := 0;
        colRange := 8;

        for i in 7..<10
        {
            char : byte = code[i];
            colRange /= 2;
            
            if (char == 'L')
            {
                // Nothing
            }
            else
            {
                assert(char == 'R');
                colLower += colRange;
            }
        }

        assert(colRange == 1);
        col = colLower;
    }

    return row, col;
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));

    highestId := -1;

    highestPossibleId :: 127 * 8 + 7;
    isSeatClaimed : [highestPossibleId + 1]bool;
    
    for !isEof(&scanner)
    {
        row, col := computeSeatForNextBoardingPass(&scanner);
        seatId := row * 8 + col;
        highestId = max(seatId, highestId);

        assert(!isSeatClaimed[seatId]);
        isSeatClaimed[seatId] = true;
    }

    unclaimedSeatId := -1;
    for seatId in 1..<highestPossibleId
    {
        if !isSeatClaimed[seatId] && isSeatClaimed[seatId - 1] && isSeatClaimed[seatId + 1]
        {
            assert(unclaimedSeatId == -1);
            unclaimedSeatId = seatId;
        }
    }

    fmt.println("Part 1:", highestId);
    fmt.println("Part 2:", unclaimedSeatId);
}
