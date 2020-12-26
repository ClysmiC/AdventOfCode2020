package main

import scan "core:text/scanner"
import "core:strconv"

isEof :: proc(scanner: ^scan.Scanner) -> bool
{
    using scan;
    
    return peek(scanner) == EOF;
}

consumeUntilOrPast_ :: proc(scanner: ^scan.Scanner, set: []rune, shouldPass: bool) -> string
{
    using scan;
    
    start: int = position(scanner).offset;
    len: int;
    
    for
    {
        c: rune = peek(scanner);
        if c == EOF
        {
            break;
        }

        delimiterFound := false;
        for delimiter in set
        {
            if c == delimiter
            {
                delimiterFound = true;
                break;
            }
        }

        if !delimiterFound || shouldPass
        {
            next(scanner);
            len += 1;
        }

        if delimiterFound
        {
            break;
        }
    }

    return scanner.src[start: start + len];
}

o_consumeUntilCharSet :: proc(scanner: ^scan.Scanner, untilSet: []rune) -> string
{
    return consumeUntilOrPast_(scanner, untilSet, false);
}

o_consumeUntilChar :: proc(scanner: ^scan.Scanner, until: rune) -> string
{
    return consumeUntilOrPast_(scanner, []rune{until}, false);
}

o_consumePastCharSet :: proc(scanner: ^scan.Scanner, pastSet: []rune) -> string
{
    return consumeUntilOrPast_(scanner, pastSet, true);
}

o_consumePastChar :: proc(scanner: ^scan.Scanner, past: rune) -> string
{
    return consumeUntilOrPast_(scanner, []rune{past}, true);
}

consumeUntil :: proc{o_consumeUntilChar, o_consumeUntilCharSet};
consumePast :: proc{o_consumePastChar, o_consumePastCharSet};

tryConsume :: proc(scanner: ^scan.Scanner, match: string) -> bool
{
    using scan;

    saved: Scanner = scanner^;

    for c in match
    {
        nextChar := next(scanner);
        if nextChar != c
        {
            scanner^ = saved;
            return false;
        }
    }

    return true;
}

makeIntArray :: proc(scanner: ^scan.Scanner) -> [dynamic]int
{
    result: [dynamic]int;
    
    for 
    {
        if value, ok := tryConsumeInt(scanner); ok
        {
            append(&result, value);
        }
        else
        {
            break;
        }
    }

    return result;
}

o_consumeThroughSet :: proc(scanner: ^scan.Scanner, throughSet: []rune) -> string
{
    using scan;
    
    start: int = position(scanner).offset;
    len: int;
    
    for
    {
        char_: rune = peek(scanner);
        if char_ == EOF
        {
            break;
        }

        matchFound:= false;
        for match in throughSet
        {
            if char_ == match
            {
                matchFound = true;
                break;
            }
        }

        if !matchFound
        {
            break;
        }

        next(scanner);
        len += 1;
    }

    return scanner.src[start : start + len];
}

o_consumeThroughChar :: proc(scanner: ^scan.Scanner, through: rune) -> string
{
    return o_consumeThroughSet(scanner, []rune{through});
}

consumeThrough :: proc{ o_consumeThroughChar, o_consumeThroughSet };

tryConsumeInt :: proc(scanner: ^scan.Scanner) -> (int, bool)
{
    using scan;
    using strconv;

    saved: Scanner = scanner^;

    valueStr := consumeThrough(scanner, []rune{'-', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' }); // @Hack

    if value, ok := parse_int(valueStr); ok
    {
        return value, true;
    }

    scanner^ = saved;
    return ---, false;
}

tryConsumeInt64 :: proc(scanner: ^scan.Scanner) -> (i64, bool)
{
    using scan;
    using strconv;

    saved: Scanner = scanner^;

    valueStr := consumeThrough(scanner, []rune{'-', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' }); // @Hack

    if value, ok := parse_i64(valueStr); ok
    {
        return value, true;
    }

    scanner^ = saved;
    return ---, false;
}

consumeWhitespace :: proc(scanner: ^scan.Scanner)
{
    using scan;
    
    isWhitespace :: proc(r: rune) -> bool
    {
        return r == '\t' || r == ' ' || r == '\n' || r == '\r';
    }

    for isWhitespace(peek(scanner))
    {
        next(scanner);
    }
}

consumeUntilWhitespace :: proc(scanner: ^scan.Scanner) -> string
{
    return consumeUntil(scanner, []rune{'\t', ' ', '\n', '\r' });
}

resetScanner :: proc(scanner: ^scan.Scanner)
{
    scan.init(scanner, scanner.src);
}
