# Implements a cell object in a grid with x and y coordinates

import std/random
import types

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

proc neighbors*(self: Cell, model: Model): Cell.neighbors =
  if self.y < model.height - 1:
    self.neighbors[Direction.Up] = model.cellAt(self.x, self.y + 1)

  if self.x < model.width - 1:
    self.neighbors[Direction.Right] = model.cellAt(self.x + 1, self.y)

  if self.y > 0:
    self.neighbors[Direction.Down] = model.cellAt(self.x, self.y - 1)

  if self.x > 0:
    self.neighbors[Direction.Left] = model.cellAt(self.x - 1, self.y)

  self.neighbors
