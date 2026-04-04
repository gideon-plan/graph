{.experimental: "strictFuncs".}
## Graph types tests.

import std/unittest

import graph/types

suite "graph types - directed":
  test "empty graph":
    let g = initGraph(gkDirected)
    check g.nodeCount == 0
    check g.edgeCount == 0
    check g.isEmpty

  test "add nodes":
    var g = initGraph(gkDirected)
    let a = g.addNode()
    let b = g.addNode()
    let c = g.addNode()
    check a == NodeId(0)
    check b == NodeId(1)
    check c == NodeId(2)
    check g.nodeCount == 3
    check not g.isEmpty

  test "add nodes batch":
    var g = initGraph(gkDirected)
    let first = g.addNodes(5)
    check first == NodeId(0)
    check g.nodeCount == 5

  test "add edges":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 2.0)
    g.addEdge(0, 2, 3.0)
    g.addEdge(1, 2, 1.0)
    check g.edgeCount == 3
    check g.degree(NodeId(0)) == 2
    check g.degree(NodeId(1)) == 1
    check g.degree(NodeId(2)) == 0

  test "has edge":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check g.hasEdge(NodeId(0), NodeId(1))
    check g.hasEdge(NodeId(1), NodeId(2))
    check not g.hasEdge(NodeId(1), NodeId(0))  # directed: no reverse
    check not g.hasEdge(NodeId(0), NodeId(2))

  test "neighbors":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 5.0)
    g.addEdge(0, 2, 7.0)
    let nbrs = g.neighbors(NodeId(0))
    check nbrs.len == 2
    check nbrs[0].target == NodeId(1)
    check nbrs[0].weight == 5.0
    check nbrs[1].target == NodeId(2)
    check nbrs[1].weight == 7.0

  test "default weight is 1.0":
    var g = initGraph(gkDirected)
    discard g.addNodes(2)
    g.addEdge(0, 1)
    check g.neighbors(NodeId(0))[0].weight == 1.0

  test "node iteration":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    var ids: seq[int]
    for n in g.nodes:
      ids.add(n.int)
    check ids == @[0, 1, 2, 3]

  test "edge iteration":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    var count = 0
    for e in g.edges:
      count += 1
    check count == 3

  test "neighbor id iteration":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 3)
    var ids: seq[int]
    for n in g.neighborIds(NodeId(0)):
      ids.add(n.int)
    check ids == @[1, 3]

suite "graph types - undirected":
  test "undirected edges stored both ways":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 2.0)
    g.addEdge(1, 2, 3.0)
    # Edge count should reflect unique undirected edges.
    check g.edgeCount == 2
    # Both directions present in adjacency.
    check g.hasEdge(NodeId(0), NodeId(1))
    check g.hasEdge(NodeId(1), NodeId(0))
    check g.hasEdge(NodeId(1), NodeId(2))
    check g.hasEdge(NodeId(2), NodeId(1))

  test "undirected degree":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    check g.degree(NodeId(0)) == 3
    check g.degree(NodeId(1)) == 1

  test "undirected edge iteration yields each edge once":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    var count = 0
    for e in g.edges:
      count += 1
    check count == 2

suite "graph types - labeled nodes":
  test "labeled node lookup":
    var g = initGraph(gkDirected)
    let a = g.addLabeledNode("alice")
    let b = g.addLabeledNode("bob")
    check g.nodeByLabel("alice") == a
    check g.nodeByLabel("bob") == b

  test "try labeled node":
    var g = initGraph(gkDirected)
    discard g.addLabeledNode("alice")
    let (found, _) = g.tryNodeByLabel("alice")
    check found
    let (notFound, _) = g.tryNodeByLabel("unknown")
    check not notFound

suite "graph types - capacity":
  test "preallocated graph":
    var g = initGraph(gkDirected, capacity = 100)
    check g.nodeCount == 0
    discard g.addNodes(50)
    check g.nodeCount == 50
