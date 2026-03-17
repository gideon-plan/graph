#[
========================
Minimum Spanning Tree
========================

Prim's and Kruskal's MST algorithms.
]#

{.push raises: [Defect].}

# std...
import std/[algorithm, heapqueue]

# graph...
import types
import unionfind

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== TYPES ==============================================================================================================
#=======================================================================================================================

type
  MstEdge* = object
    ## An edge in the MST result.
    source*: NodeId
    target*: NodeId
    weight*: float

#=======================================================================================================================
#== KRUSKAL ============================================================================================================
#=======================================================================================================================

proc kruskal*(g: Graph): seq[MstEdge] =
  ## Kruskal's MST for undirected graphs. Returns MST edges sorted by weight.
  var edgeList: seq[MstEdge]
  for e in g.edges:
    edgeList.add(MstEdge(source: e.source, target: e.target, weight: e.weight))
  edgeList.sort(proc(a, b: MstEdge): system.int = cmp(a.weight, b.weight))

  var uf = initUnionFind(g.nodeCount)
  for e in edgeList:
    if not uf.connected(e.source.int, e.target.int):
      uf.union(e.source.int, e.target.int)
      result.add(e)
      if result.len == g.nodeCount - 1:
        break

proc kruskalWeight*(g: Graph): float =
  ## Total weight of Kruskal's MST.
  for e in g.kruskal():
    result += e.weight

#=======================================================================================================================
#== PRIM ===============================================================================================================
#=======================================================================================================================

type
  PrimEntry = object
    weight: float
    node: NodeId
    parent: system.int

proc `<`(a, b: PrimEntry): bool = a.weight < b.weight

proc prim*(g: Graph): seq[MstEdge] =
  ## Prim's MST for undirected graphs. Returns MST edges.
  let n = g.nodeCount
  if n == 0:
    return @[]
  var inMst: seq[bool]
  inMst.setLen(n)
  var pq = initHeapQueue[PrimEntry]()
  pq.push(PrimEntry(weight: 0.0, node: NodeId(0), parent: -1))

  while pq.len > 0 and result.len < n - 1:
    let cur = pq.pop()
    if inMst[cur.node.int]:
      continue
    inMst[cur.node.int] = true
    if cur.parent >= 0:
      result.add(MstEdge(source: NodeId(cur.parent), target: cur.node, weight: cur.weight))
    for e in g.neighbors(cur.node):
      if not inMst[e.target.int]:
        pq.push(PrimEntry(weight: e.weight, node: e.target, parent: cur.node.int))

proc primWeight*(g: Graph): float =
  ## Total weight of Prim's MST.
  for e in g.prim():
    result += e.weight
