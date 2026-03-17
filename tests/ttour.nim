## Tour tests.

import std/unittest

import graph/types
import graph/tour

suite "Christofides":
  test "small complete graph":
    # K4 with weights.
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(0, 3, 3.0)
    g.addEdge(1, 2, 1.0)
    g.addEdge(1, 3, 2.0)
    g.addEdge(2, 3, 1.0)
    let (cost, path) = g.christofides()
    check path.len == 5  # n+1 (returns to start)
    check path[0] == path[^1]
    check cost > 0.0

  test "trivial 2-node":
    var g = initGraph(gkUndirected)
    discard g.addNodes(2)
    g.addEdge(0, 1, 5.0)
    let (_, path) = g.christofides()
    check path.len == 3
