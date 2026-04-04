#[
========
Distance
========

Diameter and eccentricity.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/deques

# graph...
import types
import shortest_path

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== ECCENTRICITY =======================================================================================================
#=======================================================================================================================

proc eccentricity*(g: Graph, node: NodeId): float =
  ## Eccentricity of a node: maximum shortest-path distance to any other reachable node.
  ## Uses BFS for unweighted graphs, Dijkstra for weighted.
  ## Returns 0 for isolated nodes.
  let (dist, _) = g.dijkstra(node)
  result = 0.0
  for i in 0 ..< g.nodeCount:
    if dist[i] != InfDist and dist[i] > result:
      result = dist[i]

#=======================================================================================================================
#== DIAMETER ===========================================================================================================
#=======================================================================================================================

proc diameter*(g: Graph): float =
  ## Diameter of the graph: maximum eccentricity over all nodes.
  ## Only considers reachable pairs.
  result = 0.0
  for i in 0 ..< g.nodeCount:
    let ecc = g.eccentricity(NodeId(i))
    if ecc > result:
      result = ecc

#=======================================================================================================================
#== RADIUS =============================================================================================================
#=======================================================================================================================

proc radius*(g: Graph): float =
  ## Radius of the graph: minimum eccentricity over all nodes.
  if g.nodeCount == 0:
    return 0.0
  result = InfDist
  for i in 0 ..< g.nodeCount:
    let ecc = g.eccentricity(NodeId(i))
    if ecc < result:
      result = ecc

#=======================================================================================================================
#== CENTER =============================================================================================================
#=======================================================================================================================

proc center*(g: Graph): seq[NodeId] =
  ## Center of the graph: nodes with eccentricity equal to the radius.
  let r = g.radius()
  for i in 0 ..< g.nodeCount:
    let ecc = g.eccentricity(NodeId(i))
    if ecc == r:
      result.add(NodeId(i))
