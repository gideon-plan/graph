{.experimental: "strictFuncs".}
## Matching tests.

import std/unittest

import graph/types
import graph/matching

suite "Hopcroft-Karp":
  test "bipartite matching":
    var g = initGraph(gkUndirected)
    discard g.addNodes(6)
    # Left: 0, 1, 2; Right: 3, 4, 5
    g.addEdge(0, 3)
    g.addEdge(0, 4)
    g.addEdge(1, 3)
    g.addEdge(2, 5)
    let m = g.hopcroftKarp(@[NodeId(0), NodeId(1), NodeId(2)],
                           @[NodeId(3), NodeId(4), NodeId(5)])
    check m.len == 3  # Perfect matching exists.

  test "incomplete matching":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    # Left: 0, 1; Right: 2, 3
    g.addEdge(0, 2)
    g.addEdge(1, 2)  # Both compete for node 2.
    let m = g.hopcroftKarp(@[NodeId(0), NodeId(1)],
                           @[NodeId(2), NodeId(3)])
    check m.len == 1  # Only one can match.

suite "Edmonds blossom":
  test "general matching":
    # Triangle: general matching finds 1 edge.
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let m = g.edmondsMatching()
    check m.len == 1

  test "path of 4 nodes":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let m = g.edmondsMatching()
    check m.len == 2

suite "Hungarian":
  test "minimum cost assignment":
    let cost = @[
      @[1.0, 2.0, 3.0],
      @[4.0, 5.0, 6.0],
      @[7.0, 8.0, 9.0]
    ]
    let (totalCost, assignment) = hungarian(cost)
    check assignment.len == 3
    # Minimum: 1 + 5 + 9 = 15.
    check totalCost == 15.0
