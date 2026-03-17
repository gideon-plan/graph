## MST tests.

import std/unittest

import graph/types
import graph/mst

suite "Kruskal":
  test "simple undirected graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(0, 2, 4.0)
    g.addEdge(1, 2, 2.0)
    g.addEdge(2, 3, 3.0)
    let mstEdges = g.kruskal()
    check mstEdges.len == 3
    check g.kruskalWeight() == 6.0  # 1 + 2 + 3

  test "disconnected graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(2, 3, 2.0)
    let mstEdges = g.kruskal()
    check mstEdges.len == 2
    check g.kruskalWeight() == 3.0

suite "Prim":
  test "simple undirected graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(0, 2, 4.0)
    g.addEdge(1, 2, 2.0)
    g.addEdge(2, 3, 3.0)
    check g.primWeight() == 6.0

  test "Prim and Kruskal agree":
    var g = initGraph(gkUndirected)
    discard g.addNodes(5)
    g.addEdge(0, 1, 2.0)
    g.addEdge(0, 3, 6.0)
    g.addEdge(1, 2, 3.0)
    g.addEdge(1, 3, 8.0)
    g.addEdge(1, 4, 5.0)
    g.addEdge(2, 4, 7.0)
    g.addEdge(3, 4, 9.0)
    check g.primWeight() == g.kruskalWeight()

  test "empty graph":
    let g = initGraph(gkUndirected)
    check g.prim().len == 0
