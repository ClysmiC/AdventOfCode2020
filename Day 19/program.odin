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
    iRuleParents : [dynamic]int;
    defer delete(iRuleParents);
    
    prefixLen := computeFullMatchPrefixLengthForRule(str, iRule, &iRuleParents, rules);
    return prefixLen == len(str);

    // ---Proceduceres---
    
    computeFullMatchPrefixLengthForRule :: proc(
        str: string,
        iRule: int,
        iRuleParents: ^[dynamic]int, // Note - Should not include iRule
        rules: []Rule)
        -> int
    {
        if len(str) == 0
        {
            return 0;
        }
        
        assert(iRule >= 0);
        assert(iRule < len(rules));

        rule := rules[iRule];
        append(iRuleParents, iRule);
        
        result := 0;
        for sequence in rule
        {
            prefixLen := computeFullMatchPrefixLengthForRuleSequence(str, iRuleParents, sequence, rules);
            result = max(result, prefixLen);
            
            if result == len(str)
            {
                break;
            }
        }

        pop(iRuleParents);

        return result;

        // ---Procedures---
        
        computeFullMatchPrefixLengthForRuleSequence :: proc(
            str: string,
            stackIRule: ^[dynamic]int, // Note - Top of stack is the rule we are computing prefix length for
            sequence: RuleSequence,    // Note - This should correspond to one of the sequences in the rule on top of the stack
            rules: []Rule) -> int
        {
            strCursor := str;

            // @HACK Only works with 0 or 1 self-or-parent-loops per sequence. 
            // The idea is to work forwards until hitting a loop. Then work bacwards
            //  from the back. Then, you know how much the loop needs to "inflate" to
            
            prefixLen := 0;
            iPrimitiveLoop := -1;

            // Work forward

            LForward:
            for primitive, iPrimitive in sequence
            {
                switch primitive in primitive
                {
                    case rune:
                    {
                        if len(strCursor) > 0 && (strCursor[0] == auto_cast primitive)
                        {
                            prefixLen += 1;
                            strCursor = strCursor[1 : ];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case int:
                    {
                        for iRuleFromStack in stackIRule
                        {
                            if primitive == iRuleFromStack
                            {
                                iPrimitiveLoop = iPrimitive;
                                break LForward;
                            }
                        }

                        matchPrefixLen := computeFullMatchPrefixLengthForRule(strCursor, primitive, stackIRule, rules);

                        if matchPrefixLen > 0
                        {
                            prefixLen += matchPrefixLen;
                            strCursor = strCursor[matchPrefixLen : ];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case: assert(false);
                }
            }
            
            if iPrimitiveLoop == -1
            {
                // We didn't stop at a loop

                return prefixLen;
            }

            // We stopped at a loop, so work backwards
            // TODO - Need to work backwards starting from the root parent rule... ughhhh this bookkeeping is getting gross

            suffixLen := 0;

            for iPrimitive := len(sequence) - 1; iPrimitive > iPrimitiveLoop; iPrimitive -= 1
            {
                primitive := sequence[iPrimitive];

                switch primitive in primitive
                {
                    case rune:
                    {
                        if len(strCursor) > 0 && (strCursor[len(strCursor) - 1] == auto_cast primitive)
                        {
                            suffixLen += 1;
                            strCursor = strCursor[ : len(strCursor) - 1];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case int:
                    {
                        for iRuleFromStack in stackIRule
                        {
                            // If this triggers, it means there were multiple rule loops in a sequence, which we don't support!
                            assert(primitive != iRuleFromStack);
                        }

                        matchSuffixLen := computeFullMatchSuffixLengthForRule(strCursor, primitive, stackIRule, rules);

                        if matchSuffixLen > 0
                        {
                            suffixLen += matchSuffixLen;
                            strCursor = strCursor[ : len(strCursor) - matchSuffixLen];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case: assert(false);
                }
            }
            
            iRuleLoop := sequence[iPrimitiveLoop].(int);

            foundInStack := false;

            for iRuleInStack in stackIRule
            {
                if iRuleInStack == iRuleLoop
                {
                    foundInStack = true;
                    break;
                }
            }
            assert(foundInStack);

            inflateLen := computeFullMatchPrefixLengthForRule(strCursor, iRuleLoop, stackIRule, rules);

            if prefixLen + inflateLen + suffixLen == len(str)
            {
                return len(str);
            }
            else
            {
                assert(prefixLen + inflateLen + suffixLen < len(str));

                // Inflate starts at the beginning of the region needing inflation and works forwards. If we don't have
                //  a complete match, the inflated match still contributes to our resulting prefix length
                
                return prefixLen + inflateLen;
            }
        }
    }

    computeFullMatchSuffixLengthForRule :: proc(
        str: string,
        iRule: int,
        iRuleParents: ^[dynamic]int, // Note - Should not include iRule
        rules: []Rule)
        -> int
    {
        if len(str) == 0
        {
            return 0;
        }
        
        assert(iRule >= 0);
        assert(iRule < len(rules));

        rule := rules[iRule];
        append(iRuleParents, iRule);
        
        result := 0;
        for iSequence := len(rule) - 1; iSequence >= 0; iSequence -= 1
        {
            sequence := rule[iSequence];
            
            suffixLen := computeFullMatchSuffixLengthForRuleSequence(str, iRuleParents, sequence, rules);
            result = max(result, suffixLen);
            
            if result == len(str)
            {
                break;
            }
        }

        pop(iRuleParents);

        return result;

        // ---Procedures---
        
        computeFullMatchSuffixLengthForRuleSequence :: proc(
            str: string,
            stackIRule: ^[dynamic]int, // Note - Top of stack is the rule we are computing prefix length for
            sequence: RuleSequence,    // Note - This should correspond to one of the sequences in the rule on top of the stack
            rules: []Rule)
            -> int
        {
            strCursor := str;

            // @HACK Only works with 0 or 1 self references per sequence. 
            // The idea is to work backwards until hitting a self reference. Then work forwards
            //  from the front. Then, you know how much the self-reference needs to "inflate" to
            
            suffixLen := 0;
            iPrimitiveLoop := -1;

            // Work backwards

            LBackward:
            for iPrimitive := len(sequence) - 1; iPrimitive >= 0; iPrimitive -= 1
            {
                primitive := sequence[iPrimitive];

                switch primitive in primitive
                {
                    case rune:
                    {
                        if len(strCursor) > 0 && (strCursor[len(strCursor) - 1] == auto_cast primitive)
                        {
                            suffixLen += 1;
                            strCursor = strCursor[ : len(strCursor) - 1];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case int:
                    {
                        for iRuleFromStack in stackIRule
                        {
                            if primitive == iRuleFromStack
                            {
                                iPrimitiveLoop = iPrimitive;
                                break LBackward;
                            }
                        }

                        matchSuffixLen := computeFullMatchSuffixLengthForRule(strCursor, primitive, stackIRule, rules);

                        if matchSuffixLen > 0
                        {
                            suffixLen += matchSuffixLen;
                            strCursor = strCursor[ : len(strCursor) - matchSuffixLen];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case: assert(false);
                }
            }
            
            if iPrimitiveLoop == -1
            {
                // We didn't stop at a self reference

                return suffixLen;
            }

            // We stopped at a self-reference, so work forwards
            // TODO - Need to work forwards starting from the most recently evaluated parent rule????
            //  Something like that???

            prefixLen := 0;
            
            for iPrimitive in 0..<iPrimitiveLoop
            {
                primitive := sequence[iPrimitive];
                
                switch primitive in primitive
                {
                    case rune:
                    {
                        if len(strCursor) > 0 && (strCursor[0] == auto_cast primitive)
                        {
                            prefixLen += 1;
                            strCursor = strCursor[1 : ];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case int:
                    {
                        for iRuleFromStack in stackIRule
                        {
                            // If this triggers, it means there were multiple rule loops in a sequence, which we don't support!
                            assert(primitive != iRuleFromStack);
                        }
                        
                        matchPrefixLen := computeFullMatchPrefixLengthForRule(strCursor, primitive, stackIRule, rules);

                        if matchPrefixLen > 0
                        {
                            prefixLen += matchPrefixLen;
                            strCursor = strCursor[matchPrefixLen : ];
                        }
                        else
                        {
                            return 0;
                        }
                    }

                    case: assert(false);
                }
            }
            
            iRuleLoop := sequence[iPrimitiveLoop].(int);
            
            foundInStack := false;

            for iRuleInStack in stackIRule
            {
                if iRuleInStack == iRuleLoop
                {
                    foundInStack = true;
                    break;
                }
            }
            assert(foundInStack);

            inflateLen := computeFullMatchSuffixLengthForRule(strCursor, iRuleLoop, stackIRule, rules);

            if prefixLen + inflateLen + suffixLen == len(str)
            {
                return len(str);
            }
            else
            {
                assert(prefixLen + inflateLen + suffixLen < len(str));

                // Inflate starts at the end of the region needing inflation and works backwards. If we don't have
                //  a complete match, the inflated match still contributes to our resulting suffix length
                
                return suffixLen + inflateLen;
            }
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
