{.experimental: "strictFuncs".}
## Isomorphism tests.

import std/unittest

import graph/types
import graph/isomorphism

suite "graph isomorphism":
  test "identical graphs":
    var g1 = initGraph(GraphKind.Undirected)
    discard g1.addNodes(3)
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = initGraph(GraphKind.Undirected)
    discard g2.addNodes(3)
    g2.addEdge(0, 1)
    g2.addEdge(1, 2)
    check g1.isIsomorphic(g2)

  test "relabeled graph":
    var g1 = initGraph(GraphKind.Undirected)
    discard g1.addNodes(3)
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = initGraph(GraphKind.Undirected)
    discard g2.addNodes(3)
    g2.addEdge(1, 2)
    g2.addEdge(2, 0)
    check g1.isIsomorphic(g2)

  test "different structure":
    var g1 = initGraph(GraphKind.Undirected)
    discard g1.addNodes(3)
    g1.addEdge(0, 1)
    g1.addEdge(1, 2)
    var g2 = initGraph(GraphKind.Undirected)
    discard g2.addNodes(3)
    g2.addEdge(0, 1)
    g2.addEdge(0, 2)
    g2.addEdge(1, 2)
    check not g1.isIsomorphic(g2)

suite "subgraph isomorphism":
  test "triangle in K4":
    var pattern = initGraph(GraphKind.Undirected)
    discard pattern.addNodes(3)
    pattern.addEdge(0, 1)
    pattern.addEdge(1, 2)
    pattern.addEdge(2, 0)
    var target = initGraph(GraphKind.Undirected)
    discard target.addNodes(4)
    target.addEdge(0, 1)
    target.addEdge(0, 2)
    target.addEdge(0, 3)
    target.addEdge(1, 2)
    target.addEdge(1, 3)
    target.addEdge(2, 3)
    check pattern.isSubgraphIsomorphic(target)

  test "larger pattern fails":
    var pattern = initGraph(GraphKind.Undirected)
    discard pattern.addNodes(5)
    var target = initGraph(GraphKind.Undirected)
    discard target.addNodes(3)
    check not pattern.isSubgraphIsomorphic(target)
