package main

import "core:fmt"
import scan "core:text/scanner"

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));
}
