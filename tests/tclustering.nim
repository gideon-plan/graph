{.experimental: "strictFuncs".}
## Clustering tests.

import std/[unittest, math]

import graph/types
import graph/clustering

suite "triangle counting":
  test "single triangle":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check g.triangleCount() == 1

  test "K4 has 4 triangles":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    g.addEdge(1, 2)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    check g.triangleCount() == 4

suite "clustering coefficient":
  test "triangle has coefficient 1.0":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check abs(g.localClusteringCoefficient(NodeId(0)) - 1.0) < 0.001

  test "star has coefficient 0.0 at center":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(0, 3)
    check g.localClusteringCoefficient(NodeId(0)) == 0.0

  test "global clustering coefficient":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check abs(g.globalClusteringCoefficient() - 1.0) < 0.001
