package main

import "core:fmt"
import scan "core:text/scanner"

PHOTO_DIM :: 96;
Photo :: [PHOTO_DIM][PHOTO_DIM]bool;

rotatePhoto :: proc(photo: ^Photo)
{
    src := photo^;

    // Clockwise
    for iRowDst in 0..<PHOTO_DIM
    {
        iColSrc := iRowDst;
        
        for iColDst in 0..<PHOTO_DIM
        {
            iRowSrc := PHOTO_DIM - 1 - iColDst;
            photo[iRowDst][iColDst] = src[iRowSrc][iColSrc];
        }
    }
}

flipPhoto :: proc(photo: ^Photo)
{
    src := photo^;

    // Horizontal
    for iRowDst in 0..<PHOTO_DIM
    {
        iRowSrc := iRowDst;
        
        for iColDst in 0..<PHOTO_DIM
        {
            iColSrc := PHOTO_DIM - 1 - iColDst;
            photo[iRowDst][iColDst] = src[iRowSrc][iColSrc];
        }
    }
}

countSeamonsters :: proc(photo: ^Photo) -> int
{
    result := 0;

    // Look at the range that is valid for the leftmost part of the tail

    ROW_LOOK_BEHIND_REQUIRED :: 1;
    ROW_LOOK_AHEAD_REQUIRED :: 1;
    COL_LOOK_BEHIND_REQUIRED :: 0;
    COL_LOOK_AHEAD_REQUIRED :: 19;
    
    for iRow in ROW_LOOK_BEHIND_REQUIRED ..< (PHOTO_DIM - ROW_LOOK_AHEAD_REQUIRED)
    {
        for iCol in COL_LOOK_BEHIND_REQUIRED..< (PHOTO_DIM - COL_LOOK_AHEAD_REQUIRED)
        {
            //                   # 
            // #    ##    ##    ###
            //  #  #  #  #  #  #
            //
            //                   M
            // A    DE    HI    LNO
            //  B  C  F  G  J  K
            
            if  photo[iRow + 0][iCol + 00] && // A
                photo[iRow + 1][iCol + 01] && // B
                photo[iRow + 1][iCol + 04] && // C
                photo[iRow + 0][iCol + 05] && // D
                photo[iRow + 0][iCol + 06] && // E
                photo[iRow + 1][iCol + 07] && // F
                photo[iRow + 1][iCol + 10] && // G
                photo[iRow + 0][iCol + 11] && // H
                photo[iRow + 0][iCol + 12] && // I
                photo[iRow + 1][iCol + 13] && // J
                photo[iRow + 1][iCol + 16] && // K
                photo[iRow + 0][iCol + 17] && // L
                photo[iRow - 1][iCol + 18] && // M
                photo[iRow + 0][iCol + 18] && // N
                photo[iRow + 0][iCol + 19]    // O
            {
                result += 1;
            }
        }
    }

    return result;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    photo: Photo;

    cntFilledCell := 0;

    for iRow in 0..<PHOTO_DIM
    {
        for iCol in 0..<PHOTO_DIM
        {
            c := scan.next(&scanner);

            switch c
            {
                case '#': photo[iRow][iCol] = true; cntFilledCell += 1;
                case '.': ; // Nop
                case: assert(false);
            }
        }

        consumeWhitespace(&scanner);
    }

    consumeWhitespace(&scanner);
    assert(isEof(&scanner));

    // NOTE - Assumes no seamonsters share cells. Seems to be a safe assumption from the example.

    cntSeamonster := 0;

    LOuter:
    for _ in 1..2
    {
        for _ in 1..4
        {
            cntSeamonster = countSeamonsters(&photo);
            if cntSeamonster > 0
            {
                break LOuter;
            }

            rotatePhoto(&photo);
        }

        flipPhoto(&photo);
    }
    
    assert(cntSeamonster > 0);
    
    FILLED_CELLS_PER_SEAMONSTER :: 15;
    fmt.println("Part 2:", cntFilledCell - (cntSeamonster * FILLED_CELLS_PER_SEAMONSTER));
}
