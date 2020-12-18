package main

import "core:fmt"
import scan "core:text/scanner"

//
// Scanning
//

Token :: enum
{
    None,

    Eof,
    
    LParen,
    RParen,
    IntLiteral,
    Plus,
    Star,
}

peekToken :: proc(scanner: ^scan.Scanner) -> Token
{
    saved := scanner^;
    result := nextToken(scanner);
    scanner^ = saved;
    return result;
}

nextToken :: proc(scanner: ^scan.Scanner) -> Token
{
    consumeWhitespace(scanner);

    result : Token;

    needAdvanceScanner := true;
    
    switch scan.peek(scanner)
    {
        case '(': result = .LParen;
        case ')': result = .RParen;
        case '*': result = .Star;
        case '+': result = .Plus;
        case scan.EOF: result = .Eof;
        case '0'..'9':
        {
            result = .IntLiteral;
            needAdvanceScanner = false;
        }

        case: assert(false);
    }

    if needAdvanceScanner
    {
        scan.next(scanner);
    }

    return result;
}

o_tryConsumeTokenSet :: proc(scanner: ^scan.Scanner, match: []Token) -> (Token, bool)
{
    token := peekToken(scanner);
    for candidate in match
    {
        if token == candidate
        {
            nextToken(scanner);
            return token, true;
        }
    }

    return .None, false;
}

o_tryConsumeToken :: proc(scanner: ^scan.Scanner, match: Token) -> bool
{
    _, result := o_tryConsumeTokenSet(scanner, []Token{match});
    return result;
}

tryConsumeToken :: proc{ o_tryConsumeTokenSet, o_tryConsumeToken };



//
// AST
//

AstExpr :: union
{
    IntLitExpr,
    ^BinopExpr,
}

IntLitExpr :: int;

BinopExpr :: struct
{
    lhs : AstExpr,
    rhs : AstExpr,
    op : Token,
}



//
// Parsing
//

BinopRule :: struct
{
    precedence: int,
    ops: []Token
}

BinopRules :: []BinopRule;


parsePrimary :: proc(scanner: ^scan.Scanner, allOps: BinopRules) -> AstExpr
{
    result : AstExpr;
    token : Token = peekToken(scanner);

    #partial switch token
    {
        case .LParen:
        {
            lParen := nextToken(scanner);
            assert(lParen == .LParen);
            
            result = parseExpr(scanner, allOps);

            rParen := nextToken(scanner);
            assert(rParen == .RParen);
        }
        
        case .IntLiteral:
        {
            result = parseIntExpr(scanner);
        }

        case: assert(false);
    }

    return result;
}

parseBinopOrPrimary :: proc(scanner: ^scan.Scanner, ops: BinopRule, allOps: BinopRules) -> AstExpr
{
    oneStepHigher :: proc(scanner: ^scan.Scanner, ops: BinopRule, allOps: BinopRules) -> AstExpr
    {
        assert(ops.precedence >= 0);
        assert(ops.precedence < len(allOps));

        if (ops.precedence == len(allOps) - 1)
        {
            return parsePrimary(scanner, allOps);
        }
        else
        {
            return parseBinopOrPrimary(scanner, allOps[ops.precedence + 1], allOps);
        }
    }
    
    expr := oneStepHigher(scanner, ops, allOps);

    for
    {
        if op, ok := tryConsumeToken(scanner, ops.ops); ok
        {
            lhs := expr;
            rhs := oneStepHigher(scanner, ops, allOps);

            // HMM - Cleaner way to allocate/initialize a union pointer?
            expr = new(BinopExpr);
            expr_ := expr.(^BinopExpr);
            expr_^ = BinopExpr
            {
                lhs = lhs,
                rhs = rhs,
                op = op
            };
        }
        else
        {
            // NOTE - I find myself using this idiom a LOT. Maybe something to consider
            //  for Meek?
            
            break;
        }
    }

    return expr;
}

parseExpr :: proc(scanner: ^scan.Scanner, allOps: BinopRules) -> AstExpr
{
    assert(len(allOps) > 0);
    
    return parseBinopOrPrimary(scanner, allOps[0], allOps);
}

parseIntExpr :: proc(scanner: ^scan.Scanner) -> IntLitExpr
{
    value, ok := tryConsumeInt(scanner);
    assert(ok);

    return value;
}



//
// Interpreter
//

evalExpr :: proc(expr: AstExpr) -> int
{
    switch e in expr
    {
        case IntLitExpr:
        {
            return e;
        }

        case ^BinopExpr:
        {
            lhs := evalExpr(e.lhs);
            rhs := evalExpr(e.rhs);
            
            #partial switch e.op
            {
                case .Plus: return lhs + rhs;
                case .Star: return lhs * rhs;
                case: assert(false); return ---;
            }
        }

        case:
        {
            assert(false);
            return ---;
        }
    }
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    // Part 1
    
    sum1 := 0;
    rules1 := BinopRules
    {
        { 0, []Token { .Plus, .Star } }
    };
    
    for !isEof(&scanner)
    {
        
        expr := parseExpr(&scanner, rules1);
        sum1 += evalExpr(expr);

        consumeWhitespace(&scanner);
    }

    fmt.println("Part 1:", sum1);

    // Part 2

    resetScanner(&scanner);
    
    sum2 := 0;
    rules2 := BinopRules
    {
        { 0, []Token { .Star } },
        { 1, []Token { .Plus } }
    };
    
    for !isEof(&scanner)
    {
        
        expr := parseExpr(&scanner, rules2);
        sum2 += evalExpr(expr);

        consumeWhitespace(&scanner);
    }

    fmt.println("Part 2:", sum2);
}
