## Clique tests.

import std/unittest

import graph/types
import graph/clique

suite "Bron-Kerbosch":
  test "triangle is a clique":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let cliques = g.bronKerbosch()
    check cliques.len == 1
    check cliques[0].len == 3

  test "max clique in graph with triangle and pendant":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(2, 3)
    let mc = g.maxClique()
    check mc.len == 3  # Triangle {0, 1, 2}.

  test "clique count":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(2, 3)
    check g.cliqueCount() == 2  # {0,1,2} and {2,3}
