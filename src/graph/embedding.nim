#[
=========
Embedding
=========

Node2Vec: random walk generation for graph embedding.
Outputs random walks; embedding (skip-gram) is deferred to external tools.
]#

{.push raises: [Defect].}

# std...
import std/math
import std/random

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== NODE2VEC RANDOM WALKS ==============================================================================================
#=======================================================================================================================

proc node2vecWalk*(g: Graph, start: NodeId, walkLength: system.int,
                   p: float = 1.0, q: float = 1.0, rng: var Rand): seq[NodeId] =
  ## Generate a single Node2Vec biased random walk.
  ## p controls return parameter (lower = more likely to return).
  ## q controls in-out parameter (lower = BFS-like, higher = DFS-like).
  result.add(start)
  if g.degree(start) == 0:
    return

  # First step: uniform random neighbor.
  let nbrs = g.neighbors(start)
  let firstIdx = rng.rand(nbrs.len - 1)
  result.add(nbrs[firstIdx].target)

  for step in 2 ..< walkLength:
    let cur = result[^1]
    let prev = result[^2]
    let curNbrs = g.neighbors(cur)
    if curNbrs.len == 0:
      break

    # Compute unnormalized transition probabilities.
    var weights: seq[float]
    weights.setLen(curNbrs.len)
    var totalWeight = 0.0
    for i in 0 ..< curNbrs.len:
      let next = curNbrs[i].target
      if next == prev:
        weights[i] = curNbrs[i].weight / p
      elif g.hasEdge(prev, next):
        weights[i] = curNbrs[i].weight
      else:
        weights[i] = curNbrs[i].weight / q
      totalWeight += weights[i]

    # Sample proportional to weights.
    var r = rng.rand(totalWeight)
    var chosen = curNbrs.len - 1
    for i in 0 ..< curNbrs.len:
      r -= weights[i]
      if r <= 0.0:
        chosen = i
        break

    result.add(curNbrs[chosen].target)

proc node2vecWalks*(g: Graph, numWalks: system.int = 10, walkLength: system.int = 80,
                    p: float = 1.0, q: float = 1.0, seed: system.int = 42): seq[seq[NodeId]] =
  ## Generate Node2Vec random walks for all nodes.
  var rng = initRand(seed)
  for walk in 0 ..< numWalks:
    for i in 0 ..< g.nodeCount:
      result.add(g.node2vecWalk(NodeId(i), walkLength, p, q, rng))
