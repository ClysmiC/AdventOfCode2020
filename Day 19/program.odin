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


isMatch :: inline proc(str: string, iRule: int, rules: []Rule) -> bool
{
    prefixLens := computeFullMatchPrefixLengthsForRule(str, iRule, rules);

    for length in prefixLens
    {
        if length == len(str)
        {
            return true;
        }
    }

    return false;

    // ---Procedures---

    // Returns either:
    // - An array with a single 0 value if the string is not prefixed by the rule
    // - An array of non-0 values which are the lengths of all of the possible prefixes
    //   that satisfy the rule
    //
    // Note - Returning an array of values supports rules that are recursive. We brute force all the possible
    //  number of times we can recursively expand the rule. The caller will need to check all possible lengths,
    //  since greedily taking the longest one might cause upcoming rules to run past the end of the string
    //  when they would otherwise match if we recursed fewer times.
    computeFullMatchPrefixLengthsForRule :: proc(
        str: string,
        iRule: int,
        rules: []Rule)
        -> [dynamic]int // @Leak
    {
        assert(iRule >= 0);
        assert(iRule < len(rules));
        
        result : [dynamic]int;
        
        if len(str) > 0
        {            
            rule := rules[iRule];
            
            for sequence in rule
            {
                prefixLens := computeFullMatchPrefixLengthsForRuleSequence(str, sequence, rules);
                for length in prefixLens
                {
                    if length > 0
                    {
                        append(&result, length);
                    }
                }
            }
        }

        if len(result) == 0
        {
            append(&result, 0);
        }
        
        return result;

        // ---Procedures---

        computeFullMatchPrefixLengthsForRuleSequence :: proc(
            str: string,
            sequence: RuleSequence,
            rules: []Rule)
            -> [dynamic]int // @Leak
        {
            // NOTE - "strCursors" and "result" arrays are kept in parallel. Removals use unordered_remove for
            //  efficiency, since the iterations don't rely on any particular order. That said, it does rely
            //  on identical unordered_removes resulting in identical orderings in the parallel arrays. I'm
            //  not sure if that is strictly guaranteed by unordered_remove, but with the obvious implementiation
            //  of that function, it should hold.
            
            strCursors := [dynamic]string { str };
            defer delete(strCursors);
            
            result := [dynamic]int{ 0 };
            
            for primitive in sequence
            {
                assert(len(result) == len(strCursors));
                
                switch primitive in primitive
                {
                    case rune:
                    {
                        // Rune matches can't proliferate, so we update or remove inline
                        
                        for i := 0; i < len(strCursors); i += 1
                        {
                            strCursor := &strCursors[i];

                            if len(strCursor) > 0 && (strCursor[0] == auto_cast primitive)
                            {
                                result[i] += 1;
                                strCursor^ = strCursor[1 : ];
                            }
                            else
                            {
                                unordered_remove(&result, i);
                                unordered_remove(&strCursors, i);
                                i -= 1;
                            }
                        }
                    }

                    case int:
                    {
                        // When rule matches don't proliferate, we update or remove inline
                        // When rule matches do proliferate, we remove inline and defer appending the updated values
                        //  until the end of the loop.
                        
                        strCursorsToAppend : [dynamic]string;
                        lensToAppend : [dynamic]int;
                        defer
                        {
                            delete(strCursorsToAppend);
                            delete(lensToAppend);
                        }
                        
                        for i := 0; i < len(strCursors); i += 1
                        {
                            strCursor := &strCursors[i];
                            
                            prefixLens := computeFullMatchPrefixLengthsForRule(strCursor^, primitive, rules);

                            assert(len(prefixLens) > 0);
                            if len(prefixLens) == 1
                            {
                                prefixLen := prefixLens[0];
                                if prefixLen == 0
                                {
                                    unordered_remove(&result, i);
                                    unordered_remove(&strCursors, i);
                                    i -= 1;
                                }
                                else
                                {
                                    result[i] += prefixLen;
                                    strCursor^ = strCursor[prefixLen : ];
                                }
                            }
                            else
                            {
                                priorLen := result[i];
                                
                                for length in prefixLens
                                {
                                    assert(length > 0);

                                    append(&strCursorsToAppend, strCursor[length : ]);
                                    append(&lensToAppend, priorLen + length);
                                }
                                
                                unordered_remove(&result, i);
                                unordered_remove(&strCursors, i);
                                i -= 1;
                            }
                        }

                        // HMM - No built-in "append all" function?
                        
                        for length in lensToAppend
                        {
                            append(&result, length);
                        }

                        for strCursor in strCursorsToAppend
                        {
                            append(&strCursors, strCursor);
                        }
                    }

                    case: assert(false);
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
