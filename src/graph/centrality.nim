#[
==========
Centrality
==========

PageRank, betweenness, closeness, degree distribution,
eigenvector, Katz, harmonic, HITS.
]#

{.push raises: [Defect].}

# std...
import std/deques
import std/math
import std/tables

# graph...
import types
import shortest_path

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== DEGREE DISTRIBUTION ================================================================================================
#=======================================================================================================================

proc degreeDistribution*(g: Graph): Table[system.int, system.int] =
  ## Return degree distribution: degree -> count.
  for i in 0 ..< g.nodeCount:
    let d = g.degree(NodeId(i))
    result[d] = result.getOrDefault(d) + 1

#=======================================================================================================================
#== PAGERANK ===========================================================================================================
#=======================================================================================================================

proc pageRank*(g: Graph, damping: float = 0.85, iterations: system.int = 100,
               tolerance: float = 1.0e-6): seq[float] =
  ## PageRank centrality. Returns score per node.
  let n = g.nodeCount
  if n == 0:
    return @[]
  let initial = 1.0 / n.float
  result.setLen(n)
  for i in 0 ..< n:
    result[i] = initial

  var newRank: seq[float]
  newRank.setLen(n)

  for iter in 0 ..< iterations:
    let base = (1.0 - damping) / n.float
    for i in 0 ..< n:
      newRank[i] = base

    for i in 0 ..< n:
      let deg = g.degree(NodeId(i))
      if deg > 0:
        let share = result[i] / deg.float
        for e in g.neighbors(NodeId(i)):
          newRank[e.target.int] += damping * share

    # Check convergence.
    var diff = 0.0
    for i in 0 ..< n:
      diff += abs(newRank[i] - result[i])
    for i in 0 ..< n:
      result[i] = newRank[i]
    if diff < tolerance:
      break

#=======================================================================================================================
#== BETWEENNESS CENTRALITY =============================================================================================
#=======================================================================================================================

proc betweennessCentrality*(g: Graph): seq[float] =
  ## Betweenness centrality using Brandes' algorithm.
  let n = g.nodeCount
  result.setLen(n)

  for s in 0 ..< n:
    var stack: seq[system.int]
    var predecessors: seq[seq[system.int]]
    predecessors.setLen(n)
    var sigma: seq[float]
    sigma.setLen(n)
    sigma[s] = 1.0
    var dist: seq[system.int]
    dist.setLen(n)
    for i in 0 ..< n:
      dist[i] = -1
    dist[s] = 0

    var queue = initDeque[system.int]()
    queue.addLast(s)
    while queue.len > 0:
      let v = queue.popFirst()
      stack.add(v)
      for e in g.neighbors(NodeId(v)):
        let w = e.target.int
        if dist[w] < 0:
          queue.addLast(w)
          dist[w] = dist[v] + 1
        if dist[w] == dist[v] + 1:
          sigma[w] += sigma[v]
          predecessors[w].add(v)

    var delta: seq[float]
    delta.setLen(n)
    while stack.len > 0:
      let w = stack.pop()
      for v in predecessors[w]:
        delta[v] += (sigma[v] / sigma[w]) * (1.0 + delta[w])
      if w != s:
        result[w] += delta[w]

  # For undirected graphs, divide by 2.
  if g.kind == gkUndirected:
    for i in 0 ..< n:
      result[i] /= 2.0

#=======================================================================================================================
#== CLOSENESS CENTRALITY ===============================================================================================
#=======================================================================================================================

proc closenessCentrality*(g: Graph): seq[float] =
  ## Closeness centrality: 1 / sum of shortest distances.
  ## For disconnected graphs, uses Wasserman-Faust normalization.
  let n = g.nodeCount
  result.setLen(n)
  for i in 0 ..< n:
    let (dist, _) = g.dijkstra(NodeId(i))
    var totalDist = 0.0
    var reachable = 0
    for j in 0 ..< n:
      if j != i and dist[j] != InfDist:
        totalDist += dist[j]
        reachable += 1
    if reachable > 0 and totalDist > 0.0:
      result[i] = reachable.float / totalDist

#=======================================================================================================================
#== EIGENVECTOR CENTRALITY =============================================================================================
#=======================================================================================================================

proc eigenvectorCentrality*(g: Graph, iterations: system.int = 100,
                            tolerance: float = 1.0e-6): seq[float] =
  ## Eigenvector centrality using power iteration.
  let n = g.nodeCount
  if n == 0:
    return @[]
  result.setLen(n)
  for i in 0 ..< n:
    result[i] = 1.0

  var tmp: seq[float]
  tmp.setLen(n)

  for iter in 0 ..< iterations:
    for i in 0 ..< n:
      tmp[i] = 0.0
    for i in 0 ..< n:
      for e in g.neighbors(NodeId(i)):
        tmp[e.target.int] += result[i]

    # Normalize.
    var norm = 0.0
    for i in 0 ..< n:
      norm += tmp[i] * tmp[i]
    norm = sqrt(norm)
    if norm == 0.0:
      break

    var diff = 0.0
    for i in 0 ..< n:
      let newVal = tmp[i] / norm
      diff += abs(newVal - result[i])
      result[i] = newVal
    if diff < tolerance:
      break

#=======================================================================================================================
#== KATZ CENTRALITY ====================================================================================================
#=======================================================================================================================

proc katzCentrality*(g: Graph, alpha: float = 0.1, beta: float = 1.0,
                     iterations: system.int = 100, tolerance: float = 1.0e-6): seq[float] =
  ## Katz centrality. alpha should be less than 1/lambda_max.
  let n = g.nodeCount
  if n == 0:
    return @[]
  result.setLen(n)
  for i in 0 ..< n:
    result[i] = 0.0

  var tmp: seq[float]
  tmp.setLen(n)

  for iter in 0 ..< iterations:
    for i in 0 ..< n:
      tmp[i] = beta
    for i in 0 ..< n:
      for e in g.neighbors(NodeId(i)):
        tmp[e.target.int] += alpha * result[i]

    var diff = 0.0
    for i in 0 ..< n:
      diff += abs(tmp[i] - result[i])
      result[i] = tmp[i]
    if diff < tolerance:
      break

#=======================================================================================================================
#== HARMONIC CENTRALITY ================================================================================================
#=======================================================================================================================

proc harmonicCentrality*(g: Graph): seq[float] =
  ## Harmonic centrality: sum of reciprocals of shortest distances.
  let n = g.nodeCount
  result.setLen(n)
  for i in 0 ..< n:
    let (dist, _) = g.dijkstra(NodeId(i))
    for j in 0 ..< n:
      if j != i and dist[j] != InfDist and dist[j] > 0.0:
        result[i] += 1.0 / dist[j]

#=======================================================================================================================
#== HITS (HUBS AND AUTHORITIES) ========================================================================================
#=======================================================================================================================

proc hits*(g: Graph, iterations: system.int = 100,
           tolerance: float = 1.0e-6): (seq[float], seq[float]) =
  ## HITS algorithm. Returns (hub scores, authority scores).
  let n = g.nodeCount
  if n == 0:
    return (@[], @[])
  var hub: seq[float]
  hub.setLen(n)
  var auth: seq[float]
  auth.setLen(n)
  for i in 0 ..< n:
    hub[i] = 1.0
    auth[i] = 1.0

  for iter in 0 ..< iterations:
    # Update authority scores.
    var newAuth: seq[float]
    newAuth.setLen(n)
    for i in 0 ..< n:
      for e in g.neighbors(NodeId(i)):
        newAuth[e.target.int] += hub[i]

    # Normalize authority.
    var norm = 0.0
    for i in 0 ..< n:
      norm += newAuth[i] * newAuth[i]
    norm = sqrt(norm)
    if norm > 0.0:
      for i in 0 ..< n:
        newAuth[i] /= norm

    # Update hub scores.
    var newHub: seq[float]
    newHub.setLen(n)
    for i in 0 ..< n:
      for e in g.neighbors(NodeId(i)):
        newHub[i] += newAuth[e.target.int]

    # Normalize hub.
    norm = 0.0
    for i in 0 ..< n:
      norm += newHub[i] * newHub[i]
    norm = sqrt(norm)
    if norm > 0.0:
      for i in 0 ..< n:
        newHub[i] /= norm

    # Check convergence.
    var diff = 0.0
    for i in 0 ..< n:
      diff += abs(newHub[i] - hub[i]) + abs(newAuth[i] - auth[i])
    hub = newHub
    auth = newAuth
    if diff < tolerance:
      break

  (hub, auth)
