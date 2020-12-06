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

AnswerSet :: [26]int;

computeAnswerSetForGroup :: proc(scanner : ^scannerPkg.Scanner) -> (answerSet : AnswerSet, groupCount : int)
{
    using scannerPkg;
    using strings;
    
    assert(!isEof(scanner));

    for peek(scanner) != '\r' && peek(scanner) != '\n' && peek(scanner) != EOF
    {
        answers : string = consumeUntil(scanner, '\n');
        next(scanner); // Consume \n
        
        answers = trim_right(answers, "\r");

        groupCount += 1;

        for char in answers
        {
            i := char - 'a';
            answerSet[i] += 1;
        }
    }
    
    consumeUntil(scanner, '\n');
    next(scanner); // Consume \n

    return answerSet, groupCount;
}

countAnswers :: proc(answerSet : AnswerSet, groupCount : int) -> (part1Count : int, part2Count : int)
{
    for i in 0..<26
    {
        if answerSet[i] > 0
        {
            part1Count += 1;
        }

        if answerSet[i] == groupCount
        {
            part2Count += 1;
        }
    }

    return part1Count, part2Count;
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));

    part1Result : int;
    part2Result : int;
    
    for !isEof(&scanner)
    {
        answers, groupCount := computeAnswerSetForGroup(&scanner);

        dPart1, dPart2 := countAnswers(answers, groupCount);
        part1Result += dPart1;
        part2Result += dPart2;
    }

    fmt.println("Part 1:", part1Result);
    fmt.println("Part 2:", part2Result);
}
