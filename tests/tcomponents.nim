## Components tests.

import std/unittest

import graph/types
import graph/components

suite "connected components":
  test "single component":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    check g.componentCount() == 1
    check g.isConnected()

  test "two components":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    check g.componentCount() == 2
    check not g.isConnected()

  test "isolated nodes":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    check g.componentCount() == 3

suite "Tarjan SCC":
  test "single SCC (cycle)":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let sccs = g.tarjanScc()
    check sccs.len == 1
    check sccs[0].len == 3

  test "three SCCs":
    var g = initGraph(gkDirected)
    discard g.addNodes(6)
    # SCC 1: 0, 1, 2
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    # SCC 2: 3, 4
    g.addEdge(3, 4)
    g.addEdge(4, 3)
    # SCC 3: 5 (singleton)
    g.addEdge(2, 3)
    g.addEdge(4, 5)
    let sccs = g.tarjanScc()
    check sccs.len == 3

  test "DAG (each node is own SCC)":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let sccs = g.tarjanScc()
    check sccs.len == 3

suite "Kosaraju SCC":
  test "single SCC":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let sccs = g.kosarajuScc()
    check sccs.len == 1
    check sccs[0].len == 3

  test "Tarjan and Kosaraju agree on count":
    var g = initGraph(gkDirected)
    discard g.addNodes(6)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(3, 4)
    g.addEdge(4, 3)
    g.addEdge(2, 3)
    g.addEdge(4, 5)
    check g.tarjanScc().len == g.kosarajuScc().len

suite "articulation points":
  test "single cut vertex":
    # 0 - 1 - 2; 1 is the only AP
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let aps = g.articulationPoints()
    check aps.len == 1
    check aps[0] == NodeId(1)

  test "no cut vertex in a cycle":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check g.articulationPoints().len == 0

suite "bridges":
  test "single bridge":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(1, 3)  # bridge: 1-3
    let b = g.bridges()
    check b.len == 1

  test "no bridges in complete graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    check g.bridges().len == 0
