#[
=========
Traversal
=========

BFS, DFS, cycle detection, Eulerian path/circuit, bipartite check.
]#

{.push raises: [Defect].}

# std...
import std/deques

# graph...
import types
import unionfind

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== BFS ================================================================================================================
#=======================================================================================================================

iterator bfs*(g: Graph, start: NodeId): NodeId =
  ## Yield nodes in breadth-first order from `start`.
  var visited = newSeq[bool](g.nodeCount)
  var queue = initDeque[NodeId]()
  visited[start.int] = true
  queue.addLast(start)
  while queue.len > 0:
    let node = queue.popFirst()
    yield node
    for e in g.neighbors(node):
      if not visited[e.target.int]:
        visited[e.target.int] = true
        queue.addLast(e.target)

proc bfsTree*(g: Graph, start: NodeId): seq[NodeId] =
  ## Return BFS traversal order as a sequence.
  for node in g.bfs(start):
    result.add(node)

proc bfsParent*(g: Graph, start: NodeId): seq[int] =
  ## Return parent array from BFS. parent[i] = -1 if unvisited, parent[start] = start.int.
  result.setLen(g.nodeCount)
  for i in 0 ..< g.nodeCount:
    result[i] = -1
  result[start.int] = start.int
  var queue = initDeque[NodeId]()
  queue.addLast(start)
  while queue.len > 0:
    let node = queue.popFirst()
    for e in g.neighbors(node):
      if result[e.target.int] == -1:
        result[e.target.int] = node.int
        queue.addLast(e.target)

#=======================================================================================================================
#== DFS ================================================================================================================
#=======================================================================================================================

iterator dfs*(g: Graph, start: NodeId): NodeId =
  ## Yield nodes in depth-first order from `start` (iterative).
  var visited = newSeq[bool](g.nodeCount)
  var stack: seq[NodeId]
  stack.add(start)
  while stack.len > 0:
    let node = stack.pop()
    if visited[node.int]:
      continue
    visited[node.int] = true
    yield node
    # Push neighbors in reverse order so first neighbor is visited first.
    let nbrs = g.neighbors(node)
    for i in countdown(nbrs.len - 1, 0):
      if not visited[nbrs[i].target.int]:
        stack.add(nbrs[i].target)

proc dfsTree*(g: Graph, start: NodeId): seq[NodeId] =
  ## Return DFS traversal order as a sequence.
  for node in g.dfs(start):
    result.add(node)

proc dfsParent*(g: Graph, start: NodeId): seq[int] =
  ## Return parent array from DFS. parent[i] = -1 if unvisited, parent[start] = start.int.
  result.setLen(g.nodeCount)
  for i in 0 ..< g.nodeCount:
    result[i] = -1
  result[start.int] = start.int
  var stack: seq[NodeId]
  stack.add(start)
  while stack.len > 0:
    let node = stack.pop()
    for e in g.neighbors(node):
      if result[e.target.int] == -1:
        result[e.target.int] = node.int
        stack.add(e.target)

#=======================================================================================================================
#== TOPOLOGICAL ORDER (DFS) ============================================================================================
#=======================================================================================================================

proc topologicalSort*(g: Graph): seq[NodeId] =
  ## Return nodes in topological order for a DAG.
  ## Raises Defect if the graph contains a cycle.
  let n = g.nodeCount
  var visited: seq[bool]
  visited.setLen(n)
  var onStack: seq[bool]
  onStack.setLen(n)
  var order: seq[NodeId]

  proc visit(node: NodeId) =
    visited[node.int] = true
    onStack[node.int] = true
    for e in g.neighbors(node):
      if onStack[e.target.int]:
        raise newException(Defect, "graph contains a cycle")
      if not visited[e.target.int]:
        visit(e.target)
    onStack[node.int] = false
    order.add(node)

  for i in 0 ..< n:
    if not visited[i]:
      visit(NodeId(i))

  # Reverse to get topological order.
  result.setLen(order.len)
  for i in 0 ..< order.len:
    result[i] = order[order.len - 1 - i]

#=======================================================================================================================
#== CYCLE DETECTION ====================================================================================================
#=======================================================================================================================

proc hasCycleDirected*(g: Graph): bool =
  ## Detect whether a directed graph contains a cycle using DFS coloring.
  let n = g.nodeCount
  # 0 = white (unvisited), 1 = gray (on stack), 2 = black (done)
  var color: seq[int]
  color.setLen(n)

  proc visit(node: int): bool =
    color[node] = 1
    for e in g.neighbors(NodeId(node)):
      if color[e.target.int] == 1:
        return true
      if color[e.target.int] == 0:
        if visit(e.target.int):
          return true
    color[node] = 2
    false

  for i in 0 ..< n:
    if color[i] == 0:
      if visit(i):
        return true
  false

proc hasCycleUndirected*(g: Graph): bool =
  ## Detect whether an undirected graph contains a cycle using union-find.
  var uf = initUnionFind(g.nodeCount)
  for e in g.edges:
    if uf.connected(e.source.int, e.target.int):
      return true
    uf.union(e.source.int, e.target.int)
  false

proc hasCycle*(g: Graph): bool =
  ## Detect whether the graph contains a cycle.
  if g.kind == gkDirected:
    hasCycleDirected(g)
  else:
    hasCycleUndirected(g)

#=======================================================================================================================
#== BIPARTITE CHECK ====================================================================================================
#=======================================================================================================================

proc isBipartite*(g: Graph): bool =
  ## Check whether the graph is bipartite (2-colorable).
  let n = g.nodeCount
  if n == 0:
    return true
  var color: seq[int]
  color.setLen(n)
  for i in 0 ..< n:
    color[i] = -1

  var queue = initDeque[NodeId]()
  for start in 0 ..< n:
    if color[start] != -1:
      continue
    color[start] = 0
    queue.addLast(NodeId(start))
    while queue.len > 0:
      let node = queue.popFirst()
      for e in g.neighbors(node):
        let t = e.target.int
        if color[t] == -1:
          color[t] = 1 - color[node.int]
          queue.addLast(e.target)
        elif color[t] == color[node.int]:
          return false
  true

proc bipartitePartition*(g: Graph): (seq[NodeId], seq[NodeId]) =
  ## Return the two partitions of a bipartite graph.
  ## Raises Defect if the graph is not bipartite.
  let n = g.nodeCount
  var color: seq[int]
  color.setLen(n)
  for i in 0 ..< n:
    color[i] = -1
  var queue = initDeque[NodeId]()
  for start in 0 ..< n:
    if color[start] != -1:
      continue
    color[start] = 0
    queue.addLast(NodeId(start))
    while queue.len > 0:
      let node = queue.popFirst()
      for e in g.neighbors(node):
        let t = e.target.int
        if color[t] == -1:
          color[t] = 1 - color[node.int]
          queue.addLast(e.target)
        elif color[t] == color[node.int]:
          raise newException(Defect, "graph is not bipartite")
  var partA, partB: seq[NodeId]
  for i in 0 ..< n:
    if color[i] == 0:
      partA.add(NodeId(i))
    else:
      partB.add(NodeId(i))
  (partA, partB)

#=======================================================================================================================
#== EULERIAN PATH / CIRCUIT ============================================================================================
#=======================================================================================================================

proc hasEulerianCircuit*(g: Graph): bool =
  ## Check whether the graph has an Eulerian circuit.
  let n = g.nodeCount
  if n == 0:
    return true
  if g.kind == gkDirected:
    var inDeg: seq[int]
    inDeg.setLen(n)
    for i in 0 ..< n:
      for e in g.neighbors(NodeId(i)):
        inDeg[e.target.int] += 1
    for i in 0 ..< n:
      if g.degree(NodeId(i)) != inDeg[i]:
        return false
  else:
    for i in 0 ..< n:
      if g.degree(NodeId(i)) mod 2 != 0:
        return false
  # Check connectivity among nodes with edges.
  var startNode = -1
  for i in 0 ..< n:
    if g.degree(NodeId(i)) > 0:
      startNode = i
      break
  if startNode == -1:
    return true  # No edges.
  var visited: seq[bool]
  visited.setLen(n)
  var queue = initDeque[NodeId]()
  visited[startNode] = true
  queue.addLast(NodeId(startNode))
  while queue.len > 0:
    let node = queue.popFirst()
    for e in g.neighbors(node):
      if not visited[e.target.int]:
        visited[e.target.int] = true
        queue.addLast(e.target)
  if g.kind == gkDirected:
    # Build reverse graph reachability from startNode.
    var revVisited: seq[bool]
    revVisited.setLen(n)
    var revQueue = initDeque[NodeId]()
    revVisited[startNode] = true
    revQueue.addLast(NodeId(startNode))
    while revQueue.len > 0:
      let node = revQueue.popFirst()
      for i in 0 ..< n:
        if not revVisited[i]:
          for e in g.neighbors(NodeId(i)):
            if e.target == node:
              revVisited[i] = true
              revQueue.addLast(NodeId(i))
              break
    for i in 0 ..< n:
      if g.degree(NodeId(i)) > 0 and not revVisited[i]:
        return false
  else:
    for i in 0 ..< n:
      if g.degree(NodeId(i)) > 0 and not visited[i]:
        return false
  true

proc hasEulerianPath*(g: Graph): bool =
  ## Check whether the graph has an Eulerian path (but not necessarily a circuit).
  let n = g.nodeCount
  if n == 0:
    return true
  if g.kind == gkDirected:
    var inDeg: seq[int]
    inDeg.setLen(n)
    for i in 0 ..< n:
      for e in g.neighbors(NodeId(i)):
        inDeg[e.target.int] += 1
    var startCount = 0
    var endCount = 0
    for i in 0 ..< n:
      let outD = g.degree(NodeId(i))
      let diff = outD - inDeg[i]
      if diff == 1:
        startCount += 1
      elif diff == -1:
        endCount += 1
      elif diff != 0:
        return false
    (startCount == 0 and endCount == 0) or (startCount == 1 and endCount == 1)
  else:
    var oddCount = 0
    for i in 0 ..< n:
      if g.degree(NodeId(i)) mod 2 != 0:
        oddCount += 1
    oddCount == 0 or oddCount == 2

proc eulerianCircuit*(g: Graph): seq[NodeId] =
  ## Find an Eulerian circuit using Hierholzer's algorithm.
  ## Raises Defect if no Eulerian circuit exists.
  if not g.hasEulerianCircuit():
    raise newException(Defect, "graph has no Eulerian circuit")
  let n = g.nodeCount
  if g.edgeCount == 0:
    return @[]
  # Find a start node with edges.
  var startNode = NodeId(0)
  for i in 0 ..< n:
    if g.degree(NodeId(i)) > 0:
      startNode = NodeId(i)
      break
  # Track edge usage with per-node cursors.
  var adjIdx: seq[int]
  adjIdx.setLen(n)
  # Build mutable adjacency.
  var adjList: seq[seq[Edge]]
  adjList.setLen(n)
  for i in 0 ..< n:
    let nbrs = g.neighbors(NodeId(i))
    adjList[i].setLen(nbrs.len)
    for j in 0 ..< nbrs.len:
      adjList[i][j] = nbrs[j]
  if g.kind == gkUndirected:
    var edgeUsed: seq[seq[bool]]
    edgeUsed.setLen(n)
    for i in 0 ..< n:
      edgeUsed[i].setLen(adjList[i].len)
    var stack: seq[NodeId]
    stack.add(startNode)
    while stack.len > 0:
      let v = stack[^1]
      var found = false
      while adjIdx[v.int] < adjList[v.int].len:
        let idx = adjIdx[v.int]
        if edgeUsed[v.int][idx]:
          adjIdx[v.int] += 1
          continue
        let u = adjList[v.int][idx].target
        edgeUsed[v.int][idx] = true
        for k in 0 ..< adjList[u.int].len:
          if not edgeUsed[u.int][k] and adjList[u.int][k].target == v:
            edgeUsed[u.int][k] = true
            break
        adjIdx[v.int] += 1
        stack.add(u)
        found = true
        break
      if not found:
        result.add(stack.pop())
  else:
    var stack: seq[NodeId]
    stack.add(startNode)
    while stack.len > 0:
      let v = stack[^1]
      if adjIdx[v.int] < adjList[v.int].len:
        let next = adjList[v.int][adjIdx[v.int]].target
        adjIdx[v.int] += 1
        stack.add(next)
      else:
        result.add(stack.pop())
  # Reverse to get the circuit in order.
  var reversed: seq[NodeId]
  for i in countdown(result.len - 1, 0):
    reversed.add(result[i])
  result = reversed
