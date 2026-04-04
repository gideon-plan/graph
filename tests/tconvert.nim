{.experimental: "strictFuncs".}
## CSR conversion tests.

import std/unittest

import graph/types
import graph/convert

suite "CSR conversion - directed":
  test "empty graph roundtrip":
    let g = initGraph(gkDirected)
    let csr = g.toCsr()
    check csr.nodeCount == 0
    check csr.edgeCount == 0
    let g2 = csr.toGraph()
    check g2.nodeCount == 0
    check g2.edgeCount == 0

  test "directed graph to CSR":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(1, 3, 3.0)
    g.addEdge(2, 3, 4.0)
    let csr = g.toCsr()
    check csr.nodeCount == 4
    check csr.edgeCount == 4
    # Node 0 has 2 edges.
    check csr.degree(NodeId(0)) == 2
    # Node 1 has 1 edge.
    check csr.degree(NodeId(1)) == 1
    # Node 3 has 0 edges (sink).
    check csr.degree(NodeId(3)) == 0

  test "CSR hasEdge":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let csr = g.toCsr()
    check csr.hasEdge(NodeId(0), NodeId(1))
    check csr.hasEdge(NodeId(1), NodeId(2))
    check not csr.hasEdge(NodeId(1), NodeId(0))
    check not csr.hasEdge(NodeId(0), NodeId(2))

  test "CSR neighbor iteration":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 5.0)
    g.addEdge(0, 2, 7.0)
    let csr = g.toCsr()
    var targets: seq[int]
    var weights: seq[float]
    for (t, w) in csr.neighbors(NodeId(0)):
      targets.add(t.int)
      weights.add(w)
    check targets == @[1, 2]
    check weights == @[5.0, 7.0]

  test "CSR neighborIds iteration":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    let csr = g.toCsr()
    var ids: seq[int]
    for n in csr.neighborIds(NodeId(0)):
      ids.add(n.int)
    check ids == @[1, 2]

  test "CSR node iteration":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    let csr = g.toCsr()
    var ids: seq[int]
    for n in csr.nodes:
      ids.add(n.int)
    check ids == @[0, 1, 2, 3]

  test "CSR edge iteration":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let csr = g.toCsr()
    var count = 0
    for e in csr.edges:
      count += 1
    check count == 3

  test "directed roundtrip preserves structure":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.5)
    g.addEdge(0, 2, 2.5)
    g.addEdge(1, 3, 3.5)
    g.addEdge(3, 0, 4.5)
    let csr = g.toCsr()
    let g2 = csr.toGraph()
    check g2.nodeCount == 4
    check g2.edgeCount == 4
    check g2.hasEdge(NodeId(0), NodeId(1))
    check g2.hasEdge(NodeId(0), NodeId(2))
    check g2.hasEdge(NodeId(1), NodeId(3))
    check g2.hasEdge(NodeId(3), NodeId(0))
    # Verify weights survived.
    check g2.neighbors(NodeId(0))[0].weight == 1.5
    check g2.neighbors(NodeId(0))[1].weight == 2.5

suite "CSR conversion - undirected":
  test "undirected graph to CSR":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 2.0)
    g.addEdge(1, 2, 3.0)
    let csr = g.toCsr()
    check csr.nodeCount == 3
    check csr.edgeCount == 2  # unique undirected edges
    # Both directions present in CSR.
    check csr.hasEdge(NodeId(0), NodeId(1))
    check csr.hasEdge(NodeId(1), NodeId(0))

  test "undirected CSR edge iteration yields each edge once":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let csr = g.toCsr()
    var count = 0
    for e in csr.edges:
      count += 1
    check count == 2
