## Distance tests.

import std/unittest

import graph/types
import graph/distance

suite "eccentricity":
  test "center node has lower eccentricity":
    var g = initGraph(gkUndirected)
    discard g.addNodes(5)
    # Path: 0-1-2-3-4
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    check g.eccentricity(NodeId(2)) == 2.0
    check g.eccentricity(NodeId(0)) == 4.0

suite "diameter":
  test "path graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check g.diameter() == 3.0

  test "complete graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    check g.diameter() == 1.0

suite "radius":
  test "path graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(5)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    check g.radius() == 2.0

suite "center":
  test "path graph center":
    var g = initGraph(gkUndirected)
    discard g.addNodes(5)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    let c = g.center()
    check NodeId(2) in c
