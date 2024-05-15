import std/[random, sequtils], hashes

type
  Direction* = enum
    Up, Right, Down, Left

  Tile* = ref object
    tileid: int
    probability*: float
    edges*: array[Direction, Hash]

  Cell* = ref object
    cellid*: int
    x, y: int
    tiles: seq[Tile]
    collapsed: bool = false
    entropy: int
    neighbors*: array[Direction, Cell]

  Model* = ref object
    tiles*: seq[Tile]
    width*, height*: int
    cells: seq[Cell]
    uncollapsedCells*: seq[Cell]
    maxEntropy*: int

  Grid* = seq[seq[Tile]]

  WangId = array[0..7, int]

proc new*(_: typedesc[Tile], tileid: int, probability: float,
    wangid: WangId): Tile =
  var edges: array[Direction, Hash]
  edges[Up] = hashes.hash([wangid[7], wangid[0], wangid[1]])
  edges[Right] = hashes.hash([wangid[1], wangid[2], wangid[3]])
  edges[Down] = hashes.hash([wangid[5], wangid[4], wangid[3]])
  edges[Left] = hashes.hash([wangid[7], wangid[6], wangid[5]])
  result = Tile(tileid: tileid, probability: probability, edges: edges)

proc new(_: typedesc[Cell], x: int, y: int, tiles: sink seq[Tile]): Cell =
  var cellId {.global.}: int
  result = Cell(x: x, y: y, tiles: tiles, cellId: cellId)
  inc cellId

proc new*(_: typedesc[Model], width: int, height: int, tiles: sink seq[Tile]): Model =
  result = Model(width: width, height: height, tiles: tiles)
  for y in 0 ..< height:
    for x in 0 ..< width:
      let cell = Cell(x: x, y: y, tiles: tiles)
      result.cells.add(cell)

  # TODO: Below should be a copy of the cells array
  result.uncollapsedCells = result.cells # TODO: Reject already collapsed
  result.maxEntropy = tiles.len # TODO: Calculate max entropy based on cells' tiles

proc update(self: Cell): void =
  assert self.tiles.len > 0
  self.entropy = self.tiles.len
  self.collapsed = self.entropy == 1

proc setTiles*(self: Cell, tiles: seq[Tile]): void =
  self.tiles = tiles
  self.update()

proc getTile*(self: Cell): Tile = self.tiles[0]

proc collapse(self: Cell): void =
  # TODO: Get the random tile by probability and verify the code
  var
    tile: Tile
    total = 0.0
  for i, t in self.tiles:
    total += t.probability
  var random = rand(total)
  for i, t in self.tiles:
    random -= t.probability
    if random <= 0:
      tile = t
      break
  self.tiles = @[tile]
  self.update()

proc cellAt*(self: Model, x, y: int): Cell =
  result = self.cells[x + y * self.width]

  assert result.x == x
  assert result.y == y

proc neighborsFor(self: Cell, model: Model): Cell.neighbors =
  if self.y > 0:
    self.neighbors[Up] = model.cellAt(self.x, self.y - 1)

  if self.x < model.width - 1:
    self.neighbors[Right] = model.cellAt(self.x + 1, self.y)

  if self.y < model.height - 1:
    self.neighbors[Down] = model.cellAt(self.x, self.y + 1)

  if self.x > 0:
    self.neighbors[Left] = model.cellAt(self.x - 1, self.y)

  self.neighbors

proc complete*(self: Model): bool = self.uncollapsedCells.len == 0

proc percent*(self: Model): float = 1.0 - float(self.uncollapsedCells.len) /
    float(self.cells.len)

proc randomCell(cells: Model.uncollapsedCells): Cell =
  let index = rand(cells.len)
  cells[index]

proc propagate(self: Model, cell: Cell): void # Forward declaration
proc evaluateNeighbor(self: Model, sourceCell: Cell, direction: Direction): void

proc propagate(self: Model, cell: Cell): void =
  self.evaluateNeighbor(cell, Direction.Up)
  self.evaluateNeighbor(cell, Direction.Right)
  self.evaluateNeighbor(cell, Direction.Down)
  self.evaluateNeighbor(cell, Direction.Left)

proc evaluateNeighbor(self: Model, sourceCell: Cell,
    direction: Direction): void =
  var neighbors = sourceCell.neighborsFor(self)
  var neighbor = neighbors[direction]
  if neighbor == nil or neighbor.collapsed:
    return

  let originalTileCount = neighbor.tiles.len
  let oppositeDirection = case direction
    of Direction.Up: Direction.Down
    of Direction.Right: Direction.Left
    of Direction.Down: Direction.Up
    of Direction.Left: Direction.Right
  let neighborTiles = neighbor.tiles

  let sourceTileEdges = sourceCell.tiles.mapIt(it.edges[direction])

  var newTiles: seq[Tile]
  let ntl = neighbor.tiles.len
  for i in 0 ..< ntl:
    let tile = neighborTiles[i]
    if sourceTileEdges.contains(tile.edges[oppositeDirection]):
      newTiles.add(tile)

  if newTiles.len > 0:
    neighbor.setTiles(newTiles)

  if neighbor.collapsed:
    let index = self.uncollapsedCells.find(neighbor)
    assert index != -1
    self.uncollapsedCells.del(index)

  if neighbor.tiles.len != originalTileCount:
    self.propagate(neighbor)

proc processCell*(self: Model, cell: Cell): void =
  cell.collapse()
  assert cell.collapsed

  let index = self.uncollapsedCells.find(cell)
  self.uncollapsedCells.del(index)

  if self.uncollapsedCells.len == 0:
    return

  self.propagate(cell)

# Finds cells with lowest entropy and returns a random one
proc findLowestEntropy(cells: seq[Cell]): Cell =
  var lowestEntropy = cells[0].entropy
  var lowestEntropyCells: seq[Cell] = @[cells[0]]
  for i in 1 ..< cells.len:
    let cell = cells[i]
    if cell.entropy < lowestEntropy:
      lowestEntropy = cell.entropy
      lowestEntropyCells = @[cell]
    elif cell.entropy == lowestEntropy:
      lowestEntropyCells.add(cell)

  let index = rand(lowestEntropyCells.len)
  lowestEntropyCells[index]

proc generateGrid*(self: Model): Grid =
  result = newSeq[seq[Tile]](self.width)

  for x in 0 ..< self.width:
    result[x] = newSeq[Tile](self.height)
    for y in 0 ..< self.height:
      let cell = self.cellAt(x, y)
      result[x][y] = cell.getTile()

proc iterate*(self: Model): Cell =
  if self.complete():
    return nil

  let cell = findLowestEntropy(self.uncollapsedCells)
  if cell == nil:
    return nil

  self.processCell(cell)
  cell

proc solve*(self: Model): Cell = # TODO: Can this be an array?
  let cell = randomCell(self.uncollapsedCells)
  self.processCell(cell)
  cell
