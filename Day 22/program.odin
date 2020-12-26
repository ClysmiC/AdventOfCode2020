package main

import "core:fmt"
import scan "core:text/scanner"

Card :: struct
{
    value: int,
    next: ^Card,
    prev: ^Card,
}

Deck :: struct
{
    top: ^Card,
    bottom: ^Card,
    count: int,
}

is_empty :: proc(deck: Deck) -> bool
{
    return deck.count == 0;
}

draw_top_card :: proc(deck: ^Deck) -> ^Card
{
    if is_empty(deck^)
    {
        return nil;
    }

    result := deck.top;
    deck.top = deck.top.next;
    deck.count -= 1;

    if is_empty(deck^)
    {
        assert(deck.top == nil);
        deck.bottom = nil;
    }
    else
    {
        deck.top.prev = nil;
    }

    result.next = nil;
    result.prev = nil;

    return result;
}

add_card_to_bottom :: proc(deck: ^Deck, card: ^Card)
{
    assert(card.next == nil);
    assert(card.prev == nil);
    
    if is_empty(deck^)
    {
        deck.top = card;
        deck.bottom = card;
    }
    else
    {
        card.prev = deck.bottom;
        deck.bottom.next = card;
        deck.bottom = card;
    }

    deck.count += 1;
}

main :: proc()
{
    scanner : scan.Scanner;
    scan.init(&scanner, string(#load("input.txt")));

    STORAGE_SIZE :: 512;
    
    cardStorage1: [STORAGE_SIZE]Card;
    cardStorage2: [STORAGE_SIZE]Card;
    
    // 1 and 2: part 1 vs part 2
    // A and B: player A vs player B
    
    deck1A: Deck;
    deck1B: Deck;
    deck2A: Deck;
    deck2B: Deck;

    //
    // Read in input
    
    {
        cntStoredCards := 0;

        deck1 := &deck1A;
        deck2 := &deck2A;
        
        for player in 'A'..'B'
        {
            consumePast(&scanner, ':');
            consumeWhitespace(&scanner);

            for
            {
                cardValue, ok := tryConsumeInt(&scanner);
                if !ok
                {
                    break;
                }
                
                ok = tryConsume(&scanner, "\r\n");
                assert(ok);

                card1 := &cardStorage1[cntStoredCards];
                card2 := &cardStorage2[cntStoredCards];
                cntStoredCards += 1;
                assert(cntStoredCards < STORAGE_SIZE);

                card1.value = cardValue;
                card2.value = cardValue;
                
                add_card_to_bottom(deck1, card1);
                add_card_to_bottom(deck2, card2);
            }
            
            deck1 = &deck1B;
            deck2 = &deck2B;
        }
    }

    //
    // Part 1
    
    {
        for !is_empty(deck1A) && !is_empty(deck1B)
        {
            cardA := draw_top_card(&deck1A);
            cardB := draw_top_card(&deck1B);

            if cardA.value > cardB.value
            {
                add_card_to_bottom(&deck1A, cardA);
                add_card_to_bottom(&deck1A, cardB);
            }
            else
            {
                assert(cardA.value < cardB.value);
                add_card_to_bottom(&deck1B, cardB);
                add_card_to_bottom(&deck1B, cardA);
            }
        }

        winner := &deck1A;
        if is_empty(winner^)
        {
            winner = &deck1B;
        }

        assert(!is_empty(winner^));

        score := 0;
        cardToScore := winner.bottom;
        k := 1;

        for cardToScore != nil
        {
            score += k * cardToScore.value;
            cardToScore = cardToScore.prev;
            k += 1;
        }

        assert(k == (winner.count + 1));
        fmt.println("Part 1:", score);
    }

    //
    // Part 2

    {
    }
}
