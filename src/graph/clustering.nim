#[
==========
Clustering
==========

Clustering coefficient and triangle counting.
]#

{.push raises: [Defect].}

# std...
import std/sets

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== TRIANGLE COUNTING ==================================================================================================
#=======================================================================================================================

proc triangleCount*(g: Graph): system.int =
  ## Count the number of triangles in an undirected graph.
  let n = g.nodeCount
  for u in 0 ..< n:
    var neighbors = initHashSet[system.int]()
    for e in g.neighbors(NodeId(u)):
      neighbors.incl(e.target.int)
    for e in g.neighbors(NodeId(u)):
      let v = e.target.int
      if v > u:
        for e2 in g.neighbors(NodeId(v)):
          let w = e2.target.int
          if w > v and w in neighbors:
            result += 1

#=======================================================================================================================
#== CLUSTERING COEFFICIENT =============================================================================================
#=======================================================================================================================

proc localClusteringCoefficient*(g: Graph, node: NodeId): float =
  ## Local clustering coefficient for a single node.
  let deg = g.degree(node)
  if deg < 2:
    return 0.0
  var neighbors = initHashSet[system.int]()
  for e in g.neighbors(node):
    neighbors.incl(e.target.int)
  var triangles = 0
  for e in g.neighbors(node):
    let u = e.target.int
    for e2 in g.neighbors(NodeId(u)):
      if e2.target.int in neighbors and e2.target.int != node.int:
        triangles += 1
  if g.kind == gkUndirected:
    triangles = triangles div 2
  triangles.float / (deg * (deg - 1) div 2).float

proc averageClusteringCoefficient*(g: Graph): float =
  ## Average clustering coefficient over all nodes.
  let n = g.nodeCount
  if n == 0:
    return 0.0
  var total = 0.0
  for i in 0 ..< n:
    total += g.localClusteringCoefficient(NodeId(i))
  total / n.float

proc globalClusteringCoefficient*(g: Graph): float =
  ## Global clustering coefficient: 3 * triangles / connected triples.
  let n = g.nodeCount
  var triples = 0
  for i in 0 ..< n:
    let d = g.degree(NodeId(i))
    if d >= 2:
      triples += d * (d - 1) div 2
  if triples == 0:
    return 0.0
  let tri = g.triangleCount()
  (3 * tri).float / triples.float
