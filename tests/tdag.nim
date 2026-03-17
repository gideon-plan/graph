## DAG tests.

import std/unittest

import graph/types
import graph/dag

suite "transitive closure":
  test "simple DAG":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let tc = g.transitiveClosure()
    check tc.hasEdge(NodeId(0), NodeId(1))
    check tc.hasEdge(NodeId(0), NodeId(2))  # transitive
    check tc.hasEdge(NodeId(1), NodeId(2))
    check not tc.hasEdge(NodeId(2), NodeId(0))

suite "transitive reduction":
  test "removes redundant edges":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(0, 2)  # redundant: 0->1->2
    let tr = g.transitiveReduction()
    check tr.hasEdge(NodeId(0), NodeId(1))
    check tr.hasEdge(NodeId(1), NodeId(2))
    check not tr.hasEdge(NodeId(0), NodeId(2))

suite "longest path":
  test "DAG critical path":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 3.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(1, 3, 4.0)
    g.addEdge(2, 3, 1.0)
    let (dist, _) = g.longestPath(NodeId(0))
    check dist[3] == 7.0  # 0 -> 1 -> 3

  test "critical path length":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 3.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(1, 3, 4.0)
    g.addEdge(2, 3, 1.0)
    check g.criticalPathLength(NodeId(0)) == 7.0

suite "dominator tree":
  test "simple DAG":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let idom = g.dominatorTree(NodeId(0))
    check idom[0] == 0  # entry dominates itself
    check idom[1] == 0
    check idom[2] == 0
    check idom[3] == 0  # 0 dominates 3 (both paths go through 0)

  test "linear chain":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let idom = g.dominatorTree(NodeId(0))
    check idom[0] == 0
    check idom[1] == 0
    check idom[2] == 1
