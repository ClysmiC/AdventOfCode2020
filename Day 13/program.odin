package main

import "core:fmt"
import "core:math"
import scan "core:text/scanner"

Bus :: struct
{
    id : i64,
    index : i64,
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    buses : [dynamic]Bus;
    defer delete(buses);

    // Read input
    
    tStart, ok := tryConsumeInt(&scanner);
    assert(ok);

    consumeWhitespace(&scanner);

    index := 0;
    
    for !isEof(&scanner)
    {
        value, ok := tryConsumeInt(&scanner);

        if ok
        {
            scan.next(&scanner);
            append(&buses, Bus{ id = auto_cast value, index = auto_cast index });
        }
        else
        {
            xChar := scan.next(&scanner);
            commaChar := scan.next(&scanner);
            assert(xChar == 'x');
            assert(commaChar == ',');
        }

        consumeWhitespace(&scanner);
        index += 1;
    }
    
    // Part 1

    t : i64 = auto_cast tStart;
    for
    {
        busIdFound : i64 = -1;
        for bus in buses
        {
            if t % bus.id == 0
            {
                busIdFound = bus.id;
                break;
            }
        }

        if busIdFound != -1
        {
            part1Result := busIdFound * (t - auto_cast tStart);
            fmt.println("Part 1:", part1Result);
            break;
        }
        else
        {
            t += 1;
        }
    }

    // Part 2

    slowest : Bus;
    slow : Bus; // 2nd slowest
    
    for bus in buses
    {
        if bus.id > slowest.id
        {
            slow = slowest;
            slowest = bus;
        }
        else if bus.id > slow.id
        {
            slow = bus;
        }
    }

    lcmSlowIds := math.lcm(slow.id, slowest.id);

    // Quickly filter out any number that doesn't line up with the two slowest buses

    dTSlow := slow.index - slowest.index;
    dTBus0 := buses[0].index - slowest.index;

    tSlowest : i64 = 2 * slowest.id; // @Hack - No point in checking minute 0... also lets me avoid thinking about using % with negative t values
    dTLoop := slowest.id;
    
    for
    {
        tSlow := tSlowest + dTSlow;

        // @Slow - Once we set dTLoop to the lcm, this check will always be true
        if tSlow % slow.id == 0
        {
            // Might be a match!
            // Check all of the buses!

            tBus0 := tSlowest + dTBus0;

            success := true;
            for bus in buses
            {
                t := tBus0 + bus.index;

                if t % bus.id != 0
                {
                    success = false;
                    break;
                }
            }

            if success
            {
                fmt.println("Part 2:", tBus0);
                break;
            }
            else
            {
                // Wasn't a match. But we can now increment the loop by the least common multiple
                //  of the two slowest to find another place that might be a match!
                
                // @Slow - *could* compute the lcm of all the buses that *did* match, instead of just the
                //  two slowest ones.

                dTLoop = lcmSlowIds;
            }
        }

        tSlowest += dTLoop;
    }
}
