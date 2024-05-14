import std/random
import types, cell

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

proc cellAt*(self: Model, x, y: int): Cell = self.cells[x + y * self.width]

proc `complete?`*(self: Model): bool = self.uncollapsedCells.len == 0

proc percent*(self: Model): float = 1.0 - float(self.uncollapsedCells.len) /
    float(self.cells.len)

proc randomCell(cells: Model.uncollapsedCells): Cell =
  let index = rand(cells.len)
  cells[index]

proc evaluateNeighbor(self: Model, cell: Cell, direction: Direction): void =
  var neighbors = cell.neighbors(self)
  var neighbor = neighbors[direction]
  if neighbor == nil:
    return
  # TODO: Implement

proc propagateCell(self: Model, cell: Cell): void =
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
  self.generateGrid()
