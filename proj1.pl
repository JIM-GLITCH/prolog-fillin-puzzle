/*
Author:
ID:
Purpose:This project is designed to solve fill-in puzzles.

The puzzle consists of a grid of squares, most of which are empty,
into which letters or digits are to be written, but some of which
are filled in solid, and are not to be written in. First we find 
all the Slots.Then each step we select a slot with the most number 
of ground terms to unify with a word in a wordList Until all Slots
are instantiated.
*/
:-use_module(library(clpfd)).

/*
puzzle_solution(+Puzzle,+WordList).
*/
puzzle_solution(Puzzle,WordList):-
    getSlots(Puzzle,Slots),
    selectWords(Slots, WordList).

/*
selectWords(+Slots,+WordList)
Following hint 6, we need to do fast failure to avoid too much 
search space. At each step of selectWords/2, the slot with most 
ground elements is selected to instantiate to achieve fast failure.
*/
selectWords(_,[]).
selectWords(Slots,WordList):-
    sortByNumOfGroundTerms(Slots,[Slot|RestSlots]),
    select(Slot,WordList,RestWordList),
    selectWords(RestSlots,RestWordList).

/*
sortByKeyFunc(+KeyFunc,+Ls,-SortedLs)
Calculate the key of each element according to the keyfunc,
and then sort the elements according to the key
*/
sortByKeyFunc(KeyFunc,Ls,SortedLs):-
    maplist(addKey(KeyFunc),Ls,KeyLs),
    keysort(KeyLs,SortedKeyLs),
    maplist(delKey,SortedKeyLs,SortedLs).

/*
addKey(+,-)
Convert element to key-element form
delKey(+,-)
Convert key-element to element form
*/
addKey(Func,V,K-V):-
    call(Func,V,K).
delKey(_-V,V).


/*
countGround(+Slot,-Int)
Count how many ground elements are in a slot
*/
countGround([],0).
countGround([H|T],Count):-
    countGround(T,Count1),
    (
        ground(H)
    ->  Count is Count1+1
    ;   Count = Count1
    ).

/*
sortByNumOfGroundTerms(+L,-SortedL)
Sort by the number of groud terms in the slot
from smallest to largest
*/
sortByNumOfGroundTerms(L1,L2):-
    sortByKeyFunc(countGround,L1,L3),
    reverse(L3,L2).

/*
getSlots(+Puzzle,-Slots)
Get all the slots in the puzzle, 
both horizontal and vertical
*/
getSlots(Puzzle,Slots):-
    getHorizontalSlots(Puzzle,Slots1),
    transpose(Puzzle, Puzzle2),
    getHorizontalSlots(Puzzle2,Slots2),
    append(Slots1,Slots2,Slots).
/*
getHorizontalSlots(+Puzzle,-Slots)
Get all the horizontal slots in the puzzle
*/
getHorizontalSlots(Puzzle,Slots):-
    maplist(getSlotsOfOneLine,Puzzle,ListOfSlots),
    append(ListOfSlots, Slots).
/*
getSlotsOfOneLine(+Line,-Slots),
Get all slots in the line
*/
getSlotsOfOneLine(Line,Slots):-
    slots(Slots,Line,[]).


/*******************************************************
    Use DCG parse one line of puzzle and get slots
********************************************************/

/*A grid that is not sloid*/
grid(C)-->[C],{C\=='#'}.

/*Zero or more grids, greedy*/
grids([H|T])-->grid(H),grids(T).
grids([])-->{true}.

/*A sloid is the square whose char is '#'*/
solid-->[C],{C=='#'}.

/*Zero or more sloid, greedy*/
solids --> solid,solids.
solids --> [].

/*A valid slot must contain at least two grids */
slot([H1,H2|T])-->
    grid(H1),
    grid(H2),
    grids(T).

/*We define SlotBock as a slot and maybe some solids.*/
slotBlock(Slot)-->
    slot(Slot),
    solids.

/*We don't collect one grid slot*/
skipOneGridSlotBlock-->
    grid(_),
    solids.

/*slotBlocks collects slots that contains at least two grid*/
slotBlocks([H|T])-->
    slotBlock(H),
    slotBlocks(T).
slotBlocks(L)-->
    skipOneGridSlotBlock,
    slotBlocks(L).
slotBlocks([])-->[].


/*Collect slots of the line*/
slots(Slots)-->solids,slotBlocks(Slots),!.
