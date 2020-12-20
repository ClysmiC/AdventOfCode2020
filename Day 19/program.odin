package main

import "core:fmt"
import scan "core:text/scanner"

RulePrimitive :: union
{
    rune,
    int,
}

RuleSequence :: [dynamic]RulePrimitive;
Rule :: [dynamic]RuleSequence;

// If string is prefixed by something fully matching the rule, returns the length of the prefix
// Otherwise, returns 0.

isMatch :: inline proc(str: string, iRule: int, rules: []Rule) -> bool
{
    prefixLen := computeFullMatchPrefixLengthForRule(str, iRule, rules);
    return prefixLen == len(str);

    // ---
    computeFullMatchPrefixLengthForRule :: proc(str: string, iRule: int, rules: []Rule) -> int
    {
        if len(str) == 0
        {
            return 0;
        }
        
        assert(iRule >= 0);
        assert(iRule < len(rules));

        rule := rules[iRule];
        
        for sequence in rule
        {
            if prefixLen := computeFullMatchPrefixLengthForRuleSequence(str, sequence, rules)
            ;  prefixLen > 0
            {
                return prefixLen;
            }
        }

        return 0;

        // ---
        computeFullMatchPrefixLengthForRuleSequence :: proc(str: string, sequence: RuleSequence, rules: []Rule) -> int
        {
            strCursor := str;
            
            result := 0;
            for primitive in sequence
            {
                switch primitive in primitive
                {
                    case rune:
                    {
                        if len(strCursor) > 0 && (strCursor[0] == auto_cast primitive)
                        {
                            result += 1;
                            strCursor = strCursor[1 : ];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case int:
                    {
                        prefixLen := computeFullMatchPrefixLengthForRule(strCursor, primitive, rules);

                        if prefixLen > 0
                        {
                            result += prefixLen;
                            strCursor = strCursor[prefixLen : ];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case:
                    {
                        assert(false);
                        return 0;
                    }
                }
            }

            return result;
        }
    }
}

ensure :: proc(array: ^[dynamic]$T, index: int, item: T)
{
    if index >= len(array)
    {
        resize(array, index + 1);
    }
    
    array[index] = item;
}

main :: proc()
{
    scanner1 : scan.Scanner;
    scan.init(&scanner1, string(#load("input.txt")));

    rules : [dynamic]Rule;

    // Parse rules

    LRule:
    for // each rule
    {
        index, ok := tryConsumeInt(&scanner1);
        assert(ok);
        
        ok = tryConsume(&scanner1, ": ");
        assert(ok);

        rule : Rule;

        isEol := false;
        
        LSequence:
        for // each sequence
        {
            sequence : RuleSequence;

            LPrimitive:
            for // each primitive
            {
                if scan.peek(&scanner1) == '"'
                {
                    scan.next(&scanner1);
                    c := scan.next(&scanner1);
                    closeQuote := scan.next(&scanner1);
                    assert(closeQuote == '"');

                    append(&sequence, c);
                }
                else
                {
                    iRule, ok := tryConsumeInt(&scanner1);
                    assert(ok);

                    append(&sequence, iRule);
                }

                isEol = !tryConsume(&scanner1, " ");
                if isEol || tryConsume(&scanner1, "| ")
                {
                    break LPrimitive;
                }
            }
            
            append(&rule, sequence);

            if isEol
            {
                eol := tryConsume(&scanner1, "\r\n");
                assert(eol);
                break LSequence;
            }
        }

        ensure(&rules, index, rule);
        
        if tryConsume(&scanner1, "\r\n")
        {
            break LRule;
        }
    }

    //
    // Match values to rules

    scanner2 := scanner1; // Save scanner state so part 2 can re-scan from the middle of the file

    // Part 1
    
    scanner := &scanner1;
    
    part1Result := 0;
    for !isEof(scanner)
    {
        str := consumeUntil(scanner, []rune{'\r', '\n'});
        consumeWhitespace(scanner);

        if isMatch(str, 0, rules[:])
        {
            part1Result += 1;
        }
    }

    fmt.println("Part 1: ", part1Result);

    // Part 2

    scanner = &scanner2;

    // TODO - Step through part 2 with debugger to see what is going wrong
    //  with loopy rules!
    
    rules[8] = [dynamic]RuleSequence{
        { int(42) },
        { int(42), int(8) }
    };

    rules[11] = [dynamic]RuleSequence{
        { int(42), int(31) },
        { int(42), int(11), int(31) }
    };

    part2Result := 0;
    for !isEof(scanner)
    {
        str := consumeUntil(scanner, []rune{'\r', '\n'});
        consumeWhitespace(scanner);

        if isMatch(str, 0, rules[:])
        {
            part2Result += 1;
        }
    }

    fmt.println("Part 2: ", part2Result);
}
