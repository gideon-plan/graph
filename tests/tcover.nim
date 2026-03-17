## Cover tests.

import std/[unittest, sequtils, sets]

import graph/types
import graph/cover

suite "vertex cover":
  test "covers all edges":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 3)
    let vc = g.vertexCover()
    let vcSet = vc.mapIt(system.int(it)).toHashSet
    for e in g.edges:
      check e.source.int in vcSet or e.target.int in vcSet

  test "triangle":
    var g = initGraph(gkUndirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    g.addEdge(2, 0)
    let vc = g.vertexCover()
    check vc.len <= 3  # 2-approx guarantees <= 2 * OPT.

suite "independent set":
  test "complement of vertex cover":
    var g = initGraph(gkUndirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    let indepSet = g.independentSet()
    let indepIds = indepSet.mapIt(system.int(it)).toHashSet
    for e in g.edges:
      check not (e.source.int in indepIds and e.target.int in indepIds)
