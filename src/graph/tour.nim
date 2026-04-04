#[
====
Tour
====

Christofides TSP approximation.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/sets

# graph...
import types
import mst
import matching
import shortest_path

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== CHRISTOFIDES TSP APPROXIMATION =====================================================================================
#=======================================================================================================================

proc christofides*(g: Graph): (float, seq[NodeId]) =
  ## Christofides 3/2-approximation for the Traveling Salesman Problem.
  ## Requires a complete undirected weighted graph.
  ## Returns (tour cost, tour node sequence).
  let n = g.nodeCount
  if n <= 2:
    var tour: seq[NodeId]
    for i in 0 ..< n:
      tour.add(NodeId(i))
    if n > 0:
      tour.add(NodeId(0))
    return (0.0, tour)

  # Step 1: Find MST.
  let mstEdges = g.kruskal()

  # Step 2: Find odd-degree vertices in MST.
  var mstDeg: seq[system.int]
  mstDeg.setLen(n)
  for e in mstEdges:
    mstDeg[e.source.int] += 1
    mstDeg[e.target.int] += 1

  var oddVertices: seq[system.int]
  for i in 0 ..< n:
    if mstDeg[i] mod 2 != 0:
      oddVertices.add(i)

  # Step 3: Minimum weight perfect matching on odd-degree vertices.
  # Build cost matrix for odd vertices.
  let numOdd = oddVertices.len
  var costMat: seq[seq[float]]
  costMat.setLen(numOdd)
  for i in 0 ..< numOdd:
    costMat[i].setLen(numOdd)
    for j in 0 ..< numOdd:
      if i != j:
        # Get weight from original graph.
        var found = false
        for e in g.neighbors(NodeId(oddVertices[i])):
          if e.target.int == oddVertices[j]:
            costMat[i][j] = e.weight
            found = true
            break
        if not found:
          costMat[i][j] = InfDist
      else:
        costMat[i][j] = InfDist

  let (_, matchAssign) = hungarian(costMat)

  # Step 4: Combine MST and matching edges into a multigraph.
  # Build adjacency list.
  var adj: seq[seq[system.int]]
  adj.setLen(n)
  for e in mstEdges:
    adj[e.source.int].add(e.target.int)
    adj[e.target.int].add(e.source.int)

  var matched = initHashSet[system.int]()
  for i in 0 ..< numOdd:
    if i notin matched and matchAssign[i] < numOdd:
      let j = matchAssign[i]
      adj[oddVertices[i]].add(oddVertices[j])
      adj[oddVertices[j]].add(oddVertices[i])
      matched.incl(i)
      matched.incl(j)

  # Step 5: Find Eulerian circuit on the multigraph.
  var edgeUsed: seq[seq[bool]]
  edgeUsed.setLen(n)
  for i in 0 ..< n:
    edgeUsed[i].setLen(adj[i].len)

  var adjIdx: seq[system.int]
  adjIdx.setLen(n)
  var circuit: seq[system.int]
  var stack: seq[system.int]
  stack.add(0)
  while stack.len > 0:
    let v = stack[^1]
    var found = false
    while adjIdx[v] < adj[v].len:
      let idx = adjIdx[v]
      if edgeUsed[v][idx]:
        adjIdx[v] += 1
        continue
      let u = adj[v][idx]
      edgeUsed[v][idx] = true
      # Mark reverse edge.
      for k in 0 ..< adj[u].len:
        if not edgeUsed[u][k] and adj[u][k] == v:
          edgeUsed[u][k] = true
          break
      adjIdx[v] += 1
      stack.add(u)
      found = true
      break
    if not found:
      circuit.add(stack.pop())

  # Step 6: Shortcut to Hamiltonian tour.
  var visited = initHashSet[system.int]()
  var tour: seq[NodeId]
  for i in countdown(circuit.len - 1, 0):
    let v = circuit[i]
    if v notin visited:
      visited.incl(v)
      tour.add(NodeId(v))
  if tour.len > 0:
    tour.add(tour[0])

  # Compute tour cost.
  var cost = 0.0
  for i in 0 ..< tour.len - 1:
    for e in g.neighbors(tour[i]):
      if e.target == tour[i + 1]:
        cost += e.weight
        break

  (cost, tour)
