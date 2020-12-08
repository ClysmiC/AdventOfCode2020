package main

import "core:fmt"
import "core:strconv"
import scannerPkg "core:text/scanner"
import "core:strings"

//
// Scanning / util
//

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

//
// Puzzle
//

Op :: enum
{
    nop,
    acc,
    jmp,
}

Instruction :: struct
{
    op : Op,
    arg : int,
}

ProgramState :: struct
{
    acc : int,
    ip : int,
    
    instructions : [dynamic]Instruction,
}

tryParseOp :: proc(scanner : ^scannerPkg.Scanner) -> (Op, bool)
{
    using scannerPkg;
    
    saved : Scanner = scanner^;
    opStr := consumeUntilWhitespace(scanner);

    switch opStr
    {
        case "acc": return .acc, true;
        case "jmp": return .jmp, true;
        case "nop": return .nop, true;
        case:
        {
            scanner^ = saved;
            return ---, false;
        }
    }
}

tryParseArg :: proc(scanner : ^scannerPkg.Scanner) -> (int, bool)
{
    using scannerPkg;
    using strconv;
    
    saved : Scanner = scanner^;

    argStr := consumeUntilWhitespace(scanner);
    if result, ok := parse_int(argStr); ok
    {
        return result, true;
    }

    scanner^ = saved;
    return ---, false;
}

tryParseInstruction :: proc(scanner : ^scannerPkg.Scanner) -> (Instruction, bool)
{
    using scannerPkg;

    saved : Scanner = scanner^;

    consumeWhitespace(scanner);
    
    if op, ok := tryParseOp(scanner); ok
    {
        consumeWhitespace(scanner);
        
        if arg, ok := tryParseArg(scanner); ok
        {
            consumeWhitespace(scanner);

            instruction := Instruction
            {
                op = op,
                arg = arg,
            };

            return instruction, true;
        }
    }

    scanner^ = saved;
    return ---, false;
}

buildProgram :: proc(scanner : ^scannerPkg.Scanner) -> ProgramState
{
    state : ProgramState;
    instruction : Instruction;

    for !isEof(scanner)
    {
        instruction, ok := tryParseInstruction(scanner);
        assert(ok);
        append(&state.instructions, instruction);
    }

    return state;
}

ExitCode :: enum
{
    Ok,
    Error_IpOutOfBounds,
    Error_InfiniteLoop,
    Error_UnknownInstruction
}

executeProgram :: proc(using program : ^ProgramState) -> ExitCode
{
    hasInstructionExecuted := make([]bool, len(instructions));
    defer delete(hasInstructionExecuted);
    
    for
    {
        if ip < 0 || ip > len(instructions)
        {
            return .Error_IpOutOfBounds;
        }
        else if ip == len(instructions)
        {
            // Normal termination

            return .Ok;
        }
        else if hasInstructionExecuted[ip]
        {
            return .Error_InfiniteLoop;
        }
        
        hasInstructionExecuted[ip] = true;
        
        instruction := &instructions[ip];
        op := instruction.op;
        arg := instruction.arg;

        incrementIp := true;
        
        switch op
        {
            case .nop:
            {
            }

            case .jmp:
            {
                ip += arg;
                incrementIp = false;
            }

            case .acc:
            {
                acc += arg;
            }

            case:
            {
                return .Error_UnknownInstruction;
            }
        }

        if incrementIp
        {
            ip += 1;
        }
    }
}

main :: proc()
{
    scanner : scannerPkg.Scanner;
    scannerPkg.init(&scanner, string(#load("input.txt")));

    program := buildProgram(&scanner); // @Leak

    // Part 1
    
    exitCode := executeProgram(&program);
    assert(exitCode == .Error_InfiniteLoop);
    
    fmt.println("Part 1:", program.acc);

    // Part 2

    for iOp in 0..<len(program.instructions)
    {
        originalOp := program.instructions[iOp].op;

        // Mutate instruction
        
        if originalOp == .nop
        {
            program.instructions[iOp].op = .jmp;
        }
        else if originalOp == .jmp
        {
            program.instructions[iOp].op = .nop;
        }
        else
        {
            continue;
        }

        // Reset program state

        program.acc = 0;
        program.ip = 0;

        // Run program
        
        exitCode := executeProgram(&program);
        if exitCode == .Ok
        {
            fmt.println("Part 2:", program.acc);
            break;
        }

        // Revert mutation

        program.instructions[iOp].op = originalOp;
    }
}
