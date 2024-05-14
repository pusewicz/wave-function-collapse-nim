import hashes
import types

proc new*(_: typedesc[Tile], tileid: int, probability: float, wangid: array[
    0..8, int]): Tile =
  const up = hashes.hash([wangid[7], wangid[0], wangid[1]])
  const right = hashes.hash([wangid[1], wangid[2], wangid[3]])
  const down = hashes.hash([wangid[5], wangid[4], wangid[3]])
  const left = hashes.hash([wangid[7], wangid[6], wangid[5]])
  result = Tile(tileid: tileid, probability: probability, up: up, right: right,
      down: down, left: left)
