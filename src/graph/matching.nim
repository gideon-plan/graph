#[
========
Matching
========

Hopcroft-Karp bipartite matching, Edmonds' blossom general matching,
Hungarian weighted bipartite matching.
]#

{.push raises: [Defect].}

# std...
import std/deques

# graph...
import types
import shortest_path

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== HOPCROFT-KARP BIPARTITE MATCHING ===================================================================================
#=======================================================================================================================

const NilNode = -1

proc hopcroftKarp*(g: Graph, leftNodes, rightNodes: seq[NodeId]): seq[(NodeId, NodeId)] =
  ## Maximum cardinality bipartite matching using Hopcroft-Karp.
  ## `leftNodes` and `rightNodes` define the bipartition.
  let n = g.nodeCount
  var matchL: seq[system.int]
  matchL.setLen(n)
  var matchR: seq[system.int]
  matchR.setLen(n)
  for i in 0 ..< n:
    matchL[i] = NilNode
    matchR[i] = NilNode

  var dist: seq[system.int]
  dist.setLen(n)

  proc bfs(): bool =
    var queue = initDeque[system.int]()
    for u in leftNodes:
      if matchL[u.int] == NilNode:
        dist[u.int] = 0
        queue.addLast(u.int)
      else:
        dist[u.int] = high(system.int)
    var found = false
    while queue.len > 0:
      let u = queue.popFirst()
      for e in g.neighbors(NodeId(u)):
        let v = e.target.int
        let w = matchR[v]
        if w == NilNode:
          found = true
        elif dist[w] == high(system.int):
          dist[w] = dist[u] + 1
          queue.addLast(w)
    found

  proc dfsAug(u: system.int): bool =
    for e in g.neighbors(NodeId(u)):
      let v = e.target.int
      let w = matchR[v]
      if w == NilNode or (dist[w] == dist[u] + 1 and dfsAug(w)):
        matchL[u] = v
        matchR[v] = u
        return true
    dist[u] = high(system.int)
    false

  while bfs():
    for u in leftNodes:
      if matchL[u.int] == NilNode:
        discard dfsAug(u.int)

  for u in leftNodes:
    if matchL[u.int] != NilNode:
      result.add((u, NodeId(matchL[u.int])))

#=======================================================================================================================
#== EDMONDS' BLOSSOM (GENERAL MATCHING) ================================================================================
#=======================================================================================================================

proc edmondsMatching*(g: Graph): seq[(NodeId, NodeId)] =
  ## Maximum cardinality matching for general (non-bipartite) graphs
  ## using augmenting paths with blossom contraction.
  let n = g.nodeCount
  var mate: seq[system.int]
  mate.setLen(n)
  for i in 0 ..< n:
    mate[i] = NilNode

  proc tryAugment(root: system.int): bool =
    # BFS to find augmenting path from unmatched `root`.
    var parent: seq[system.int]
    parent.setLen(n)
    for i in 0 ..< n:
      parent[i] = NilNode
    parent[root] = root
    var queue = initDeque[system.int]()
    queue.addLast(root)

    while queue.len > 0:
      let u = queue.popFirst()
      for e in g.neighbors(NodeId(u)):
        let v = e.target.int
        if parent[v] != NilNode or v == root:
          continue
        if mate[v] == NilNode:
          # Found augmenting path: augment.
          parent[v] = u
          var w = v
          while true:
            let p = parent[w]
            let oldMate = mate[p]
            mate[w] = p
            mate[p] = w
            if p == root:
              break
            w = oldMate
          return true
        else:
          # v is matched; extend alternating tree through its mate.
          parent[v] = u
          let m = mate[v]
          parent[m] = v
          queue.addLast(m)
    false

  for i in 0 ..< n:
    if mate[i] == NilNode:
      discard tryAugment(i)

  for i in 0 ..< n:
    if mate[i] != NilNode and i < mate[i]:
      result.add((NodeId(i), NodeId(mate[i])))

#=======================================================================================================================
#== HUNGARIAN (WEIGHTED BIPARTITE MATCHING) ============================================================================
#=======================================================================================================================

proc hungarian*(costMatrix: seq[seq[float]]): (float, seq[system.int]) =
  ## Hungarian algorithm for minimum weight perfect matching on a bipartite graph.
  ## costMatrix[i][j] = cost of assigning row i to column j.
  ## Returns (total cost, assignment) where assignment[i] = column assigned to row i.
  let n = costMatrix.len
  if n == 0:
    return (0.0, @[])

  # Pad to square if needed.
  var m = n
  for row in costMatrix:
    if row.len > m:
      m = row.len

  var cost: seq[seq[float]]
  cost.setLen(m)
  for i in 0 ..< m:
    cost[i].setLen(m)
    for j in 0 ..< m:
      if i < n and j < costMatrix[i].len:
        cost[i][j] = costMatrix[i][j]

  var u: seq[float]
  u.setLen(m + 1)
  var v: seq[float]
  v.setLen(m + 1)
  var p: seq[system.int]
  p.setLen(m + 1)
  var way: seq[system.int]
  way.setLen(m + 1)

  for i in 1 .. m:
    p[0] = i
    var j0 = 0
    var minv: seq[float]
    minv.setLen(m + 1)
    var used: seq[bool]
    used.setLen(m + 1)
    for j in 0 .. m:
      minv[j] = InfDist
      used[j] = false

    while true:
      used[j0] = true
      let i0 = p[j0]
      var delta = InfDist
      var j1 = -1
      for j in 1 .. m:
        if not used[j]:
          let cur = cost[i0 - 1][j - 1] - u[i0] - v[j]
          if cur < minv[j]:
            minv[j] = cur
            way[j] = j0
          if minv[j] < delta:
            delta = minv[j]
            j1 = j
      if j1 < 0:
        break

      for j in 0 .. m:
        if used[j]:
          u[p[j]] += delta
          v[j] -= delta
        else:
          minv[j] -= delta

      j0 = j1
      if p[j0] == 0:
        break

    while j0 != 0:
      p[j0] = p[way[j0]]
      j0 = way[j0]

  var assignment: seq[system.int]
  assignment.setLen(m)
  for j in 1 .. m:
    if p[j] > 0:
      assignment[p[j] - 1] = j - 1

  var totalCost = 0.0
  for i in 0 ..< n:
    if assignment[i] < costMatrix[i].len:
      totalCost += costMatrix[i][assignment[i]]

  (totalCost, assignment[0 ..< n])
