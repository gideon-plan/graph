#[
===
DAG
===

Topological sort, transitive closure, transitive reduction, longest path
(critical path), dominator tree.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# graph...
import types
import traversal

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== TRANSITIVE CLOSURE =================================================================================================
#=======================================================================================================================

proc transitiveClosure*(g: Graph): Graph =
  ## Compute the transitive closure of a directed graph.
  ## Returns a new graph where edge (u, v) exists iff v is reachable from u.
  let n = g.nodeCount
  # Start with a reachability matrix.
  var reach: seq[seq[bool]]
  reach.setLen(n)
  for i in 0 ..< n:
    reach[i].setLen(n)
    reach[i][i] = true
    for e in g.neighbors(NodeId(i)):
      reach[i][e.target.int] = true

  # Floyd-Warshall style transitive closure.
  for k in 0 ..< n:
    for i in 0 ..< n:
      if not reach[i][k]:
        continue
      for j in 0 ..< n:
        if reach[k][j]:
          reach[i][j] = true

  result = initGraph(gkDirected, n)
  for i in 0 ..< n:
    discard result.addNode()
  for i in 0 ..< n:
    for j in 0 ..< n:
      if i != j and reach[i][j]:
        result.addEdge(NodeId(i), NodeId(j))

#=======================================================================================================================
#== TRANSITIVE REDUCTION ===============================================================================================
#=======================================================================================================================

proc transitiveReduction*(g: Graph): Graph =
  ## Compute the transitive reduction of a DAG.
  ## Returns the minimal subgraph with the same reachability.
  let n = g.nodeCount
  # Compute reachability matrix via transitive closure.
  var reach: seq[seq[bool]]
  reach.setLen(n)
  for i in 0 ..< n:
    reach[i].setLen(n)
    for e in g.neighbors(NodeId(i)):
      reach[i][e.target.int] = true

  for k in 0 ..< n:
    for i in 0 ..< n:
      if not reach[i][k]:
        continue
      for j in 0 ..< n:
        if reach[k][j]:
          reach[i][j] = true

  result = initGraph(gkDirected, n)
  for i in 0 ..< n:
    discard result.addNode()

  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      let j = e.target.int
      # Keep edge (i, j) only if no intermediate path exists.
      var redundant = false
      for k in 0 ..< n:
        if k != i and k != j and reach[i][k] and reach[k][j]:
          # Check that k is reachable via a direct neighbor (not j itself).
          if g.hasEdge(NodeId(i), NodeId(k)) or (reach[i][k] and k != j):
            redundant = true
            break
      if not redundant:
        result.addEdge(NodeId(i), NodeId(j), e.weight)

#=======================================================================================================================
#== LONGEST PATH (CRITICAL PATH) =======================================================================================
#=======================================================================================================================

proc longestPath*(g: Graph, source: NodeId): (seq[float], seq[system.int]) =
  ## Longest path from `source` in a DAG. Returns (distances, predecessors).
  ## Uses topological sort + relaxation. Distances default to -Inf for unreachable nodes.
  let n = g.nodeCount
  let topoOrder = g.topologicalSort()

  var dist: seq[float]
  dist.setLen(n)
  var pred: seq[system.int]
  pred.setLen(n)
  for i in 0 ..< n:
    dist[i] = -Inf
    pred[i] = -1
  dist[source.int] = 0.0
  pred[source.int] = source.int

  for node in topoOrder:
    if dist[node.int] == -Inf:
      continue
    for e in g.neighbors(node):
      let newDist = dist[node.int] + e.weight
      if newDist > dist[e.target.int]:
        dist[e.target.int] = newDist
        pred[e.target.int] = node.int

  (dist, pred)

proc criticalPathLength*(g: Graph, source: NodeId): float =
  ## Length of the longest path from `source` in a DAG.
  let (dist, _) = g.longestPath(source)
  result = -Inf
  for d in dist:
    if d > result:
      result = d

#=======================================================================================================================
#== DOMINATOR TREE =====================================================================================================
#=======================================================================================================================

proc dominatorTree*(g: Graph, entry: NodeId): seq[system.int] =
  ## Compute the dominator tree of a directed graph using the iterative data-flow algorithm.
  ## Returns idom array: idom[i] = immediate dominator of node i. idom[entry] = entry.
  ## idom[i] = -1 if node i is unreachable from entry.
  let n = g.nodeCount
  # Compute reverse postorder via DFS from entry.
  var visited: seq[bool]
  visited.setLen(n)
  var rpo: seq[NodeId]

  proc dfs(v: system.int) =
    visited[v] = true
    for e in g.neighbors(NodeId(v)):
      if not visited[e.target.int]:
        dfs(e.target.int)
    rpo.add(NodeId(v))

  dfs(entry.int)

  # Reverse to get reverse postorder.
  var rpoReversed: seq[NodeId]
  for i in countdown(rpo.len - 1, 0):
    rpoReversed.add(rpo[i])

  # Map node -> rpo index.
  var rpoIdx: seq[system.int]
  rpoIdx.setLen(n)
  for i in 0 ..< n:
    rpoIdx[i] = -1
  for i in 0 ..< rpoReversed.len:
    rpoIdx[rpoReversed[i].int] = i

  # Build predecessor lists.
  var preds: seq[seq[system.int]]
  preds.setLen(n)
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      preds[e.target.int].add(i)

  # Initialize idom.
  var idom: seq[system.int]
  idom.setLen(n)
  for i in 0 ..< n:
    idom[i] = -1
  idom[entry.int] = entry.int

  proc intersect(b1, b2: system.int): system.int =
    var finger1 = b1
    var finger2 = b2
    while finger1 != finger2:
      while rpoIdx[finger1] > rpoIdx[finger2]:
        finger1 = idom[finger1]
      while rpoIdx[finger2] > rpoIdx[finger1]:
        finger2 = idom[finger2]
    finger1

  # Iterate until stable.
  var changed = true
  while changed:
    changed = false
    for idx in 0 ..< rpoReversed.len:
      let b = rpoReversed[idx].int
      if b == entry.int:
        continue
      var newIdom = -1
      for p in preds[b]:
        if idom[p] != -1:
          if newIdom == -1:
            newIdom = p
          else:
            newIdom = intersect(newIdom, p)
      if newIdom != -1 and newIdom != idom[b]:
        idom[b] = newIdom
        changed = true
  result = idom
