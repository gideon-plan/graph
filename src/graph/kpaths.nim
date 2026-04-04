#[
======================
Yen's K-Shortest Paths
======================

Find the k shortest simple (loopless) paths between two nodes.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/[algorithm, heapqueue, sets]

# graph...
import types
import shortest_path

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== TYPES ==============================================================================================================
#=======================================================================================================================

type
  KPath* = object
    ## A path with its total distance.
    dist*: float
    nodes*: seq[NodeId]

#=======================================================================================================================
#== YEN'S ALGORITHM ====================================================================================================
#=======================================================================================================================

proc yenKPaths*(g: Graph, source, target: NodeId, k: int): seq[KPath] =
  ## Find the `k` shortest simple paths from `source` to `target`.
  ## Uses Yen's algorithm with Dijkstra as the inner shortest-path routine.
  ## Returns up to `k` paths sorted by distance.
  if k <= 0:
    return @[]

  # Find the first shortest path.
  let (dist0, path0) = g.dijkstraPath(source, target)
  if path0.len == 0:
    return @[]
  result.add(KPath(dist: dist0, nodes: path0))
  if k == 1:
    return

  var candidates: seq[KPath]

  for ki in 1 ..< k:
    let prevPath = result[^1]
    for i in 0 ..< prevPath.nodes.len - 1:
      let spurNode = prevPath.nodes[i]
      let rootPath = prevPath.nodes[0 .. i]

      # Compute root path distance.
      var rootDist = 0.0
      for j in 0 ..< rootPath.len - 1:
        for e in g.neighbors(rootPath[j]):
          if e.target == rootPath[j + 1]:
            rootDist += e.weight
            break

      # Build a graph excluding edges and nodes used by existing shortest paths.
      var excludedEdges = initHashSet[(system.int, system.int)]()
      for prevKPath in result:
        if prevKPath.nodes.len > i and prevKPath.nodes[0 .. i] == rootPath:
          excludedEdges.incl((prevKPath.nodes[i].int, prevKPath.nodes[i + 1].int))

      var excludedNodes = initHashSet[system.int]()
      for j in 0 ..< i:
        excludedNodes.incl(rootPath[j].int)

      # Build filtered graph.
      var filtered = initGraph(g.kind, g.nodeCount)
      for ni in 0 ..< g.nodeCount:
        discard filtered.addNode()
      for ni in 0 ..< g.nodeCount:
        if ni in excludedNodes:
          continue
        for e in g.neighbors(NodeId(ni)):
          if e.target.int in excludedNodes:
            continue
          if (ni, e.target.int) in excludedEdges:
            continue
          filtered.addEdge(NodeId(ni), e.target, e.weight)

      # Find spur path.
      let (spurDist, spurPath) = filtered.dijkstraPath(spurNode, target)
      if spurPath.len > 0:
        var totalPath: seq[NodeId]
        for j in 0 ..< rootPath.len - 1:
          totalPath.add(rootPath[j])
        for j in 0 ..< spurPath.len:
          totalPath.add(spurPath[j])
        let totalDist = rootDist + spurDist

        # Add to candidates if not already present.
        var found = false
        for c in candidates:
          if c.nodes == totalPath:
            found = true
            break
        if not found:
          candidates.add(KPath(dist: totalDist, nodes: totalPath))

    if candidates.len == 0:
      break

    # Sort candidates and pick the best one.
    candidates.sort(proc(a, b: KPath): int = cmp(a.dist, b.dist))
    result.add(candidates[0])
    candidates.delete(0)
