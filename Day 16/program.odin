package main

import "core:fmt"
import "core:strings"
import scan "core:text/scanner"

Field :: struct
{
    name : string,
    min0 : int,
    max0 : int,
    min1 : int,
    max1 : int,
}

Ticket :: struct
{
    values : [dynamic]int,
}

consumeTicket :: proc(scanner : ^scan.Scanner) -> Ticket
{
    ticket : Ticket;
    
    for
    {
        value, ok := tryConsumeInt(scanner); // @Hack - Must be >= 1 value!
        assert(ok);

        append(&ticket.values, value);
        
        if scan.peek(scanner) == ','
        {
            scan.next(scanner); // Consume ,
        }
        else
        {
            consumeWhitespace(scanner);
            break;
        }
    }

    return ticket;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    fields : [dynamic]Field;
    mine : Ticket;
    nearby : [dynamic]Ticket;
    
    for !isEof(&scanner)
    {
        label := consumeUntil(&scanner, ':');
        assert(len(label) > 0);

        colon := scan.next(&scanner);
        assert(colon == ':');
        
        consumeWhitespace(&scanner);

        switch label
        {
            case:
            {
                field : Field;
                field.name = label;
                
                ok : bool;
                
                field.min0, ok = tryConsumeInt(&scanner);
                assert(ok);

                dash := scan.next(&scanner);
                assert(dash == '-');

                field.max0, ok = tryConsumeInt(&scanner);
                assert(ok);

                ok = tryConsume(&scanner, " or ");
                assert(ok);

                field.min1, ok = tryConsumeInt(&scanner);
                assert(ok);

                dash = scan.next(&scanner);
                assert(dash == '-');

                field.max1, ok = tryConsumeInt(&scanner);
                assert(ok);

                consumeWhitespace(&scanner);

                append(&fields, field);
            }
            
            case "your ticket":
            {
                mine = consumeTicket(&scanner);
            }

            case "nearby tickets":
            {
                for !isEof(&scanner)
                {
                    append(&nearby, consumeTicket(&scanner));
                }
            }
        }
    }

    part1Result : int;

    validNearby : [dynamic]Ticket;
    
    for ticket in nearby
    {
        isAnyInvalid := false;
        
        for value in ticket.values
        {
            isValid := false;
            
            for field in fields
            {
                if (value >= field.min0 && value <= field.max0) || (value >= field.min1 && value <= field.max1)
                {
                    isValid = true;
                }
            }

            if !isValid
            {
                part1Result += value;
                isAnyInvalid = true;
            }
        }

        if !isAnyInvalid
        {
            append(&validNearby, ticket);
        }
    }

    fmt.println("Part 1:", part1Result);

    mapIValueToMapIFieldToIsValid := make([][]bool, len(mine.values));
    for _, i in mapIValueToMapIFieldToIsValid
    {
        mapIValueToMapIFieldToIsValid[i] = make([]bool, len(fields));

        for _, j in mapIValueToMapIFieldToIsValid[i]
        {
            mapIValueToMapIFieldToIsValid[i][j] = true;
        }
    }

    for ticket, iTicket in validNearby
    {
        for value, iValue in ticket.values
        {
            for field, iField in fields
            {
                isValidForField := (value >= field.min0 && value <= field.max0) || (value >= field.min1 && value <= field.max1);
                if !isValidForField
                {
                    mapIValueToMapIFieldToIsValid[iValue][iField] = false;
                }
            }
        }
    }

    mapIValueToIField := make([]int, len(mine.values));
    for _, iValue in mapIValueToIField
    {
        mapIValueToIField[iValue] = -1;
    }

    for
    {
        areAllValuesMapped := true;
        anyValueMappedThisIteration := false;
        
        for _, iValue in mapIValueToMapIFieldToIsValid
        {
            if mapIValueToIField[iValue] != -1
            {
                continue; // Already mapped
            }
            
            countValid : int;
            iFieldValidLatest := -1;
            
            for _, iField in mapIValueToMapIFieldToIsValid[iValue]
            {
                if mapIValueToMapIFieldToIsValid[iValue][iField]
                {
                    countValid += 1;
                    iFieldValidLatest = iField;
                }
            }

            assert(countValid > 0);
            assert(iFieldValidLatest != -1);

            if countValid == 1
            {
                // Map value to field
                mapIValueToIField[iValue] = iFieldValidLatest;
                anyValueMappedThisIteration = true;

                // Invalidate this field for all other values
                for _, iValueOther in mapIValueToMapIFieldToIsValid
                {
                    if iValue == iValueOther
                    {
                        continue;
                    }

                    mapIValueToMapIFieldToIsValid[iValueOther][iFieldValidLatest] = false;
                }
            }
            else
            {
                areAllValuesMapped = false;
            }
        }

        assert(anyValueMappedThisIteration); // If we trip this assert, we are stuck in an infinite loop!
        if areAllValuesMapped
        {
            break;
        }
    }

    part2Result := 1;
    for field, iField in fields
    {
        if strings.has_prefix(field.name, "departure")
        {
            // @Slow - I should have built the iValue->iField mapping the other way around to avoid this loop. *Shrug*

            iValue := -1;
            for iFieldQuery, iValueQuery in mapIValueToIField
            {
                assert(iFieldQuery != -1);
                if iFieldQuery == iField
                {
                    iValue = iValueQuery;
                    break;
                }
            }

            assert(iValue != -1);

            part2Result *= mine.values[iValue];
        }
    }

    fmt.println("Part 2:", part2Result);
}
