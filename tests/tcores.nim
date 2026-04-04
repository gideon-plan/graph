{.experimental: "strictFuncs".}
## Cores tests.

import std/unittest

import graph/types
import graph/cores

suite "k-core":
  test "triangle is 2-core":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(2, 3)
    let cn = g.coreNumbers()
    check cn[0] == 2
    check cn[1] == 2
    check cn[2] == 2
    check cn[3] == 1

  test "k-core members":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(2, 3)
    let core2 = g.kCore(2)
    check core2.len == 3

  test "degeneracy":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    g.addEdge(0, 3)
    g.addEdge(1, 3)
    g.addEdge(2, 3)
    check g.degeneracy() == 3  # K4
