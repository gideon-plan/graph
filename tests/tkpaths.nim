## K-shortest paths tests.

import std/unittest

import graph/types
import graph/kpaths

suite "Yen's k-shortest paths":
  test "simple graph k=2":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 3, 1.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(2, 3, 1.0)
    let paths = g.yenKPaths(NodeId(0), NodeId(3), 2)
    check paths.len == 2
    check paths[0].dist == 2.0
    check paths[0].nodes == @[NodeId(0), NodeId(1), NodeId(3)]
    check paths[1].dist == 3.0
    check paths[1].nodes == @[NodeId(0), NodeId(2), NodeId(3)]

  test "single path":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, 1.0)
    let paths = g.yenKPaths(NodeId(0), NodeId(2), 3)
    check paths.len == 1
    check paths[0].dist == 2.0

  test "unreachable target":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    let paths = g.yenKPaths(NodeId(0), NodeId(2), 2)
    check paths.len == 0

  test "k=0 returns empty":
    var g = initGraph(gkDirected)
    discard g.addNodes(2)
    g.addEdge(0, 1, 1.0)
    let paths = g.yenKPaths(NodeId(0), NodeId(1), 0)
    check paths.len == 0
