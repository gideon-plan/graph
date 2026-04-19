#[
==========
Components
==========

Connected components, strongly connected components (Tarjan, Kosaraju),
biconnected components, articulation points, bridges.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/deques

# graph...
import types
import unionfind

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== CONNECTED COMPONENTS (UNDIRECTED) ==================================================================================
#=======================================================================================================================

proc connectedComponents*(g: Graph): seq[seq[NodeId]] =
  ## Find connected components in an undirected graph using union-find.
  let n = g.nodeCount
  if n == 0:
    return @[]
  var uf = initUnionFind(n)
  for e in g.edges:
    uf.union(e.source.int, e.target.int)

  # Group nodes by representative.
  var groups: seq[seq[NodeId]]
  groups.setLen(n)
  for i in 0 ..< n:
    let rep = uf.find(i)
    groups[rep].add(NodeId(i))

  for g in groups:
    if g.len > 0:
      result.add(g)

proc componentCount*(g: Graph): system.int =
  ## Number of connected components.
  g.connectedComponents().len

proc isConnected*(g: Graph): bool =
  ## Whether the undirected graph is connected.
  g.componentCount() <= 1

#=======================================================================================================================
#== TARJAN'S SCC =======================================================================================================
#=======================================================================================================================

proc tarjanScc*(g: Graph): seq[seq[NodeId]] =
  ## Tarjan's algorithm for strongly connected components in a directed graph.
  ## Returns SCCs in reverse topological order.
  let n = g.nodeCount
  var disc: seq[system.int]
  disc.setLen(n)
  var low: seq[system.int]
  low.setLen(n)
  var onStack: seq[bool]
  onStack.setLen(n)
  var visited: seq[bool]
  visited.setLen(n)
  var stack: seq[NodeId]
  var timer = 0
  var sccs: seq[seq[NodeId]]

  proc strongConnect(v: NodeId) =
    disc[v.int] = timer
    low[v.int] = timer
    timer += 1
    visited[v.int] = true
    stack.add(v)
    onStack[v.int] = true

    for e in g.neighbors(v):
      if not visited[e.target.int]:
        strongConnect(e.target)
        if low[e.target.int] < low[v.int]:
          low[v.int] = low[e.target.int]
      elif onStack[e.target.int]:
        if disc[e.target.int] < low[v.int]:
          low[v.int] = disc[e.target.int]

    if low[v.int] == disc[v.int]:
      var component: seq[NodeId]
      while true:
        let w = stack.pop()
        onStack[w.int] = false
        component.add(w)
        if w == v:
          break
      sccs.add(component)

  for i in 0 ..< n:
    if not visited[i]:
      strongConnect(NodeId(i))
  result = sccs

#=======================================================================================================================
#== KOSARAJU'S SCC =====================================================================================================
#=======================================================================================================================

proc kosarajuScc*(g: Graph): seq[seq[NodeId]] =
  ## Kosaraju's algorithm for strongly connected components.
  let n = g.nodeCount
  # Pass 1: DFS on original graph, record finish order.
  var visited: seq[bool]
  visited.setLen(n)
  var order: seq[NodeId]

  proc dfs1(v: system.int) =
    visited[v] = true
    for e in g.neighbors(NodeId(v)):
      if not visited[e.target.int]:
        dfs1(e.target.int)
    order.add(NodeId(v))

  for i in 0 ..< n:
    if not visited[i]:
      dfs1(i)

  # Build reverse graph.
  var rev = initGraph(GraphKind.Directed, n)
  for i in 0 ..< n:
    discard rev.addNode()
  for i in 0 ..< n:
    for e in g.neighbors(NodeId(i)):
      rev.addEdge(e.target, NodeId(i))

  # Pass 2: DFS on reverse graph in reverse finish order.
  var visited2: seq[bool]
  visited2.setLen(n)

  proc dfs2(v: system.int, component: var seq[NodeId]) =
    visited2[v] = true
    component.add(NodeId(v))
    for e in rev.neighbors(NodeId(v)):
      if not visited2[e.target.int]:
        dfs2(e.target.int, component)

  for i in countdown(order.len - 1, 0):
    let v = order[i].int
    if not visited2[v]:
      var component: seq[NodeId]
      dfs2(v, component)
      result.add(component)

#=======================================================================================================================
#== ARTICULATION POINTS ================================================================================================
#=======================================================================================================================

proc articulationPoints*(g: Graph): seq[NodeId] =
  ## Find articulation points (cut vertices) in an undirected graph.
  let n = g.nodeCount
  var disc: seq[system.int]
  disc.setLen(n)
  var low: seq[system.int]
  low.setLen(n)
  var visited: seq[bool]
  visited.setLen(n)
  var parent: seq[system.int]
  parent.setLen(n)
  var isAP: seq[bool]
  isAP.setLen(n)
  for i in 0 ..< n:
    parent[i] = -1
  var timer = 0

  proc dfs(u: system.int) =
    visited[u] = true
    disc[u] = timer
    low[u] = timer
    timer += 1
    var childCount = 0

    for e in g.neighbors(NodeId(u)):
      let v = e.target.int
      if not visited[v]:
        childCount += 1
        parent[v] = u
        dfs(v)
        if low[v] < low[u]:
          low[u] = low[v]
        # Root with 2+ children is an AP.
        if parent[u] == -1 and childCount > 1:
          isAP[u] = true
        # Non-root where no descendant can reach above u.
        if parent[u] != -1 and low[v] >= disc[u]:
          isAP[u] = true
      elif v != parent[u]:
        if disc[v] < low[u]:
          low[u] = disc[v]

  for i in 0 ..< n:
    if not visited[i]:
      dfs(i)

  for i in 0 ..< n:
    if isAP[i]:
      result.add(NodeId(i))

#=======================================================================================================================
#== BRIDGES ============================================================================================================
#=======================================================================================================================

proc bridges*(g: Graph): seq[(NodeId, NodeId)] =
  ## Find bridges (cut edges) in an undirected graph.
  let n = g.nodeCount
  var disc: seq[system.int]
  disc.setLen(n)
  var low: seq[system.int]
  low.setLen(n)
  var visited: seq[bool]
  visited.setLen(n)
  var parent: seq[system.int]
  parent.setLen(n)
  for i in 0 ..< n:
    parent[i] = -1
  var timer = 0
  var bridgeList: seq[(NodeId, NodeId)]

  proc dfs(u: system.int) =
    visited[u] = true
    disc[u] = timer
    low[u] = timer
    timer += 1

    for e in g.neighbors(NodeId(u)):
      let v = e.target.int
      if not visited[v]:
        parent[v] = u
        dfs(v)
        if low[v] < low[u]:
          low[u] = low[v]
        if low[v] > disc[u]:
          bridgeList.add((NodeId(u), NodeId(v)))
      elif v != parent[u]:
        if disc[v] < low[u]:
          low[u] = disc[v]

  for i in 0 ..< n:
    if not visited[i]:
      dfs(i)
  result = bridgeList

#=======================================================================================================================
#== BICONNECTED COMPONENTS =============================================================================================
#=======================================================================================================================

proc biconnectedComponents*(g: Graph): seq[seq[(NodeId, NodeId)]] =
  ## Find biconnected components (edge sets) in an undirected graph.
  let n = g.nodeCount
  var disc: seq[system.int]
  disc.setLen(n)
  var low: seq[system.int]
  low.setLen(n)
  var visited: seq[bool]
  visited.setLen(n)
  var parent: seq[system.int]
  parent.setLen(n)
  for i in 0 ..< n:
    parent[i] = -1
  var timer = 0
  var edgeStack: seq[(NodeId, NodeId)]
  var bcs: seq[seq[(NodeId, NodeId)]]

  proc dfs(u: system.int) =
    visited[u] = true
    disc[u] = timer
    low[u] = timer
    timer += 1

    for e in g.neighbors(NodeId(u)):
      let v = e.target.int
      if not visited[v]:
        parent[v] = u
        edgeStack.add((NodeId(u), NodeId(v)))
        dfs(v)
        if low[v] < low[u]:
          low[u] = low[v]
        if low[v] >= disc[u]:
          var component: seq[(NodeId, NodeId)]
          while true:
            let edge = edgeStack.pop()
            component.add(edge)
            if edge[0] == NodeId(u) and edge[1] == NodeId(v):
              break
          bcs.add(component)
      elif v != parent[u] and disc[v] < disc[u]:
        edgeStack.add((NodeId(u), NodeId(v)))
        if disc[v] < low[u]:
          low[u] = disc[v]

  for i in 0 ..< n:
    if not visited[i]:
      dfs(i)
  result = bcs
