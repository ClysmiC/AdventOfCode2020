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

consumeUntil :: proc(scanner : ^scannerPkg.Scanner, until : []rune) -> string
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
        for delimiter in until
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

isDigit :: proc(char : rune) -> bool
{
    return (char >= '0' && char <= '9');
}

isHexDigit :: proc(char : rune) -> bool
{
    return isDigit(char) ||
        (char >= 'a' && char <= 'f'); // ||
        /* (char >= 'F' && char <= 'F'); */
}

processNextPassport :: proc(scanner : ^scannerPkg.Scanner) -> (meetsPart1Criteria : bool, meetsPart2Criteria : bool)
{
    using scannerPkg;
    using strconv;
    using strings;
    
    assert(!isEof(scanner));

    isByrPresent : bool;
    isByrValid : bool;
    
    isIyrPresent : bool;
    isIyrValid : bool;
    
    isEyrPresent : bool;
    isEyrValid : bool;
    
    isHgtPresent : bool;
    isHgtValid : bool;
    
    isHclPresent : bool;
    isHclValid : bool;
    
    isEclPresent : bool;
    isEclValid : bool;

    isPidPresent : bool;
    isPidValid : bool;

    for
    {
        code : string = consumeUntil(scanner, []rune{':'});
        next(scanner); // Consume :

        value : string = consumeUntil(scanner, []rune{' ', '\n'});
        value = trim_right(value, "\r");
        
        switch code
        {
            case "byr":
            {
                isByrPresent = true;
                if byr, ok := parse_int(value); ok && len(value) == 4
                {
                    isByrValid = (byr >= 1920 && byr <= 2002);
                }
                else
                {
                    assert(false);
                }
            }

            case "iyr":
            {
                isIyrPresent = true;
                if iyr, ok := parse_int(value); ok && len(value) == 4
                {
                    isIyrValid = (iyr >= 2010 && iyr <= 2020);
                }
                else
                {
                    assert(false);
                }
            }

            case "eyr":
            {
                isEyrPresent = true;
                if eyr, ok := parse_int(value); ok && len(value) == 4
                {
                    isEyrValid = (eyr >= 2020 && eyr <= 2030);
                }
                else
                {
                    assert(false);
                }
            }

            case "hgt":
            {
                isHgtPresent = true;

                Unit :: enum
                {
                    None,
                    Cm,
                    In,
                };

                unit : Unit;
                
                if has_suffix(value, "cm")
                {
                    unit = .Cm;
                    value = trim_suffix(value, "cm");
                }
                else if has_suffix(value, "in")
                {
                    unit = .In;
                    value = trim_suffix(value, "in");
                }

                if unit != .None
                {
                    if hgt, ok := parse_int(value); ok
                    {
                        isHgtValid =
                            (unit == .Cm && hgt >= 150 && hgt <= 193) ||
                            (unit == .In && hgt >= 59 && hgt <= 76);
                    }
                }
            }

            case "hcl":
            {
                isHclPresent = true;

                if len(value) == 7 && value[0] == '#'
                {
                    isHclValid = true;
                    
                    for iChar in 1..<7
                    {
                        if !isHexDigit(rune(value[iChar]))
                        {
                            isHclValid = false;
                            break;
                        }
                    }
                }
            }

            case "ecl":
            {
                isEclPresent = true;

                isEclValid =
                    (value == "amb" ||
                     value == "blu" ||
                     value == "brn" ||
                     value == "gry" ||
                     value == "grn" ||
                     value == "hzl" ||
                     value == "oth");

                test := value == "blue";
            }

            case "pid":
            {
                isPidPresent = true;

                if len(value) == 9
                {
                    isPidValid = true;
                    
                    for iChar in 0..<9
                    {
                        if !isDigit(rune(value[iChar]))
                        {
                            isPidValid = false;
                            break;
                        }
                    }
                }
            }

            case "cid":
            {
            }

            case:
            {
                fmt.println("Unknown code:", code);
            }
        }

        delimiter : rune = next(scanner);
        afterDelimiter : rune = peek(scanner);

        if afterDelimiter == '\r'
        {
            next(scanner);
            afterDelimiter = peek(scanner);
            assert(afterDelimiter == '\n');
        }
        
        if delimiter == EOF ||
            (delimiter == '\n' &&
             (afterDelimiter == EOF || afterDelimiter == '\n')
            )
        {
            next(scanner); // Consume second \n, no-op if EOF
            
            // Check validity
            // NOTE - Cid is optional

            meetsPart1Criteria = isByrPresent &&
                isIyrPresent &&
                isEyrPresent &&
                isHgtPresent &&
                isHclPresent &&
                isEclPresent &&
                isPidPresent;

            meetsPart2Criteria = meetsPart1Criteria &&
                isByrValid &&
                isIyrValid &&
                isEyrValid &&
                isHgtValid &&
                isHclValid &&
                isEclValid &&
                isPidValid;

            return;
        }
    }
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));
    
    part1Result : int;
    part2Result : int;

    for !isEof(&scanner)
    {
        part1Met, part2Met : bool = processNextPassport(&scanner);
        if part1Met
        {
            part1Result += 1;
        }

        if part2Met
        {
            part2Result += 1;
        }
    }

    fmt.println("Part 1:", part1Result);
    fmt.println("Part 2:", part2Result);
}
