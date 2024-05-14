import std/random, hashes

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

proc new*(_: typedesc[Tile], tileid: int, probability: float, wangid: array[
    0..8, int]): Tile =
  const up = hashes.hash([wangid[7], wangid[0], wangid[1]])
  const right = hashes.hash([wangid[1], wangid[2], wangid[3]])
  const down = hashes.hash([wangid[5], wangid[4], wangid[3]])
  const left = hashes.hash([wangid[7], wangid[6], wangid[5]])
  result = Tile(tileid: tileid, probability: probability, up: up, right: right,
      down: down, left: left)

proc new*(_: typedesc[Model], width: int, height: int, tiles: sink seq[Tile]): Model =
  result = Model(width: width, height: height, tiles: tiles)
  # Iterate 0 to width
  for x in 0 ..< width:
    # Iterate 0 to height
    for y in 0 ..< height:
      # Create a new cell
      let c = Cell(x: x, y: y, tiles: tiles)
      # Add the cell to the cells array
      result.cells.add(c)

  # TODO: Below should be a copy of the cells array
  result.uncollapsedCells = result.cells # TODO: Reject already collapsed
  result.maxEntropy = tiles.len # TODO: Calculate max entropy based on cells' tiles

proc new*(_: typedesc[Cell], x: int, y: int, tiles: sink seq[Tile]): Cell =
  var cellId {.global.}: int
  result = Cell(x: x, y: y, tiles: tiles, cellId: cellId)
  inc cellId

proc update(self: Cell): void =
  self.entropy = self.tiles.len
  self.collapsed = self.entropy == 1

proc setTiles*(self: Cell, tiles: seq[Tile]): Cell =
  self.tiles = tiles
  self.update()
  self

proc getTile*(self: Cell): Tile = self.tiles[0]

proc collapse*(self: Cell): void =
  # TODO: Get the random tile by probability and verify the code
  var tile: Tile
  var total = 0.0
  for t in self.tiles:
    total += t.probability
  var random = rand(total)
  for t in self.tiles:
    random -= t.probability
    if random <= 0:
      tile = t
      break
  self.tiles = @[tile]
  self.update()

proc cellAt*(self: Model, x, y: int): Cell = self.cells[x + y * self.width]

proc neighborsFor*(self: Cell, model: Model): Cell.neighbors =
  if self.y < model.height - 1:
    self.neighbors[Up] = model.cellAt(self.x, self.y + 1)

  if self.x < model.width - 1:
    self.neighbors[Right] = model.cellAt(self.x + 1, self.y)

  if self.y > 0:
    self.neighbors[Down] = model.cellAt(self.x, self.y - 1)

  if self.x > 0:
    self.neighbors[Left] = model.cellAt(self.x - 1, self.y)

  self.neighbors


proc `complete?`*(self: Model): bool = self.uncollapsedCells.len == 0

proc percent*(self: Model): float = 1.0 - float(self.uncollapsedCells.len) /
    float(self.cells.len)

proc randomCell(cells: Model.uncollapsedCells): Cell =
  let index = rand(cells.len)
  cells[index]

proc evaluateNeighbor(self: Model, cell: Cell, direction: Direction): void =
  var neighbors = cell.neighborsFor(self)
  var neighbor = neighbors[direction]
  if neighbor == nil:
    return
  # TODO: Implement

proc propagate(self: Model, cell: Cell): void =
  self.evaluateNeighbor(cell, Direction.Up)
  self.evaluateNeighbor(cell, Direction.Right)
  self.evaluateNeighbor(cell, Direction.Down)
  self.evaluateNeighbor(cell, Direction.Left)

proc processCell*(self: Model, cell: Cell): void =
  cell.collapse()
  let index = self.uncollapsedCells.find(cell)
  self.uncollapsedCells.del(index)

  if self.uncollapsedCells.len == 0:
    return

  self.propagate(cell)

proc solve*(self: Model): seq[Tile] = # TODO: Can this be an array?
  let cell = randomCell(self.uncollapsedCells)
  self.processCell(cell)
  # self.generateGrid()
