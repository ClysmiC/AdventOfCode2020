package main

import scannerPkg "core:text/scanner"
import "core:strconv"

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
        char_ : rune = peek(scanner);
        if char_ == EOF
        {
            break;
        }

        delimiterFound := false;
        for delimiter in untilSet
        {
            if char_ == delimiter
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

consumeThrough :: proc(scanner : ^scannerPkg.Scanner, throughSet : []rune) -> string
{
    using scannerPkg;
    
    start : int = position(scanner).offset;
    len : int;
    
    for
    {
        char_ : rune = peek(scanner);
        if char_ == EOF
        {
            break;
        }

        matchFound := false;
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

makeIntArray :: proc(scanner : ^scannerPkg.Scanner) -> [dynamic]int
{
    result : [dynamic]int;
    
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

tryConsumeInt :: proc(scanner : ^scannerPkg.Scanner) -> (int, bool)
{
    using scannerPkg;
    using strconv;

    saved : Scanner = scanner^;

    consumeWhitespace(scanner); // @Hack
    valueStr := consumeThrough(scanner, []rune{'-', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' }); // @Hack

    if value, ok := parse_int(valueStr); ok
    {
        return value, true;
    }

    scanner^ = saved;
    return ---, false;
}

consumeWhitespace :: proc(scanner : ^scannerPkg.Scanner)
{
    using scannerPkg;
    
    isWhitespace :: proc(r : rune) -> bool
    {
        return r == '\t' || r == ' ' || r == '\n' || r == '\r';
    }

    for isWhitespace(peek(scanner))
    {
        next(scanner);
    }
}

consumeUntilWhitespace :: proc(scanner : ^scannerPkg.Scanner) -> string
{
    return consumeUntil(scanner, []rune{'\t', ' ', '\n', '\r' });
}

resetScanner :: proc(scanner : ^scannerPkg.Scanner)
{
    scannerPkg.init(scanner, scanner.src);
}
