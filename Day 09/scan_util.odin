package main

import scannerPkg "core:text/scanner"

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
