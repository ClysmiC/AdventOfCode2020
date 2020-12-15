package main

import "core:fmt"
import scan "core:text/scanner"

Mask :: struct
{
    maskX : i64,      // X bits
    cntX : uint,
    
    mask1 : i64,      // 1 bits
    mask0 : i64,      // 0 bits
}

clearMask :: proc(mask : ^Mask)
{
    mask.maskX = 0;
    mask.cntX = 0;
    mask.mask1 = 0;
    mask.mask0 = 0;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    mask : Mask;
    
    memory1 : map[i64]i64;
    memory2 : map[i64]i64;
    
    for !isEof(&scanner)
    {
        op := consumeUntil(&scanner, []rune{' ', '['});
        if op == "mask"
        {
            ok := tryConsume(&scanner, " = ");
            assert(ok);

            clearMask(&mask);
            
            maskBit : i64 = 1 << 35;
            for iBit in 0..<36
            {
                c := scan.next(&scanner);
                switch c
                {
                    case 'X':
                    {
                        mask.maskX |= maskBit;
                        mask.cntX += 1;
                    }
                    
                    case '1': mask.mask1 |= maskBit;
                    case '0': mask.mask0 |= maskBit;
                    
                    case: assert(false);
                }
                
                maskBit >>= 1;
            }

            assert(maskBit == 0);
        }
        else if op == "mem"
        {
            ok := tryConsume(&scanner, "[");
            assert(ok);

            address1 : i64;
            address1, ok = tryConsumeInt64(&scanner);
            assert(ok);

            ok = tryConsume(&scanner, "] = ");
            assert(ok);

            value : i64;
            value, ok = tryConsumeInt64(&scanner);
            assert(ok);

            memory1[address1] = (value & mask.maskX) | mask.mask1;

            // Iterate 2^(count X) possible addresses
            for iMask in 0..<(1 << mask.cntX)
            {
                iX : uint;
                maskFloat : i64;

                // @Slow - Couldn't find a bitscan intrinsic?
                maskBit : i64 = 1 << 35;
                for iBit in 0..<36
                {
                    if mask.maskX & maskBit != 0
                    {
                        // Decide whether this bit should be a 0 or a 1
                        if iMask & (1 << iX) != 0
                        {
                            maskFloat |= maskBit;
                        }
                        
                        iX += 1;
                    }

                    maskBit >>= 1;                    
                }
                
                address2 := (address1 & mask.mask0) | mask.mask1 | maskFloat;
                memory2[address2] = value;
            }
        }

        consumeWhitespace(&scanner);
    }

    sum1 : i64;
    for address, value in memory1
    {
        sum1 += value;
    }

    fmt.println("Part 1:", sum1);

    sum2 : i64;
    for address, value in memory2
    {
        sum2 += value;
    }

    fmt.println("Part 2:", sum2); 
}
