#[
=====
Cover
=====

Vertex cover (2-approximation) and independent set (complement of vertex cover).
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/sets

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== VERTEX COVER (2-APPROXIMATION) =====================================================================================
#=======================================================================================================================

proc vertexCover*(g: Graph): seq[NodeId] =
  ## 2-approximation vertex cover using greedy edge matching.
  var covered = initHashSet[system.int]()
  for e in g.edges:
    if e.source.int notin covered and e.target.int notin covered:
      covered.incl(e.source.int)
      covered.incl(e.target.int)
  for v in covered:
    result.add(NodeId(v))

#=======================================================================================================================
#== INDEPENDENT SET (COMPLEMENT) =======================================================================================
#=======================================================================================================================

proc independentSet*(g: Graph): seq[NodeId] =
  ## Approximate maximum independent set (complement of vertex cover).
  let cover = g.vertexCover()
  var coverSet = initHashSet[system.int]()
  for v in cover:
    coverSet.incl(v.int)
  for i in 0 ..< g.nodeCount:
    if i notin coverSet:
      result.add(NodeId(i))
