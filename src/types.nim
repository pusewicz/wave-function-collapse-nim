import hashes

type
  Direction* = enum
    Up, Right, Down, Left

  Tile* = ref object
    tileid*: int
    probability*: float
    up*: Hash
    down*: Hash
    left*: Hash
    right*: Hash

  Cell* = ref object
    cellid*: int
    x*, y*: int
    tiles*: seq[Tile]
    collapsed*: bool = false
    entropy*: int
    neighbors*: array[Direction, Cell]

  Model* = ref object
    tiles*: seq[Tile]
    width*, height*: int
    cells*: seq[Cell]
    uncollapsedCells*: seq[Cell]
    maxEntropy*: int
