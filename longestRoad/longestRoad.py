import sys
import math

n = int(input())
board = []
players= []
for i in range(n):
    line = input()
    board.append(line)
    for j in line:
        if(not j == "#" and not j.upper() in players):
            players.append(j.upper())

for line in board:
    print(line, file=sys.stderr, flush=True)
print("", file=sys.stderr, flush=True)

def getTiles(i, j, path):
    this = board[i][j].lower()

    tiles = [(i+1, j), (i-1, j), (i, j+1), (i, j-1)]
    if(i == 0):
        tiles.remove((i-1, j))
    elif(i == n-1):
        tiles.remove((i+1, j))
    if(j == 0):
        tiles.remove((i, j-1))
    elif(j == n-1):
        tiles.remove((i, j+1))

    k = 0
    while(k < len(tiles)):
        tile = tiles[k]
        if(board[tile[0]][tile[1]] == "#"):
            tiles.remove(tile)
            k = 0
        elif( not (board[tile[0]][tile[1]] == this or board[tile[0]][tile[1]] == this.upper()) ):
            tiles.remove(tile)
            k = 0
        elif(tile in path):
            tiles.remove(tile)
            k = 0
        else:
            k += 1

    return tiles



def roadType(i, j, path):
    tiles = getTiles(i, j, path)
    return len(tiles)



def getRoad(start, end, path, p, maxL, longest):
    # print("", file=sys.stderr, flush=True)

    path.append(start)

    tiles = getTiles(start[0], start[1], path)
    # print("current position: " + str(start) + " " + str(path), file=sys.stderr, flush=True)
    # print("options: " + str(tiles), file=sys.stderr, flush=True)

    if(len(tiles) == 0):
        # print("  " + str((len(path), path)), file=sys.stderr, flush=True)
        if(path[len(path)-1] == end):
            return path
    else:
        for tile in tiles:

            newPath = []
            for k in path:
                newPath.append(k)
            newPath = getRoad(tile, end, newPath, p, maxL, longest)

            if(len(newPath) > maxL):
                maxL = len(newPath)
                longest = newPath

        path = longest
        return path

    return path






longestRoad = 0
winner = "#"

for player in players:
    # print("player: " + player, file=sys.stderr, flush=True)
    roadStarts = []
    loops = []
    for i in range(n):
        for j in range(n):

            # find all beginnings/ends of roads
            if(board[i][j] == player.lower() or board[i][j] == player.upper()):
                loops.append((i, j))
                rCount = roadType(i, j, [])
                if(rCount == 1):
                    roadStarts.append((i, j))

    # roadStarts = [(1, 4), (2, 3)]
    # print(roadStarts, file=sys.stderr, flush=True)

    if(len(roadStarts) > 1):
        for i in range(len(roadStarts)):
            start = roadStarts[i]
            for j in range(i, len(roadStarts)):
                end = roadStarts[j]
                if(not start == end):
                    # print("from " + str(start) + " to " + str(end), file=sys.stderr, flush=True)
                    l = getRoad(start, end, [], player.lower(), 0, [])
                    for point in l:
                        if(board[point[0]][point[1]] == player):
                            l.remove(point)
                    l = len(l)
                    if(l > longestRoad):
                        longestRoad = l
                        winner = player
    else:
        roadStarts = loops
        for i in range(len(roadStarts)):
            start = roadStarts[i]
            for j in range(i, len(roadStarts)):
                end = roadStarts[j]
                if(not start == end):
                    # print("from " + str(start) + " to " + str(end), file=sys.stderr, flush=True)
                    l = getRoad(start, end, [], player.lower(), 0, [])
                    for point in l:
                        if(board[point[0]][point[1]] == player):
                            l.remove(point)
                    l = len(l)
                    if(l > longestRoad):
                        longestRoad = l
                        winner = player


if(longestRoad >= 5):
    print(winner, longestRoad)
else:
    print(0)
