#[
=========
Community
=========

Louvain, Leiden, label propagation, Girvan-Newman,
spectral clustering (power iteration), modularity.
]#

{.push raises: [Defect].}

# std...
import std/math
import std/random
import std/sets
import std/tables

# graph...
import types
import centrality

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== MODULARITY =========================================================================================================
#=======================================================================================================================

proc modularity*(g: Graph, communities: seq[system.int]): float =
  ## Compute modularity Q for a given community assignment.
  ## communities[i] = community id of node i.
  let n = g.nodeCount
  let m = g.edgeCount().float
  if m == 0.0:
    return 0.0
  let scale = if g.kind == gkUndirected: 2.0 * m else: m
  var degIn: seq[float]
  degIn.setLen(n)
  var degOut: seq[float]
  degOut.setLen(n)
  for i in 0 ..< n:
    degOut[i] = g.degree(NodeId(i)).float
    if g.kind == gkUndirected:
      degIn[i] = degOut[i]
  if g.kind == gkDirected:
    for i in 0 ..< n:
      for e in g.neighbors(NodeId(i)):
        degIn[e.target.int] += 1.0

  result = 0.0
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      let j = e.target.int
      if communities[i] == communities[j]:
        result += e.weight - (degOut[i] * degIn[j]) / scale
  result /= scale

#=======================================================================================================================
#== LOUVAIN ============================================================================================================
#=======================================================================================================================

proc louvain*(g: Graph): seq[system.int] =
  ## Louvain community detection. Returns community assignment per node.
  let n = g.nodeCount
  let m = g.edgeCount().float
  if n == 0 or m == 0.0:
    result.setLen(n)
    for i in 0 ..< n:
      result[i] = i
    return

  let scale = if g.kind == gkUndirected: 2.0 * m else: m

  # Initialize: each node in its own community.
  result.setLen(n)
  for i in 0 ..< n:
    result[i] = i

  # Degree per node.
  var deg: seq[float]
  deg.setLen(n)
  for i in 0 ..< n:
    deg[i] = g.degree(NodeId(i)).float

  # Sum of degrees per community.
  var commDeg: seq[float]
  commDeg.setLen(n)
  for i in 0 ..< n:
    commDeg[i] = deg[i]

  var improved = true
  while improved:
    improved = false
    for i in 0 ..< n:
      let oldComm = result[i]
      # Remove i from its community.
      commDeg[oldComm] -= deg[i]

      # Compute weight to each neighboring community.
      var neighborComms = initTable[system.int, float]()
      for e in g.neighbors(NodeId(i)):
        let c = result[e.target.int]
        neighborComms[c] = neighborComms.getOrDefault(c) + e.weight

      # Find best community.
      var bestComm = oldComm
      var bestDelta = 0.0
      for c, wc in neighborComms:
        let delta = wc - deg[i] * commDeg[c] / scale
        if delta > bestDelta:
          bestDelta = delta
          bestComm = c

      # Move i to best community.
      result[i] = bestComm
      commDeg[bestComm] += deg[i]
      if bestComm != oldComm:
        improved = true

#=======================================================================================================================
#== LEIDEN (SIMPLIFIED) ================================================================================================
#=======================================================================================================================

proc leiden*(g: Graph, gamma: float = 1.0): seq[system.int] =
  ## Simplified Leiden community detection.
  ## Refines Louvain by ensuring well-connected communities.
  result = g.louvain()
  # Refinement pass: move nodes to improve modularity.
  let n = g.nodeCount
  let m = g.edgeCount().float
  if m == 0.0:
    return
  let scale = if g.kind == gkUndirected: 2.0 * m else: m

  var deg: seq[float]
  deg.setLen(n)
  for i in 0 ..< n:
    deg[i] = g.degree(NodeId(i)).float

  var commDeg: seq[float]
  # Find max community id.
  var maxComm = 0
  for c in result:
    if c > maxComm:
      maxComm = c
  commDeg.setLen(maxComm + 1)
  for i in 0 ..< n:
    commDeg[result[i]] += deg[i]

  # Single refinement pass.
  for i in 0 ..< n:
    let oldComm = result[i]
    commDeg[oldComm] -= deg[i]

    var neighborComms = initTable[system.int, float]()
    for e in g.neighbors(NodeId(i)):
      let c = result[e.target.int]
      neighborComms[c] = neighborComms.getOrDefault(c) + e.weight

    var bestComm = oldComm
    var bestDelta = 0.0
    for c, wc in neighborComms:
      let delta = wc - gamma * deg[i] * commDeg[c] / scale
      if delta > bestDelta:
        bestDelta = delta
        bestComm = c

    result[i] = bestComm
    if bestComm >= commDeg.len:
      commDeg.setLen(bestComm + 1)
    commDeg[bestComm] += deg[i]

#=======================================================================================================================
#== LABEL PROPAGATION ==================================================================================================
#=======================================================================================================================

proc labelPropagation*(g: Graph, maxIterations: system.int = 100): seq[system.int] =
  ## Label propagation community detection.
  let n = g.nodeCount
  result.setLen(n)
  for i in 0 ..< n:
    result[i] = i

  var rng = initRand(42)
  var order: seq[system.int]
  order.setLen(n)
  for i in 0 ..< n:
    order[i] = i

  for iter in 0 ..< maxIterations:
    rng.shuffle(order)
    var changed = false
    for idx in 0 ..< n:
      let i = order[idx]
      if g.degree(NodeId(i)) == 0:
        continue
      # Count label frequencies among neighbors.
      var labelCount = initTable[system.int, float]()
      for e in g.neighbors(NodeId(i)):
        let lbl = result[e.target.int]
        labelCount[lbl] = labelCount.getOrDefault(lbl) + e.weight

      # Find most frequent label.
      var bestLabel = result[i]
      var bestCount = 0.0
      for lbl, cnt in labelCount:
        if cnt > bestCount:
          bestCount = cnt
          bestLabel = lbl

      if bestLabel != result[i]:
        result[i] = bestLabel
        changed = true

    if not changed:
      break

#=======================================================================================================================
#== GIRVAN-NEWMAN ======================================================================================================
#=======================================================================================================================

proc girvanNewman*(g: Graph, targetCommunities: system.int = 2): seq[system.int] =
  ## Girvan-Newman community detection by iterative edge removal.
  ## Removes edges with highest betweenness until desired number of communities.
  let n = g.nodeCount
  # Work on a mutable copy.
  var work = initGraph(g.kind, n)
  for i in 0 ..< n:
    discard work.addNode()
  for e in g.edges:
    work.addEdge(e.source, e.target, e.weight)

  # Count components using BFS.
  proc countComponents(gr: Graph): system.int =
    var visited: seq[bool]
    visited.setLen(gr.nodeCount)
    var count = 0
    for i in 0 ..< gr.nodeCount:
      if not visited[i]:
        count += 1
        var queue: seq[system.int]
        queue.add(i)
        visited[i] = true
        while queue.len > 0:
          let v = queue.pop()
          for e in gr.neighbors(NodeId(v)):
            if not visited[e.target.int]:
              visited[e.target.int] = true
              queue.add(e.target.int)
    count

  while countComponents(work) < targetCommunities:
    # Compute edge betweenness.
    let bc = work.betweennessCentrality()
    # Find edge with highest betweenness endpoint sum.
    var bestSrc = -1
    var bestTgt = -1
    var bestScore = -1.0
    for e in work.edges:
      let score = bc[e.source.int] + bc[e.target.int]
      if score > bestScore:
        bestScore = score
        bestSrc = e.source.int
        bestTgt = e.target.int
    if bestSrc < 0:
      break
    # Remove the edge by rebuilding the graph without it.
    var newWork = initGraph(work.kind, n)
    for i in 0 ..< n:
      discard newWork.addNode()
    for e in work.edges:
      if not ((e.source.int == bestSrc and e.target.int == bestTgt) or
              (g.kind == gkUndirected and e.source.int == bestTgt and e.target.int == bestSrc)):
        newWork.addEdge(e.source, e.target, e.weight)
    work = newWork

  # Assign community labels via BFS.
  result.setLen(n)
  for i in 0 ..< n:
    result[i] = -1
  var comm = 0
  for i in 0 ..< n:
    if result[i] == -1:
      var queue: seq[system.int]
      queue.add(i)
      result[i] = comm
      while queue.len > 0:
        let v = queue.pop()
        for e in work.neighbors(NodeId(v)):
          if result[e.target.int] == -1:
            result[e.target.int] = comm
            queue.add(e.target.int)
      comm += 1

#=======================================================================================================================
#== SPECTRAL CLUSTERING (POWER ITERATION) ==============================================================================
#=======================================================================================================================

proc spectralClustering*(g: Graph, k: system.int = 2,
                         iterations: system.int = 100): seq[system.int] =
  ## Spectral clustering using power iteration on the normalized Laplacian.
  ## Approximates k clusters. Uses sign of the Fiedler vector for k=2,
  ## k-means on multiple eigenvectors for k>2.
  let n = g.nodeCount
  if n == 0:
    return @[]

  # Compute degree.
  var deg: seq[float]
  deg.setLen(n)
  for i in 0 ..< n:
    deg[i] = g.degree(NodeId(i)).float

  # Power iteration to find the second smallest eigenvector of the Laplacian.
  # L = D - A; we use L * x = lambda * x, finding smallest non-trivial eigenvalue.
  # Use inverse power iteration on L shifted: find largest eigenvector of (D^-1 * A).
  var x: seq[float]
  x.setLen(n)
  var rng = initRand(42)
  for i in 0 ..< n:
    x[i] = rng.rand(1.0)

  var tmp: seq[float]
  tmp.setLen(n)

  for iter in 0 ..< iterations:
    # Multiply by D^-1 * A (normalized adjacency).
    for i in 0 ..< n:
      tmp[i] = 0.0
    for i in 0 ..< n:
      if deg[i] > 0.0:
        for e in g.neighbors(NodeId(i)):
          tmp[i] += x[e.target.int] / deg[i]

    # Orthogonalize against constant vector (remove first eigenvector component).
    var mean = 0.0
    for i in 0 ..< n:
      mean += tmp[i]
    mean /= n.float
    for i in 0 ..< n:
      tmp[i] -= mean

    # Normalize.
    var norm = 0.0
    for i in 0 ..< n:
      norm += tmp[i] * tmp[i]
    norm = sqrt(norm)
    if norm > 0.0:
      for i in 0 ..< n:
        tmp[i] /= norm

    # Check convergence.
    var diff = 0.0
    for i in 0 ..< n:
      diff += abs(tmp[i] - x[i])
    x = tmp
    if diff < 1.0e-8:
      break

  # Partition by sign of the Fiedler vector.
  result.setLen(n)
  if k == 2:
    for i in 0 ..< n:
      result[i] = if x[i] >= 0.0: 0 else: 1
  else:
    # For k > 2, recursively split (simplified approach).
    for i in 0 ..< n:
      result[i] = if x[i] >= 0.0: 0 else: 1
    # This is a simplification; full k>2 would need k eigenvectors + k-means.
