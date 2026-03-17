## Traversal tests.

import std/unittest

import graph/types
import graph/traversal

suite "BFS":
  test "simple directed graph":
    var g = initGraph(gkDirected)
    discard g.addNodes(5)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 4)
    let order = g.bfsTree(NodeId(0))
    check order[0] == NodeId(0)
    check order.len == 5
    # Level 1 nodes should come before level 2 nodes.
    let idx1 = order.find(NodeId(1))
    let idx2 = order.find(NodeId(2))
    let idx3 = order.find(NodeId(3))
    let idx4 = order.find(NodeId(4))
    check idx1 < idx3
    check idx2 < idx4

  test "BFS parent array":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    let parent = g.bfsParent(NodeId(0))
    check parent[0] == 0
    check parent[1] == 0
    check parent[2] == 0
    check parent[3] == 1

  test "disconnected graph":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    let order = g.bfsTree(NodeId(0))
    check order.len == 2
    check NodeId(0) in order
    check NodeId(1) in order

suite "DFS":
  test "simple directed graph":
    var g = initGraph(gkDirected)
    discard g.addNodes(5)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 4)
    let order = g.dfsTree(NodeId(0))
    check order[0] == NodeId(0)
    check order.len == 5

  test "DFS parent array":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let parent = g.dfsParent(NodeId(0))
    check parent[0] == 0
    check parent[1] == 0
    check parent[2] == 1
    # parent[3] reachable via DFS

suite "topological sort":
  test "DAG":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    let order = g.topologicalSort()
    check order.len == 4
    # 0 must come before 1, 2; both must come before 3.
    let idx0 = order.find(NodeId(0))
    let idx1 = order.find(NodeId(1))
    let idx2 = order.find(NodeId(2))
    let idx3 = order.find(NodeId(3))
    check idx0 < idx1
    check idx0 < idx2
    check idx1 < idx3
    check idx2 < idx3

suite "cycle detection":
  test "directed acyclic":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check not g.hasCycle()

  test "directed with cycle":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check g.hasCycle()

  test "undirected acyclic (tree)":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    check not g.hasCycle()

  test "undirected with cycle":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check g.hasCycle()

suite "bipartite":
  test "bipartite graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 3)
    g.addEdge(2, 1)
    g.addEdge(2, 3)
    check g.isBipartite()

  test "non-bipartite (odd cycle)":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check not g.isBipartite()

  test "bipartite partition":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 3)
    g.addEdge(2, 1)
    g.addEdge(2, 3)
    let (a, b) = g.bipartitePartition()
    check a.len + b.len == 4

  test "empty graph is bipartite":
    let g = initGraph(gkUndirected)
    check g.isBipartite()

suite "Eulerian":
  test "directed Eulerian circuit":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check g.hasEulerianCircuit()
    let circuit = g.eulerianCircuit()
    check circuit.len == 4  # 3 edges + return to start
    check circuit[0] == circuit[^1]

  test "undirected Eulerian circuit":
    # Square: 0-1-2-3-0
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    g.addEdge(3, 0)
    check g.hasEulerianCircuit()
    let circuit = g.eulerianCircuit()
    check circuit.len == 5
    check circuit[0] == circuit[^1]

  test "Eulerian path exists":
    # 0-1-2 (path, not circuit)
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    check g.hasEulerianPath()
    check not g.hasEulerianCircuit()

  test "no Eulerian path":
    # Star with 3 odd-degree nodes
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    check not g.hasEulerianPath()
