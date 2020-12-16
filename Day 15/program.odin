package main

import "core:fmt"
import scan "core:text/scanner"

NumberHistory :: struct
{
    latestTurn : int,
    prevLatestTurn : int,
}

HistoryMap :: map[int]NumberHistory;

takeTurn :: proc(historyMap : ^HistoryMap, prevNumber : int, turn : ^int) -> int
{
    assert(prevNumber in historyMap^);
    
    prevNumberHistory := historyMap[prevNumber];

    assert(prevNumberHistory.latestTurn == turn^ - 1);

    number : int = ---;

    if prevNumberHistory.prevLatestTurn == -1
    {
        // Last turn was the first time it was spoken
        number = 0;
    }
    else
    {
        number = prevNumberHistory.latestTurn - prevNumberHistory.prevLatestTurn;
    }

    if number in historyMap^
    {
        numberHistory := &historyMap[number];
        numberHistory.prevLatestTurn = numberHistory.latestTurn;
        numberHistory.latestTurn = turn^;
    }
    else
    {
        historyMap[number] = NumberHistory
        {
            latestTurn = turn^,
            prevLatestTurn = -1,
        };
    }
    
    turn^ += 1;
    return number;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    historyMap : HistoryMap;

    turn := 1;
    prevNumber : int;
    
    for !isEof(&scanner)
    {
        value, ok := tryConsumeInt(&scanner);
        assert(ok);

        scan.next(&scanner); // Consume ,
        consumeWhitespace(&scanner);

        historyMap[value] = NumberHistory
        {
            latestTurn = turn,
            prevLatestTurn = -1
        };
        
        turn += 1;

        prevNumber = value;
    }

    for turn <= 2020
    {
        prevNumber = takeTurn(&historyMap, prevNumber, &turn);
    }

    fmt.println("Part 1:", prevNumber);

    // @Slow - Maybe some better way than brute force? But N is small enough
    //  that brute forcing is reasonably quick...
    for turn <= 30000000
    {
        prevNumber = takeTurn(&historyMap, prevNumber, &turn);
    }

    fmt.println("Part 2:", prevNumber);
}
