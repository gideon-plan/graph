#[
==========
Generation
==========

Erdos-Renyi, Barabasi-Albert, random walk graph generation.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/random

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== ERDOS-RENYI ========================================================================================================
#=======================================================================================================================

proc erdosRenyi*(n: system.int, p: float, kind: GraphKind = GraphKind.Undirected,
                 seed: system.int = 42): Graph =
  ## Generate an Erdos-Renyi random graph G(n, p).
  ## Each edge exists independently with probability p.
  result = initGraph(kind, n)
  for i in 0 ..< n:
    discard result.addNode()
  var rng = initRand(seed)
  if kind == GraphKind.Undirected:
    for i in 0 ..< n:
      for j in i + 1 ..< n:
        if rng.rand(1.0) < p:
          result.addEdge(NodeId(i), NodeId(j))
  else:
    for i in 0 ..< n:
      for j in 0 ..< n:
        if i != j and rng.rand(1.0) < p:
          result.addEdge(NodeId(i), NodeId(j))

#=======================================================================================================================
#== BARABASI-ALBERT ====================================================================================================
#=======================================================================================================================

proc barabasiAlbert*(n, m: system.int, seed: system.int = 42): Graph =
  ## Generate a Barabasi-Albert preferential attachment graph.
  ## Start with m+1 nodes in a clique, then add n-(m+1) nodes each with m edges.
  let startNodes = m + 1
  if n <= startNodes:
    result = initGraph(GraphKind.Undirected, n)
    for i in 0 ..< n:
      discard result.addNode()
    for i in 0 ..< n:
      for j in i + 1 ..< n:
        result.addEdge(NodeId(i), NodeId(j))
    return

  result = initGraph(GraphKind.Undirected, n)
  for i in 0 ..< n:
    discard result.addNode()
  # Initial clique.
  for i in 0 ..< startNodes:
    for j in i + 1 ..< startNodes:
      result.addEdge(NodeId(i), NodeId(j))

  var rng = initRand(seed)
  # Repeated edges list for preferential attachment sampling.
  var targets: seq[system.int]
  for i in 0 ..< startNodes:
    for j in i + 1 ..< startNodes:
      targets.add(i)
      targets.add(j)

  for newNode in startNodes ..< n:
    # Select m distinct targets proportional to degree.
    var chosen: seq[system.int]
    for attempt in 0 ..< m:
      if targets.len == 0:
        break
      var t = targets[rng.rand(targets.len - 1)]
      # Avoid duplicates.
      var isDup = false
      for c in chosen:
        if c == t:
          isDup = true
          break
      if isDup:
        continue
      chosen.add(t)

    for t in chosen:
      result.addEdge(NodeId(newNode), NodeId(t))
      targets.add(newNode)
      targets.add(t)

#=======================================================================================================================
#== RANDOM WALK GRAPH ==================================================================================================
#=======================================================================================================================

proc randomWalkGraph*(n, steps: system.int, seed: system.int = 42): Graph =
  ## Generate a graph by random walk: start at node 0, at each step
  ## either visit a random neighbor or jump to a random new node.
  result = initGraph(GraphKind.Undirected, n)
  for i in 0 ..< n:
    discard result.addNode()
  if n <= 1:
    return

  var rng = initRand(seed)
  var current = 0
  for step in 0 ..< steps:
    let next = rng.rand(n - 1)
    if next != current:
      if not result.hasEdge(NodeId(current), NodeId(next)):
        result.addEdge(NodeId(current), NodeId(next))
      current = next
