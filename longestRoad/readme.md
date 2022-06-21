# Longest Road Puzzle

This contains the code for the Longest Road puzzle contributed to Codingame.com, [view here](https://www.codingame.com/training/medium/longest-road). The python code used to generate solution for the test cases is a simple depth first search (DFS) algorithm that looks at the ascii values of the *game board* around the current position. It is an application of the classic NP-hard problem, but the test cases were designed to be simple enough for a basic DFS algorithm to solve within a few seconds.

## Description

Determine which player in a rectangular "Settlers of Catan" themed game board has the longest road.

Given an ascii game board:
```
aa##b
#A##B
#aa#b
##a##
```

The lower case letters "a" denote a road belonging to player A.
Uppercase letters denote a settlement.

If a player has at least 5 consecutive (non-repeating) roads then they can be awarded the "longest road" victory points.
Roads connected diagonally are not considered consecutive. Roads can be linked together by settlements, but the settlements do not count towards the total length of the player's roads. In the above example player A would have the longest road with a length of 5.

The input will never include the case where multiple players are tied for longest road.

Loops and branches
A road may form a loop or branch out in multiple directions. In all cases the longest possible consecutive link of roads is used to determine the players' longest roads.

Inspired by the board game "Settlers of Catan" by Klaus Teuber.

## Test Cases

Input:
```
5
#a###
#a###
#a###
#aa##
##a##
```

Output:
`A 6`

Input:
```
Bb###cC###
b#Aa#c####
###a#c####
###aaAaaa#
#####c####
#####cCccc
######d###
#dBbb#D###
#d####d###
#D####d###
```

Output:
`A 7`
