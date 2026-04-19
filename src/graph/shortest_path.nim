#[
=============
Shortest Path
=============

Dijkstra, Bellman-Ford, A*, bidirectional Dijkstra, Floyd-Warshall, Johnson's APSP.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/heapqueue

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== CONSTANTS ==========================================================================================================
#=======================================================================================================================

const InfDist* = float.high
  ## Sentinel for unreachable distance.

#=======================================================================================================================
#== DIJKSTRA ===========================================================================================================
#=======================================================================================================================

type
  DijkstraEntry = object
    dist: float
    node: NodeId

proc `<`(a, b: DijkstraEntry): bool = a.dist < b.dist

proc dijkstra*(g: Graph, source: NodeId): (seq[float], seq[int]) =
  ## Single-source shortest paths from `source` using Dijkstra's algorithm.
  ## Returns (distances, predecessors). Predecessors[i] = -1 if unreachable.
  ## Requires non-negative weights.
  let n = g.nodeCount
  var dist: seq[float]
  dist.setLen(n)
  var pred: seq[int]
  pred.setLen(n)
  for i in 0 ..< n:
    dist[i] = InfDist
    pred[i] = -1
  dist[source.int] = 0.0
  pred[source.int] = source.int
  var pq = initHeapQueue[DijkstraEntry]()
  pq.push(DijkstraEntry(dist: 0.0, node: source))
  while pq.len > 0:
    let cur = pq.pop()
    if cur.dist > dist[cur.node.int]:
      continue
    for e in g.neighbors(cur.node):
      let newDist = dist[cur.node.int] + e.weight
      if newDist < dist[e.target.int]:
        dist[e.target.int] = newDist
        pred[e.target.int] = cur.node.int
        pq.push(DijkstraEntry(dist: newDist, node: e.target))
  (dist, pred)

proc dijkstraPath*(g: Graph, source, target: NodeId): (float, seq[NodeId]) =
  ## Shortest path from `source` to `target`. Returns (distance, path).
  ## Path is empty if unreachable.
  let (dist, pred) = g.dijkstra(source)
  if dist[target.int] == InfDist:
    return (InfDist, @[])
  var path: seq[NodeId]
  var cur = target.int
  while cur != source.int:
    path.add(NodeId(cur))
    cur = pred[cur]
  path.add(source)
  var reversed: seq[NodeId]
  for i in countdown(path.len - 1, 0):
    reversed.add(path[i])
  (dist[target.int], reversed)

#=======================================================================================================================
#== BELLMAN-FORD =======================================================================================================
#=======================================================================================================================

proc bellmanFord*(g: Graph, source: NodeId): (seq[float], seq[int], bool) =
  ## Single-source shortest paths using Bellman-Ford.
  ## Returns (distances, predecessors, hasNegativeCycle).
  let n = g.nodeCount
  var dist: seq[float]
  dist.setLen(n)
  var pred: seq[int]
  pred.setLen(n)
  for i in 0 ..< n:
    dist[i] = InfDist
    pred[i] = -1
  dist[source.int] = 0.0
  pred[source.int] = source.int

  for iteration in 0 ..< n - 1:
    var updated = false
    for i in 0 ..< n:
      if dist[i] == InfDist:
        continue
      for e in g.neighbors(NodeId(i)):
        let newDist = dist[i] + e.weight
        if newDist < dist[e.target.int]:
          dist[e.target.int] = newDist
          pred[e.target.int] = i
          updated = true
    if not updated:
      break

  var hasNegCycle = false
  for i in 0 ..< n:
    if dist[i] == InfDist:
      continue
    for e in g.neighbors(NodeId(i)):
      if dist[i] + e.weight < dist[e.target.int]:
        hasNegCycle = true
        break
    if hasNegCycle:
      break

  (dist, pred, hasNegCycle)

#=======================================================================================================================
#== A* =================================================================================================================
#=======================================================================================================================

type
  Heuristic* = proc(node, target: NodeId): float {.noSideEffect, raises: [].}
    ## Heuristic function for A*. Must be admissible (never overestimates).

  AStarEntry = object
    fScore: float
    node: NodeId

proc `<`(a, b: AStarEntry): bool = a.fScore < b.fScore

proc aStar*(g: Graph, source, target: NodeId, h: Heuristic): (float, seq[NodeId]) =
  ## A* shortest path from `source` to `target` with heuristic `h`.
  ## Returns (distance, path). Path is empty if unreachable.
  let n = g.nodeCount
  var gScore: seq[float]
  gScore.setLen(n)
  var pred: seq[int]
  pred.setLen(n)
  var closed: seq[bool]
  closed.setLen(n)
  for i in 0 ..< n:
    gScore[i] = InfDist
    pred[i] = -1
  gScore[source.int] = 0.0
  pred[source.int] = source.int

  var pq = initHeapQueue[AStarEntry]()
  pq.push(AStarEntry(fScore: h(source, target), node: source))

  while pq.len > 0:
    let cur = pq.pop()
    if cur.node == target:
      var path: seq[NodeId]
      var c = target.int
      while c != source.int:
        path.add(NodeId(c))
        c = pred[c]
      path.add(source)
      var reversed: seq[NodeId]
      for i in countdown(path.len - 1, 0):
        reversed.add(path[i])
      return (gScore[target.int], reversed)

    if closed[cur.node.int]:
      continue
    closed[cur.node.int] = true

    for e in g.neighbors(cur.node):
      if closed[e.target.int]:
        continue
      let tentative = gScore[cur.node.int] + e.weight
      if tentative < gScore[e.target.int]:
        gScore[e.target.int] = tentative
        pred[e.target.int] = cur.node.int
        pq.push(AStarEntry(fScore: tentative + h(e.target, target), node: e.target))

  (InfDist, @[])

#=======================================================================================================================
#== BIDIRECTIONAL DIJKSTRA =============================================================================================
#=======================================================================================================================

proc bidirectionalDijkstra*(g: Graph, source, target: NodeId): (float, seq[NodeId]) =
  ## Bidirectional Dijkstra for undirected or symmetric directed graphs.
  ## Returns (distance, path). Path is empty if unreachable.
  let n = g.nodeCount
  var distF, distR: seq[float]
  distF.setLen(n)
  distR.setLen(n)
  var predF, predR: seq[int]
  predF.setLen(n)
  predR.setLen(n)
  var visitedF, visitedR: seq[bool]
  visitedF.setLen(n)
  visitedR.setLen(n)
  for i in 0 ..< n:
    distF[i] = InfDist
    distR[i] = InfDist
    predF[i] = -1
    predR[i] = -1
  distF[source.int] = 0.0
  distR[target.int] = 0.0
  predF[source.int] = source.int
  predR[target.int] = target.int

  var pqF = initHeapQueue[DijkstraEntry]()
  var pqR = initHeapQueue[DijkstraEntry]()
  pqF.push(DijkstraEntry(dist: 0.0, node: source))
  pqR.push(DijkstraEntry(dist: 0.0, node: target))

  var mu = InfDist
  var meetNode = -1

  while pqF.len > 0 or pqR.len > 0:
    # Forward step.
    if pqF.len > 0:
      let cur = pqF.pop()
      if cur.dist <= mu:
        visitedF[cur.node.int] = true
        if cur.dist <= distF[cur.node.int]:
          for e in g.neighbors(cur.node):
            let newDist = distF[cur.node.int] + e.weight
            if newDist < distF[e.target.int]:
              distF[e.target.int] = newDist
              predF[e.target.int] = cur.node.int
              pqF.push(DijkstraEntry(dist: newDist, node: e.target))
            if visitedR[e.target.int]:
              let total = distF[cur.node.int] + e.weight + distR[e.target.int]
              if total < mu:
                mu = total
                meetNode = e.target.int

    # Reverse step.
    if pqR.len > 0:
      let cur = pqR.pop()
      if cur.dist <= mu:
        visitedR[cur.node.int] = true
        if cur.dist <= distR[cur.node.int]:
          for e in g.neighbors(cur.node):
            let newDist = distR[cur.node.int] + e.weight
            if newDist < distR[e.target.int]:
              distR[e.target.int] = newDist
              predR[e.target.int] = cur.node.int
              pqR.push(DijkstraEntry(dist: newDist, node: e.target))
            if visitedF[e.target.int]:
              let total = distR[cur.node.int] + e.weight + distF[e.target.int]
              if total < mu:
                mu = total
                meetNode = e.target.int

    # Termination check.
    var minF = InfDist
    var minR = InfDist
    if pqF.len > 0:
      minF = pqF[0].dist
    if pqR.len > 0:
      minR = pqR[0].dist
    if minF + minR >= mu:
      break

  if meetNode == -1:
    return (InfDist, @[])

  # Reconstruct path: source -> meetNode via predF, meetNode -> target via predR.
  var pathF: seq[NodeId]
  var cur = meetNode
  while cur != source.int:
    pathF.add(NodeId(cur))
    cur = predF[cur]
  pathF.add(source)
  var path: seq[NodeId]
  for i in countdown(pathF.len - 1, 0):
    path.add(pathF[i])
  # Follow reverse path (skip meetNode).
  cur = predR[meetNode]
  while cur != target.int:
    path.add(NodeId(cur))
    cur = predR[cur]
  path.add(target)
  (mu, path)

#=======================================================================================================================
#== FLOYD-WARSHALL =====================================================================================================
#=======================================================================================================================

proc floydWarshall*(g: Graph): (seq[seq[float]], seq[seq[int]]) =
  ## All-pairs shortest paths using Floyd-Warshall.
  ## Returns (distance matrix, next-hop matrix).
  let n = g.nodeCount
  var dist: seq[seq[float]]
  dist.setLen(n)
  var next: seq[seq[int]]
  next.setLen(n)
  for i in 0 ..< n:
    dist[i].setLen(n)
    next[i].setLen(n)
    for j in 0 ..< n:
      if i == j:
        dist[i][j] = 0.0
      else:
        dist[i][j] = InfDist
      next[i][j] = -1

  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      if e.weight < dist[i][e.target.int]:
        dist[i][e.target.int] = e.weight
        next[i][e.target.int] = e.target.int

  for k in 0 ..< n:
    for i in 0 ..< n:
      if dist[i][k] == InfDist:
        continue
      for j in 0 ..< n:
        if dist[k][j] == InfDist:
          continue
        let through = dist[i][k] + dist[k][j]
        if through < dist[i][j]:
          dist[i][j] = through
          next[i][j] = next[i][k]

  (dist, next)

proc floydWarshallPath*(next: seq[seq[int]], source, target: int): seq[NodeId] =
  ## Reconstruct shortest path from Floyd-Warshall next-hop matrix.
  if next[source][target] == -1:
    return @[]
  result.add(NodeId(source))
  var cur = source
  while cur != target:
    cur = next[cur][target]
    result.add(NodeId(cur))

#=======================================================================================================================
#== JOHNSON'S APSP ====================================================================================================
#=======================================================================================================================

proc johnson*(g: Graph): (seq[seq[float]], bool) =
  ## All-pairs shortest paths using Johnson's algorithm.
  ## Handles negative weights. Returns (distance matrix, hasNegativeCycle).
  let n = g.nodeCount
  var augmented = initGraph(GraphKind.Directed, n + 1)
  for i in 0 ..< n + 1:
    discard augmented.addNode()
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      augmented.addEdge(NodeId(i), e.target, e.weight)
  let virt = NodeId(n)
  for i in 0 ..< n:
    augmented.addEdge(virt, NodeId(i), 0.0)

  let (h, _, hasNegCycle) = augmented.bellmanFord(virt)
  if hasNegCycle:
    var empty: seq[seq[float]]
    return (empty, true)

  var reweighted = initGraph(GraphKind.Directed, n)
  for i in 0 ..< n:
    discard reweighted.addNode()
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      let newWeight = e.weight + h[i] - h[e.target.int]
      reweighted.addEdge(NodeId(i), e.target, newWeight)

  var dist: seq[seq[float]]
  dist.setLen(n)
  for i in 0 ..< n:
    let (d, _) = reweighted.dijkstra(NodeId(i))
    dist[i].setLen(n)
    for j in 0 ..< n:
      if d[j] == InfDist:
        dist[i][j] = InfDist
      else:
        dist[i][j] = d[j] - h[i] + h[j]
  (dist, false)
