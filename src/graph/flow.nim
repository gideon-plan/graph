#[
====
Flow
====

Edmonds-Karp max flow, push-relabel, Stoer-Wagner min-cut, min-cost max-flow.
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
#== EDMONDS-KARP (MAX FLOW) ============================================================================================
#=======================================================================================================================

proc edmondsKarp*(g: Graph, source, sink: NodeId): (float, seq[seq[float]]) =
  ## Edmonds-Karp max flow algorithm (BFS-based Ford-Fulkerson).
  ## Returns (max flow value, flow matrix).
  let n = g.nodeCount
  # Build capacity matrix.
  var cap: seq[seq[float]]
  cap.setLen(n)
  var flowMat: seq[seq[float]]
  flowMat.setLen(n)
  for i in 0 ..< n:
    cap[i].setLen(n)
    flowMat[i].setLen(n)
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      cap[i][e.target.int] += e.weight

  # Build adjacency list for residual graph.
  var adj: seq[seq[system.int]]
  adj.setLen(n)
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      adj[i].add(e.target.int)
      adj[e.target.int].add(i)  # Reverse edge for residual.

  var totalFlow = 0.0

  while true:
    # BFS to find augmenting path.
    var parent: seq[system.int]
    parent.setLen(n)
    for i in 0 ..< n:
      parent[i] = -1
    parent[source.int] = source.int
    var queue = initDeque[system.int]()
    queue.addLast(source.int)

    while queue.len > 0 and parent[sink.int] == -1:
      let u = queue.popFirst()
      for v in adj[u]:
        let residual = cap[u][v] - flowMat[u][v]
        if parent[v] == -1 and residual > 0.0:
          parent[v] = u
          queue.addLast(v)

    if parent[sink.int] == -1:
      break

    # Find bottleneck.
    var pathFlow = InfDist
    var v = sink.int
    while v != source.int:
      let u = parent[v]
      let residual = cap[u][v] - flowMat[u][v]
      if residual < pathFlow:
        pathFlow = residual
      v = u

    # Update flow.
    v = sink.int
    while v != source.int:
      let u = parent[v]
      flowMat[u][v] += pathFlow
      flowMat[v][u] -= pathFlow
      v = u
    totalFlow += pathFlow

  (totalFlow, flowMat)

#=======================================================================================================================
#== PUSH-RELABEL =======================================================================================================
#=======================================================================================================================

proc pushRelabel*(g: Graph, source, sink: NodeId): float =
  ## Push-relabel (preflow-push) max flow algorithm.
  let n = g.nodeCount
  var cap: seq[seq[float]]
  cap.setLen(n)
  var flowMat: seq[seq[float]]
  flowMat.setLen(n)
  for i in 0 ..< n:
    cap[i].setLen(n)
    flowMat[i].setLen(n)
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      cap[i][e.target.int] += e.weight

  var excess: seq[float]
  excess.setLen(n)
  var height: seq[system.int]
  height.setLen(n)
  height[source.int] = n

  # Initialize preflow.
  for e in g.neighbors(source):
    let c = cap[source.int][e.target.int]
    if c > 0.0:
      flowMat[source.int][e.target.int] = c
      flowMat[e.target.int][source.int] = -c
      excess[e.target.int] += c
      excess[source.int] -= c

  # Active node list (exclude source and sink).
  var active: seq[system.int]
  for i in 0 ..< n:
    if i != source.int and i != sink.int and excess[i] > 0.0:
      active.add(i)

  var idx = 0
  while idx < active.len:
    let u = active[idx]
    var pushed = false
    for v in 0 ..< n:
      let residual = cap[u][v] - flowMat[u][v]
      if residual > 0.0 and height[u] == height[v] + 1:
        let pushAmt = min(excess[u], residual)
        flowMat[u][v] += pushAmt
        flowMat[v][u] -= pushAmt
        excess[u] -= pushAmt
        excess[v] += pushAmt
        if v != source.int and v != sink.int and excess[v] > 0.0:
          var found = false
          for a in active:
            if a == v:
              found = true
              break
          if not found:
            active.add(v)
        pushed = true
        if excess[u] <= 0.0:
          break

    if excess[u] > 0.0 and not pushed:
      # Relabel.
      var minHeight = high(system.int)
      for v in 0 ..< n:
        if cap[u][v] - flowMat[u][v] > 0.0:
          if height[v] < minHeight:
            minHeight = height[v]
      height[u] = minHeight + 1

    if excess[u] <= 0.0:
      idx += 1
    else:
      # Restart scan for this node.
      discard

    # Safety: prevent infinite loops.
    if idx >= active.len:
      break

  excess[sink.int]

#=======================================================================================================================
#== STOER-WAGNER MIN-CUT ===============================================================================================
#=======================================================================================================================

proc stoerWagner*(g: Graph): (float, seq[NodeId]) =
  ## Stoer-Wagner minimum cut for undirected graphs.
  ## Returns (min cut weight, nodes on one side of the cut).
  let n = g.nodeCount
  if n <= 1:
    return (0.0, @[])

  # Build weight matrix.
  var w: seq[seq[float]]
  w.setLen(n)
  for i in 0 ..< n:
    w[i].setLen(n)
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      w[i][e.target.int] += e.weight

  var merged: seq[bool]
  merged.setLen(n)
  var mergedInto: seq[system.int]
  mergedInto.setLen(n)
  for i in 0 ..< n:
    mergedInto[i] = i

  var bestCut = InfDist
  var bestPartition: seq[NodeId]

  for phase in 0 ..< n - 1:
    var inA: seq[bool]
    inA.setLen(n)
    var tightness: seq[float]
    tightness.setLen(n)

    # Find first non-merged node.
    var start = -1
    for i in 0 ..< n:
      if not merged[i]:
        start = i
        break
    inA[start] = true

    var prev = start
    var last = start

    for step in 1 ..< n - phase:
      # Add the most tightly connected vertex.
      for i in 0 ..< n:
        if not merged[i] and not inA[i]:
          tightness[i] += w[last][i]

      var best = -1
      var bestW = -1.0
      for i in 0 ..< n:
        if not merged[i] and not inA[i]:
          if tightness[i] > bestW:
            bestW = tightness[i]
            best = i
      if best < 0:
        break
      prev = last
      last = best
      inA[last] = true

    # The cut of the last phase is the tightness of the last added vertex.
    let cutWeight = tightness[last]
    if cutWeight < bestCut:
      bestCut = cutWeight
      bestPartition = @[]
      # Collect all nodes merged into `last`.
      for i in 0 ..< n:
        if mergedInto[i] == last or i == last:
          if not merged[i] or i == last:
            bestPartition.add(NodeId(i))

    # Merge last into prev.
    for i in 0 ..< n:
      w[prev][i] += w[last][i]
      w[i][prev] += w[i][last]
    merged[last] = true
    for i in 0 ..< n:
      if mergedInto[i] == last:
        mergedInto[i] = prev

  (bestCut, bestPartition)

#=======================================================================================================================
#== MIN-COST MAX-FLOW ==================================================================================================
#=======================================================================================================================

proc minCostMaxFlow*(g: Graph, source, sink: NodeId,
                     costs: seq[seq[float]]): (float, float, seq[seq[float]]) =
  ## Min-cost max-flow using successive shortest paths (Bellman-Ford).
  ## `costs[i][j]` is the cost per unit of flow on edge (i, j).
  ## Returns (total flow, total cost, flow matrix).
  let n = g.nodeCount
  var cap: seq[seq[float]]
  cap.setLen(n)
  var cost: seq[seq[float]]
  cost.setLen(n)
  var flowMat: seq[seq[float]]
  flowMat.setLen(n)
  for i in 0 ..< n:
    cap[i].setLen(n)
    cost[i].setLen(n)
    flowMat[i].setLen(n)
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      cap[i][e.target.int] += e.weight
      cost[i][e.target.int] = costs[i][e.target.int]
      cost[e.target.int][i] = -costs[i][e.target.int]  # Reverse cost.

  var totalFlow = 0.0
  var totalCost = 0.0

  while true:
    # Find shortest path in residual graph using Bellman-Ford.
    var dist: seq[float]
    dist.setLen(n)
    var parent: seq[system.int]
    parent.setLen(n)
    for i in 0 ..< n:
      dist[i] = InfDist
      parent[i] = -1
    dist[source.int] = 0.0

    for iter in 0 ..< n - 1:
      var updated = false
      for u in 0 ..< n:
        if dist[u] == InfDist:
          continue
        for v in 0 ..< n:
          let residual = cap[u][v] - flowMat[u][v]
          if residual > 0.0:
            let newDist = dist[u] + cost[u][v]
            if newDist < dist[v]:
              dist[v] = newDist
              parent[v] = u
              updated = true
      if not updated:
        break

    if dist[sink.int] == InfDist:
      break

    # Find bottleneck.
    var pathFlow = InfDist
    var v = sink.int
    while v != source.int:
      let u = parent[v]
      let residual = cap[u][v] - flowMat[u][v]
      if residual < pathFlow:
        pathFlow = residual
      v = u

    # Update flow.
    v = sink.int
    while v != source.int:
      let u = parent[v]
      flowMat[u][v] += pathFlow
      flowMat[v][u] -= pathFlow
      totalCost += pathFlow * cost[u][v]
      v = u
    totalFlow += pathFlow

  (totalFlow, totalCost, flowMat)
