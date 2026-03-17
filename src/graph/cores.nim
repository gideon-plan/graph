#[
=====
Cores
=====

K-core decomposition.
]#

{.push raises: [Defect].}

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== K-CORE DECOMPOSITION ===============================================================================================
#=======================================================================================================================

proc coreNumbers*(g: Graph): seq[system.int] =
  ## Compute core number for each node using the peeling algorithm.
  ## core[i] = the largest k such that node i is in the k-core.
  let n = g.nodeCount
  result.setLen(n)
  var deg: seq[system.int]
  deg.setLen(n)
  for i in 0 ..< n:
    deg[i] = g.degree(NodeId(i))

  # Find max degree.
  var maxDeg = 0
  for d in deg:
    if d > maxDeg:
      maxDeg = d

  # Bin sort by degree.
  var bin: seq[system.int]
  bin.setLen(maxDeg + 1)
  for d in deg:
    bin[d] += 1

  var start: seq[system.int]
  start.setLen(maxDeg + 1)
  var total = 0
  for d in 0 .. maxDeg:
    start[d] = total
    total += bin[d]

  # Position and order arrays.
  var pos: seq[system.int]
  pos.setLen(n)
  var order: seq[system.int]
  order.setLen(n)
  for i in 0 ..< n:
    pos[i] = start[deg[i]]
    order[pos[i]] = i
    start[deg[i]] += 1

  # Reset start.
  total = 0
  for d in 0 .. maxDeg:
    start[d] = total
    total += bin[d]

  for i in 0 ..< n:
    let v = order[i]
    result[v] = deg[v]
    for e in g.neighbors(NodeId(v)):
      let u = e.target.int
      if deg[u] > deg[v]:
        # Move u forward in the bin.
        let du = deg[u]
        let pu = pos[u]
        let pw = start[du]
        let w = order[pw]
        if u != w:
          pos[u] = pw
          pos[w] = pu
          order[pu] = w
          order[pw] = u
        start[du] += 1
        deg[u] -= 1

proc kCore*(g: Graph, k: system.int): seq[NodeId] =
  ## Return nodes in the k-core (nodes with core number >= k).
  let cores = g.coreNumbers()
  for i in 0 ..< g.nodeCount:
    if cores[i] >= k:
      result.add(NodeId(i))

proc degeneracy*(g: Graph): system.int =
  ## Graph degeneracy: maximum core number.
  let cores = g.coreNumbers()
  for c in cores:
    if c > result:
      result = c
