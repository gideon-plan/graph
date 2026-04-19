#[
===========
Graph Types
===========

Adjacency list graph representation supporting directed/undirected and
weighted/unweighted graphs. Vertices are integer-indexed for cache-friendly
access and O(1) lookup. Edge weights default to 1.0 for unweighted use.
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

# std...
import std/[hashes, tables]

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== TYPES ==============================================================================================================
#=======================================================================================================================

type
  NodeId* = distinct int
    ## Opaque vertex identifier. Wraps a dense integer index.

  Edge* = object
    ## Weighted directed edge.
    target*: NodeId
    weight*: float

  GraphKind* {.pure.} = enum
    ## Whether edges are directed or undirected.
    Directed
    Undirected

  Graph* = object
    ## Adjacency list graph.
    ##
    ## - `adj[i]` holds outgoing edges from node `i`.
    ## - For undirected graphs, each edge is stored in both directions.
    ## - Node count equals `adj.len`; nodes are `0 ..< nodeCount`.
    kind*: GraphKind
    adj: seq[seq[Edge]]
    labels: Table[string, NodeId]
      ## Optional name -> NodeId mapping.

#=======================================================================================================================
#== NODE ID ============================================================================================================
#=======================================================================================================================

proc `==`*(a, b: NodeId): bool {.borrow.}
proc hash*(n: NodeId): Hash {.borrow.}
proc `$`*(n: NodeId): string {.borrow.}

template int*(n: NodeId): int =
  ## Extract the underlying int from a NodeId.
  system.int(n)

#=======================================================================================================================
#== EDGE ===============================================================================================================
#=======================================================================================================================

func edge*(target: NodeId, weight: float = 1.0): Edge =
  ## Create an edge to `target` with the given `weight`.
  Edge(target: target, weight: weight)

#=======================================================================================================================
#== GRAPH CONSTRUCTION =================================================================================================
#=======================================================================================================================

func initGraph*(kind: GraphKind = GraphKind.Directed, capacity: int = 0): Graph =
  ## Create an empty graph of the given `kind`.
  result = Graph(kind: kind)
  if capacity > 0:
    result.adj = newSeqOfCap[seq[Edge]](capacity)

func addNode*(g: var Graph): NodeId =
  ## Add a new node and return its id.
  result = NodeId(g.adj.len)
  g.adj.add(@[])

func addNodes*(g: var Graph, count: int): NodeId =
  ## Add `count` nodes. Return the id of the first new node.
  result = NodeId(g.adj.len)
  for i in 0 ..< count:
    g.adj.add(@[])

func addLabeledNode*(g: var Graph, label: string): NodeId =
  ## Add a node with a string label.
  result = g.addNode()
  g.labels[label] = result

proc nodeByLabel*(g: Graph, label: string): NodeId {.raises: [KeyError].} =
  ## Look up a node by its string label.
  ## Raises KeyError if the label does not exist.
  g.labels[label]

func tryNodeByLabel*(g: Graph, label: string): (bool, NodeId) =
  ## Try to look up a node by label. Returns (found, id).
  if g.labels.hasKey(label):
    (true, g.labels.getOrDefault(label))
  else:
    (false, NodeId(0))

#=======================================================================================================================
#== EDGE MUTATION ======================================================================================================
#=======================================================================================================================

func addEdge*(g: var Graph, source, target: NodeId, weight: float = 1.0) =
  ## Add an edge from `source` to `target`.
  ## For undirected graphs, the reverse edge is added automatically.
  g.adj[source.int].add(edge(target, weight))
  if g.kind == GraphKind.Undirected:
    g.adj[target.int].add(edge(source, weight))

func addEdge*(g: var Graph, source, target: int, weight: float = 1.0) =
  ## Convenience overload accepting int node ids.
  g.addEdge(NodeId(source), NodeId(target), weight)

#=======================================================================================================================
#== ACCESSORS ==========================================================================================================
#=======================================================================================================================

func nodeCount*(g: Graph): int =
  ## Number of nodes in the graph.
  g.adj.len

func edgeCount*(g: Graph): int =
  ## Number of directed edges. For undirected graphs, each undirected edge is counted once
  ## (total stored edges / 2).
  var total = 0
  for edges in g.adj:
    total += edges.len
  if g.kind == GraphKind.Undirected:
    total div 2
  else:
    total

func neighbors*(g: Graph, node: NodeId): lent seq[Edge] =
  ## Outgoing edges from `node`.
  g.adj[node.int]

func neighbors*(g: Graph, node: int): lent seq[Edge] =
  ## Convenience overload accepting int.
  g.adj[node]

func degree*(g: Graph, node: NodeId): int =
  ## Out-degree of `node` (or total degree for undirected).
  g.adj[node.int].len

func hasEdge*(g: Graph, source, target: NodeId): bool =
  ## Check whether an edge from `source` to `target` exists.
  for e in g.adj[source.int]:
    if e.target == target:
      return true
  false

func isEmpty*(g: Graph): bool =
  ## True if the graph has no nodes.
  g.adj.len == 0

#=======================================================================================================================
#== ITERATION ==========================================================================================================
#=======================================================================================================================

iterator nodes*(g: Graph): NodeId =
  ## Yield all node ids.
  for i in 0 ..< g.adj.len:
    yield NodeId(i)

iterator edges*(g: Graph): tuple[source: NodeId, target: NodeId, weight: float] =
  ## Yield all edges as (source, target, weight) tuples.
  ## For undirected graphs, each edge is yielded once (source < target).
  for i in 0 ..< g.adj.len:
    for e in g.adj[i]:
      if g.kind == GraphKind.Undirected:
        if i <= e.target.int:
          yield (NodeId(i), e.target, e.weight)
      else:
        yield (NodeId(i), e.target, e.weight)

iterator neighborIds*(g: Graph, node: NodeId): NodeId =
  ## Yield ids of neighbors of `node`.
  for e in g.adj[node.int]:
    yield e.target
