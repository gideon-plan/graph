#[
============
Isomorphism
============

VF2 graph and subgraph isomorphism.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== VF2 GRAPH ISOMORPHISM ==============================================================================================
#=======================================================================================================================

proc isIsomorphic*(g1, g2: Graph): bool =
  ## Check whether g1 and g2 are isomorphic using VF2.
  let n1 = g1.nodeCount
  let n2 = g2.nodeCount
  if n1 != n2:
    return false
  if g1.edgeCount != g2.edgeCount:
    return false

  let n = n1
  var core1: seq[system.int]
  core1.setLen(n)
  var core2: seq[system.int]
  core2.setLen(n)
  for i in 0 ..< n:
    core1[i] = -1
    core2[i] = -1

  proc isFeasible(v1, v2: system.int): bool =
    # Check degree compatibility.
    if g1.degree(NodeId(v1)) != g2.degree(NodeId(v2)):
      return false
    # Check already-mapped neighbors.
    for e in g1.neighbors(NodeId(v1)):
      if core1[e.target.int] >= 0:
        if not g2.hasEdge(NodeId(v2), NodeId(core1[e.target.int])):
          return false
    for e in g2.neighbors(NodeId(v2)):
      if core2[e.target.int] >= 0:
        if not g1.hasEdge(NodeId(v1), NodeId(core2[e.target.int])):
          return false
    true

  proc match(depth: system.int): bool =
    if depth == n:
      return true
    # Find first unmapped node in g1.
    var v1 = -1
    for i in 0 ..< n:
      if core1[i] == -1:
        v1 = i
        break
    if v1 < 0:
      return true
    # Try matching with each unmapped node in g2.
    for v2 in 0 ..< n:
      if core2[v2] == -1 and isFeasible(v1, v2):
        core1[v1] = v2
        core2[v2] = v1
        if match(depth + 1):
          return true
        core1[v1] = -1
        core2[v2] = -1
    false

  match(0)

#=======================================================================================================================
#== VF2 SUBGRAPH ISOMORPHISM ===========================================================================================
#=======================================================================================================================

proc isSubgraphIsomorphic*(pattern, target: Graph): bool =
  ## Check whether `pattern` is a subgraph of `target` using VF2.
  let np = pattern.nodeCount
  let nt = target.nodeCount
  if np > nt:
    return false

  var coreP: seq[system.int]
  coreP.setLen(np)
  var coreT: seq[system.int]
  coreT.setLen(nt)
  for i in 0 ..< np:
    coreP[i] = -1
  for i in 0 ..< nt:
    coreT[i] = -1

  proc isFeasible(vp, vt: system.int): bool =
    if target.degree(NodeId(vt)) < pattern.degree(NodeId(vp)):
      return false
    for e in pattern.neighbors(NodeId(vp)):
      if coreP[e.target.int] >= 0:
        if not target.hasEdge(NodeId(vt), NodeId(coreP[e.target.int])):
          return false
    true

  proc match(depth: system.int): bool =
    if depth == np:
      return true
    var vp = -1
    for i in 0 ..< np:
      if coreP[i] == -1:
        vp = i
        break
    if vp < 0:
      return true
    for vt in 0 ..< nt:
      if coreT[vt] == -1 and isFeasible(vp, vt):
        coreP[vp] = vt
        coreT[vt] = vp
        if match(depth + 1):
          return true
        coreP[vp] = -1
        coreT[vt] = -1
    false

  match(0)
