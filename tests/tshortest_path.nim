## Shortest path tests.

import std/unittest

import graph/types
import graph/shortest_path

suite "Dijkstra":
  test "simple directed graph":
    var g = initGraph(gkDirected)
    discard g.addNodes(5)
    g.addEdge(0, 1, 4.0)
    g.addEdge(0, 2, 1.0)
    g.addEdge(2, 1, 2.0)
    g.addEdge(1, 3, 1.0)
    g.addEdge(2, 3, 5.0)
    g.addEdge(3, 4, 3.0)
    let (dist, _) = g.dijkstra(NodeId(0))
    check dist[0] == 0.0
    check dist[1] == 3.0  # 0 -> 2 -> 1
    check dist[2] == 1.0
    check dist[3] == 4.0  # 0 -> 2 -> 1 -> 3
    check dist[4] == 7.0

  test "unreachable node":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    let (dist, _) = g.dijkstra(NodeId(0))
    check dist[2] == InfDist

  test "path reconstruction":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, 1.0)
    g.addEdge(2, 3, 1.0)
    g.addEdge(0, 3, 10.0)
    let (dist, path) = g.dijkstraPath(NodeId(0), NodeId(3))
    check dist == 3.0
    check path == @[NodeId(0), NodeId(1), NodeId(2), NodeId(3)]

suite "Bellman-Ford":
  test "negative weights":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, -3.0)
    g.addEdge(0, 2, 2.0)
    g.addEdge(2, 3, 1.0)
    let (dist, _, hasNeg) = g.bellmanFord(NodeId(0))
    check not hasNeg
    check dist[0] == 0.0
    check dist[2] == -2.0  # 0 -> 1 -> 2
    check dist[3] == -1.0

  test "negative cycle detection":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, -1.0)
    g.addEdge(2, 0, -1.0)
    let (_, _, hasNeg) = g.bellmanFord(NodeId(0))
    check hasNeg

suite "A*":
  test "with zero heuristic (degenerates to Dijkstra)":
    var g = initGraph(gkDirected)
    discard g.addNodes(4)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, 1.0)
    g.addEdge(2, 3, 1.0)
    g.addEdge(0, 3, 10.0)
    let h: Heuristic = proc(node, target: NodeId): float = 0.0
    let (dist, path) = g.aStar(NodeId(0), NodeId(3), h)
    check dist == 3.0
    check path == @[NodeId(0), NodeId(1), NodeId(2), NodeId(3)]

  test "unreachable target":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    let h: Heuristic = proc(node, target: NodeId): float = 0.0
    let (dist, path) = g.aStar(NodeId(0), NodeId(2), h)
    check dist == InfDist
    check path.len == 0

suite "bidirectional Dijkstra":
  test "undirected graph":
    var g = initGraph(gkUndirected)
    discard g.addNodes(5)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, 2.0)
    g.addEdge(0, 3, 4.0)
    g.addEdge(3, 4, 1.0)
    g.addEdge(2, 4, 1.0)
    let (dist, _) = g.bidirectionalDijkstra(NodeId(0), NodeId(4))
    check dist == 4.0  # 0 -> 1 -> 2 -> 4

suite "Floyd-Warshall":
  test "all-pairs shortest paths":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, 2.0)
    g.addEdge(0, 2, 5.0)
    let (dist, _) = g.floydWarshall()
    check dist[0][0] == 0.0
    check dist[0][1] == 1.0
    check dist[0][2] == 3.0  # 0 -> 1 -> 2
    check dist[1][0] == InfDist

  test "path reconstruction":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, 1.0)
    g.addEdge(0, 2, 5.0)
    let (_, next) = g.floydWarshall()
    let path = floydWarshallPath(next, 0, 2)
    check path == @[NodeId(0), NodeId(1), NodeId(2)]

suite "Johnson":
  test "sparse graph with negative weights":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 2.0)
    g.addEdge(1, 2, -1.0)
    g.addEdge(0, 2, 4.0)
    let (dist, hasNeg) = g.johnson()
    check not hasNeg
    check dist[0][2] == 1.0  # 0 -> 1 -> 2

  test "negative cycle detection":
    var g = initGraph(gkDirected)
    discard g.addNodes(3)
    g.addEdge(0, 1, 1.0)
    g.addEdge(1, 2, -2.0)
    g.addEdge(2, 0, -1.0)
    let (_, hasNeg) = g.johnson()
    check hasNeg
