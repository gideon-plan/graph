{.experimental: "strictFuncs".}
## Embedding tests.

import std/[unittest, random]

import graph/types
import graph/embedding

suite "Node2Vec":
  test "walk starts at start node":
    var g = initGraph(gkUndirected)
    discard g.addNodes(5)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 4)
    var rng = initRand(42)
    let walk = g.node2vecWalk(NodeId(0), 5, 1.0, 1.0, rng)
    check walk[0] == NodeId(0)
    check walk.len == 5

  test "isolated node produces length-1 walk":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    var rng = initRand(42)
    let walk = g.node2vecWalk(NodeId(0), 10, 1.0, 1.0, rng)
    check walk.len == 1
    check walk[0] == NodeId(0)

  test "batch walks":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let walks = g.node2vecWalks(numWalks = 2, walkLength = 5)
    check walks.len == 8  # 2 walks * 4 nodes
