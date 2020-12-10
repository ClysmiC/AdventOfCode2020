package main

import "core:fmt"
import "core:strconv"
import scannerPkg "core:text/scanner"
import "core:sort"

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));

    input : [dynamic]int = makeIntArray(&scanner);
    defer delete(input);

    // Wall outlet
    append(&input, 0);
    
    sort.slice(input[:]);

    // My device
    append(&input, input[len(input) - 1] + 3);

    // Part 1

    {
        countDelta1 : int;
        countDelta3 : int;
        
        for i in 0..<len(input) - 1
        {
            delta := input[i + 1] - input[i];

            if delta == 1
            {
                countDelta1 += 1;
            }
            else if delta == 3
            {
                countDelta3 += 1;
            }
        }

        part1Result := countDelta1 * countDelta3;
        fmt.println("Part 1:", part1Result);
    }

    // Part 2

    {
        mapIToCountPossible := make([]i64, len(input));
        defer delete(mapIToCountPossible);

        // HMM - Better way to iterate in reverse?
        for iRev in 0..<len(input)
        {
            i := len(input) - iRev - 1;
            val := input[i];

            OOB :: 999;

            // HMM - Better way to assign same value to multiple variables?
            i1, i2, i3 := OOB, OOB, OOB;
            val1, val2, val3 := OOB, OOB, OOB;

            if iRev > 0
            {
                i1 = i + 1;
                val1 = input[i1];
            }
            
            if iRev > 1
            {
                i2 = i + 2;
                val2 = input[i2];
            }
            
            if iRev > 2
            {
                i3 = i + 3;
                val3 = input[i3];
            }

            countPossible : i64 = 0;

            if val1 - val <= 3
            {
                assert(i1 != OOB);
                countPossible += mapIToCountPossible[i1];
            }

            if val2 - val <= 3
            {
                assert(i2 != OOB);
                countPossible += mapIToCountPossible[i2];
            }

            if val3 - val <= 3
            {
                assert(i3 != OOB);
                countPossible += mapIToCountPossible[i3];
            }

            if countPossible == 0
            {
                assert(i == len(input) - 1);
                countPossible = 1;
            }

            mapIToCountPossible[i] = countPossible;
        }

        fmt.println("Part 2:", mapIToCountPossible[0]);
    }
}
