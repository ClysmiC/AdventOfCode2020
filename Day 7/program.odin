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

tryConsume :: proc(scanner : ^scannerPkg.Scanner, match : string) -> bool
{
    using scannerPkg;

    saved : Scanner = scanner^;

    for char in match
    {
        if next(scanner) != char
        {
            scanner^ = saved;
            return false;
        }
    }

    return true;
}

BagType :: struct
{
    adj : string,
    color : string,
}

BagTypeAndQuantity :: struct
{
    type : BagType,
    quantity : int,
}

BagContents :: map[BagType]int;
BagContentList :: map[BagType]BagContents;

tryConsumeBagType :: proc(scanner : ^scannerPkg.Scanner) -> (BagType, bool)
{
    using scannerPkg;
    
    saved : Scanner = scanner^;
    
    adj : string = consumeUntil(scanner, ' ');
    if len(adj) > 0
    {
        next(scanner);

        color : string = consumeUntil(scanner, ' ');
        if len(color) > 0
        {
            next(scanner);

            if tryConsume(scanner, "bag")
            {
                // Handle all the trailing letters/punctuation that are in the input file
                
                peekChar := peek(scanner);
                if peekChar == 's' || peekChar == '.' || peekChar == ','
                {
                    next(scanner);
                    peekChar = peek(scanner);
                }

                if peekChar == ','
                {
                    next(scanner);
                    peekChar = peek(scanner);
                }

                if peekChar == ' '
                {
                    next(scanner);
                    peekChar = peek(scanner);
                }

                if peekChar == '.'
                {
                    next(scanner);
                    peekChar = peek(scanner);
                }

                if peekChar == '\n'
                {
                    next(scanner);
                    peekChar = peek(scanner);
                }

                if peekChar == '\r'
                {
                    next(scanner);
                    newline := next(scanner);
                    assert(newline == '\n');
                    peekChar = peek(scanner);
                }
                
                result := BagType
                {
                    adj = adj,
                    color = color,
                };

                return result, true;
            }
        }
    }

    scanner^ = saved;
    return ---, false;
}

tryConsumeBagTypeAndQuantity :: proc(scanner : ^scannerPkg.Scanner) -> (BagTypeAndQuantity, bool)
{
    using scannerPkg;
    using strconv;
    
    saved : Scanner = scanner^;

    quantityStr : string = consumeUntil(scanner, ' ');
    if len(quantityStr) > 0
    {
        if quantity, ok := parse_int(quantityStr); ok
        {
            next(scanner); // consume ' '

            if type, ok := tryConsumeBagType(scanner); ok
            {
                result := BagTypeAndQuantity
                {
                    type = type,
                    quantity = quantity
                };

                return result, true;
            }
        }
    }

    scanner^ = saved;
    return ---, false;
}

buildBagContentList :: proc(scanner : ^scannerPkg.Scanner) -> BagContentList
{
    result : BagContentList;

    for !isEof(scanner)
    {
        validParse := false;
        
        if key, ok := tryConsumeBagType(scanner); ok
        {
            if ok := tryConsume(scanner, "contain "); ok
            {
                // HMM - Is there better syntax to do this??
                
                assert(!(key in result));
                result[key] = make(BagContents);
                contentsMap : ^BagContents = &result[key];
                
                if ok := tryConsume(scanner, "no other bags.\r\n"); ok
                {
                    validParse = true;
                }
                else
                {
                    for
                    {
                        if typeAndQuantity, ok := tryConsumeBagTypeAndQuantity(scanner); ok
                        {
                            contentsMap[typeAndQuantity.type] = typeAndQuantity.quantity;
                            validParse = true;
                        }
                        else
                        {
                            break;
                        }
                    }
                }
            }
        }

        assert(validParse);
    }
    
    return result;
}

ShinyGoldCachedResults :: map[BagType]bool;

SHINY_GOLD :: BagType
{
    adj = "shiny",
    color = "gold",
};

containsShinyGold :: proc(
    bagList : ^BagContentList,
    cachedResults : ^ShinyGoldCachedResults,
    outermostType : BagType)
    -> bool
{
    test := outermostType;

    // HMM - This is kind of funky, but the problem seems to say that a shiny gold bag itself doesn't qualify
    // @Slow - We are checking this outside of the recursion too
    
    if outermostType == SHINY_GOLD
    {
        return false;
    }
    
    if outermostType in cachedResults^
    {
        return cachedResults[outermostType];
    }

    for innerType in bagList[outermostType]
    {
        if innerType == SHINY_GOLD
        {
            return true;
        }
        
        if containsShinyGold(bagList, cachedResults, innerType)
        {
            return true;
        }
    }
    
    return false;
}

countInnerBags :: proc(
    bagList : ^BagContentList,
    outermostType : BagType)
    -> int
{
    result : int;
    
    for innerType, quantity in bagList[outermostType]
    {
        result += (1 + countInnerBags(bagList, innerType)) * quantity;
    }

    return result;
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));

    bagList := buildBagContentList(&scanner);
    cachedResults : ShinyGoldCachedResults;

    part1Result : int;
    for outermostType in bagList
    {
        test := outermostType;
        if containsShinyGold(&bagList, &cachedResults, outermostType)
        {
            part1Result += 1;
        }
    }

    part2Result := countInnerBags(&bagList, SHINY_GOLD);

    fmt.println("Part 1:", part1Result);
    fmt.println("Part 2:", part2Result);
}
