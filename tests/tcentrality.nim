{.experimental: "strictFuncs".}
## Centrality tests.

import std/[unittest, math, tables]

import graph/types
import graph/centrality

suite "degree distribution":
  test "simple graph":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    let dd = g.degreeDistribution()
    check dd.getOrDefault(system.int(3)) == 1  # node 0
    check dd.getOrDefault(system.int(1)) == 3  # nodes 1, 2, 3

suite "PageRank":
  test "star graph center has highest rank":
    var g = initGraph(GraphKind.Directed)
    discard g.addNodes(4)
    g.addEdge(1, 0)
    g.addEdge(2, 0)
    g.addEdge(3, 0)
    let pr = g.pageRank()
    check pr[0] > pr[1]
    check pr[0] > pr[2]
    check pr[0] > pr[3]

  test "ranks sum to ~1":
    var g = initGraph(GraphKind.Directed)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let pr = g.pageRank()
    let total = pr[0] + pr[1] + pr[2]
    check abs(total - 1.0) < 0.01

suite "betweenness centrality":
  test "center of star has highest betweenness":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(5)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    g.addEdge(0, 4)
    let bc = g.betweennessCentrality()
    check bc[0] > bc[1]

  test "path graph middle node":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let bc = g.betweennessCentrality()
    check bc[1] == 1.0
    check bc[0] == 0.0
    check bc[2] == 0.0

suite "closeness centrality":
  test "center of star":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    let cc = g.closenessCentrality()
    check cc[0] > cc[1]

suite "eigenvector centrality":
  test "converges":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let ec = g.eigenvectorCentrality()
    check ec.len == 3
    # Middle node should have highest centrality.
    check ec[1] >= ec[0]

suite "HITS":
  test "hub and authority scores":
    var g = initGraph(GraphKind.Directed)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    let (hub, auth) = g.hits()
    check hub[0] > hub[1]  # 0 is the hub
    check auth[1] > auth[0]  # 1, 2 are authorities
