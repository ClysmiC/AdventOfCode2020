// Author's note
//  Trying to compile in debug mode seems to crash the compiler. But doing "odin run" runs the program just fine.

package main

import "core:fmt"
import "core:strings"
import "core:sort"
import scan "core:text/scanner"

Ingredient :: distinct int;
Allergen :: distinct int;

ensureMapping :: proc(map_: ^map[string]$T, key: string) -> (T, bool)
{
    if key in map_^
    {
        return map_[key], false;
    }

    result := len(map_);
    map_[key] = auto_cast result;
    return auto_cast result, true;
}

getReverseMapping :: proc(map_: ^map[$K]$V, value: V) -> K
{
    for k, v in map_
    {
        if v == value
        {
            return k;
        }
    }

    assert(false);
    return ---;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));
    
    strToIngredient: map[string]Ingredient;
    strToAllergen: map[string]Allergen;

    ingredientToCnt: map[Ingredient]int;

    allergensSortedByName: [dynamic]Allergen;
    allergenToCandidateIngredients: map[Allergen](map[Ingredient]bool);

    //
    // Parse input

    for !isEof(&scanner)
    {
        ingredients: [dynamic]Ingredient;
        allergens: [dynamic]Allergen;

        defer delete(ingredients);
        defer delete(allergens);

        // Read ingredients
        for
        {
            str := consumeUntil(&scanner, ' ');
            ingredient, _ := ensureMapping(&strToIngredient, str);
            
            append(&ingredients, ingredient);
            ingredientToCnt[ingredient] += 1;
            
            ok := tryConsume(&scanner, " ");
            assert(ok);
            
            if scan.peek(&scanner) == '('
            {
                break;
            }
        }

        // Read allergens
        ok := tryConsume(&scanner, "(contains ");
        assert(ok);

        for
        {
            str := consumeUntil(&scanner, []rune{ ',', ')'});
            allergen, addedMapping := ensureMapping(&strToAllergen, str);
            
            append(&allergens, allergen);
            if addedMapping
            {
                append(&allergensSortedByName, allergen); // NOTE - Sorted later
            }

            next := scan.next(&scanner);
            consumeWhitespace(&scanner);

            if next == ')'
            {
                break;
            }
        }

        for allergen in allergens
        {
            if allergen in allergenToCandidateIngredients
            {
                existingCandidates := &allergenToCandidateIngredients[allergen];
                test := len(existingCandidates);

                candidatesToDelete: [dynamic]Ingredient;
                defer delete(candidatesToDelete);
                
                for existingCandidate, _ in existingCandidates
                {
                    found := false;
                    for newCandidate in ingredients
                    {
                        if newCandidate == existingCandidate
                        {
                            found = true;
                            break;
                        }
                    }

                    if !found
                    {
                        append(&candidatesToDelete, existingCandidate);
                    }
                }

                for candidate in candidatesToDelete
                {
                    delete_key(existingCandidates, candidate);
                }
            }
            else
            {
                allergenToCandidateIngredients[allergen] = make(map[Ingredient]bool);
                candidates := &allergenToCandidateIngredients[allergen];
                
                for ingredient in ingredients
                {
                    candidates[ingredient] = true;
                }
            }
        }
    }

    //
    // Sort allergens by name
    
    SortCtx :: struct
    {
        strToAllergen: ^map[string]Allergen,
        allergens: ^[dynamic]Allergen,
    };

    ctx := SortCtx { &strToAllergen, &allergensSortedByName };
    sort.sort(sort.Interface{
        
        collection = rawptr(&ctx),
        
        len = proc(it: sort.Interface) -> int
        {
            ctx := (^SortCtx)(it.collection);
            return len(ctx.allergens);
        },
        
        less = proc(it: sort.Interface, i0: int, i1: int) -> bool
        {
            ctx := (^SortCtx)(it.collection);
            allergen0 := ctx.allergens[i0];
            allergen1 := ctx.allergens[i1];
            return cmpAllergen(ctx.strToAllergen, allergen0, allergen1) < 0;

            //---
            cmpAllergen :: proc(strToAllergen: ^map[string]Allergen, allergen0: Allergen, allergen1: Allergen) -> int
            {
                str0 := getReverseMapping(strToAllergen, allergen0);
                str1 := getReverseMapping(strToAllergen, allergen1);

                return strings.compare(str0, str1);
            }
        },
        
        swap = proc(it: sort.Interface, i0: int, i1: int)
        {
            ctx := (^SortCtx)(it.collection);
            ctx.allergens[i0], ctx.allergens[i1] = ctx.allergens[i1], ctx.allergens[i0];
        },
    });

    //
    // Deduce which allergen maps to which ingredient
    
    allergenToSolvedIngredient: map[Allergen]Ingredient;
    
    newInfo := true;
    for newInfo
    {
        newInfo = false;

        allergensToDelete: [dynamic]Allergen;
        defer delete(allergensToDelete);
        
        for allergen, candidates in allergenToCandidateIngredients
        {
            if len(candidates) == 1
            {
                ingredient: Ingredient;
                
                for ingredient_, isCandidate in candidates
                {
                    assert(isCandidate);
                    
                    ingredient = ingredient_;
                    allergenToSolvedIngredient[allergen] = ingredient;

                    append(&allergensToDelete, allergen);
                }

                for allergenOther, candidates in allergenToCandidateIngredients
                {
                    if allergen == allergenOther
                    {
                        continue;
                    }

                    if ingredient in allergenToCandidateIngredients[allergenOther]
                    {
                        delete_key(&allergenToCandidateIngredients[allergenOther], ingredient);
                    }
                }

                newInfo = true;
            }
        }

        for allergen in allergensToDelete
        {
            delete_key(&allergenToCandidateIngredients, allergen);
        }
    }

    part1 := 0;
    
    for _, ingredient in strToIngredient
    {
        found := false;
        for _, allergen in strToAllergen
        {
            if allergenToSolvedIngredient[allergen] == ingredient
            {
                found = true;
                break;
            }
        }

        if !found
        {
            part1 += ingredientToCnt[ingredient];
        }
    }

    fmt.println("Part 1:", part1);

    fmt.print("Part 2: ");
    
    leadingComma := false;
    for allergen in allergensSortedByName
    {
        ingredient := allergenToSolvedIngredient[allergen];
        ingredientStr := getReverseMapping(&strToIngredient, ingredient);

        if leadingComma
        {
            fmt.print(",");
        }
        
        fmt.print(ingredientStr);

        leadingComma = true;
    }
}
