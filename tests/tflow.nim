## Flow tests.

import std/unittest

import graph/types
import graph/flow
import graph/shortest_path

suite "Edmonds-Karp":
  test "simple max flow":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 3.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(1, 3, 2.0)
    g.addEdge(2, 3, 3.0)
    let (maxFlow, _) = g.edmondsKarp(NodeId(0), NodeId(3))
    check maxFlow == 4.0

  test "no path":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 5.0)
    let (maxFlow, _) = g.edmondsKarp(NodeId(0), NodeId(2))
    check maxFlow == 0.0

suite "push-relabel":
  test "simple max flow":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 3.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(1, 3, 2.0)
    g.addEdge(2, 3, 3.0)
    let maxFlow = g.pushRelabel(NodeId(0), NodeId(3))
    check maxFlow == 4.0

suite "Stoer-Wagner min-cut":
  test "simple undirected graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 2.0)
    g.addEdge(0, 2, 3.0)
    g.addEdge(1, 2, 1.0)
    g.addEdge(1, 3, 3.0)
    g.addEdge(2, 3, 1.0)
    let (cutWeight, _) = g.stoerWagner()
    check cutWeight > 0.0

suite "min-cost max-flow":
  test "simple network":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 2.0)
    g.addEdge(1, 2, 2.0)
    g.addEdge(0, 2, 1.0)
    var costs: seq[seq[float]]
    costs.setLen(3)
    for i in 0 ..< 3:
      costs[i].setLen(3)
    costs[0][1] = 1.0
    costs[1][2] = 1.0
    costs[0][2] = 3.0
    let (totalFlow, totalCost, _) = g.minCostMaxFlow(NodeId(0), NodeId(2), costs)
    check totalFlow == 3.0
    check totalCost > 0.0
