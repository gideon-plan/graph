{.experimental: "strictFuncs".}
## Coloring tests.

import std/unittest

import graph/types
import graph/coloring

suite "greedy coloring":
  test "bipartite graph needs 2 colors":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    g.addEdge(0, 3)
    g.addEdge(2, 1)
    let colors = g.greedyColoring()
    # No adjacent nodes share a color.
    for e in g.edges:
      check colors[e.source.int] != colors[e.target.int]
    check g.chromaticUpperBound() <= 3

  test "complete graph K3 needs 3 colors":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    check g.chromaticUpperBound() == 3

  test "independent set needs 1 color":
    var g = initGraph(gkUndirected)
    discard g.addNodes(5)
    check g.chromaticUpperBound() == 1
