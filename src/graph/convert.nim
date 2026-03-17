#[
===========================
Compressed Sparse Row (CSR)
===========================

Cache-friendly graph representation for read-heavy batch algorithms
(PageRank, centrality, community detection). Stored as two parallel arrays:

- `offsets`: length `nodeCount + 1`. `offsets[i] ..< offsets[i+1]` indexes
  into `targets`/`weights` for node `i`'s outgoing edges.
- `targets`: packed destination node ids.
- `weights`: packed edge weights (parallel to `targets`).
]#

{.push raises: [Defect].}

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== TYPES ==============================================================================================================
#=======================================================================================================================

type
  CsrGraph* = object
    ## Compressed Sparse Row graph. Immutable after construction.
    kind*: GraphKind
    nodeCount*: int
    offsets*: seq[int]
    targets*: seq[NodeId]
    weights*: seq[float]

#=======================================================================================================================
#== ADJACENCY LIST -> CSR ==============================================================================================
#=======================================================================================================================

proc toCsr*(g: Graph): CsrGraph =
  ## Convert an adjacency list graph to CSR format.
  let n = g.nodeCount
  var edgeTotal = 0
  for node in g.nodes:
    edgeTotal += g.neighbors(node).len

  result.kind = g.kind
  result.nodeCount = n
  result.offsets.setLen(n + 1)
  result.targets.setLen(edgeTotal)
  result.weights.setLen(edgeTotal)

  var pos = 0
  for i in 0 ..< n:
    result.offsets[i] = pos
    for e in g.neighbors(NodeId(i)):
      result.targets[pos] = e.target
      result.weights[pos] = e.weight
      pos += 1
  result.offsets[n] = pos

#=======================================================================================================================
#== CSR -> ADJACENCY LIST ==============================================================================================
#=======================================================================================================================

func toGraph*(csr: CsrGraph): Graph =
  ## Convert a CSR graph back to adjacency list format.
  ## For undirected CSR graphs, assumes edges are stored in both directions
  ## (as produced by `toCsr` on an undirected `Graph`).
  result = initGraph(csr.kind, csr.nodeCount)
  # Pre-allocate all nodes.
  for i in 0 ..< csr.nodeCount:
    discard result.addNode()

  # For directed graphs, copy edges directly.
  # For undirected graphs, the CSR already has both directions stored,
  # but addEdge would double them. Add edges manually for one direction only.
  if csr.kind == gkDirected:
    for i in 0 ..< csr.nodeCount:
      let start = csr.offsets[i]
      let stop = csr.offsets[i + 1]
      for j in start ..< stop:
        result.addEdge(NodeId(i), csr.targets[j], csr.weights[j])
  else:
    # For undirected: add raw edges to adj lists without the auto-reverse
    # that addEdge would do.
    for i in 0 ..< csr.nodeCount:
      let start = csr.offsets[i]
      let stop = csr.offsets[i + 1]
      for j in start ..< stop:
        result.addEdge(NodeId(i), csr.targets[j], csr.weights[j])

#=======================================================================================================================
#== CSR ACCESSORS ======================================================================================================
#=======================================================================================================================

func edgeCount*(csr: CsrGraph): int =
  ## Number of directed edges (or undirected edges counted once).
  let total = csr.targets.len
  if csr.kind == gkUndirected:
    total div 2
  else:
    total

func degree*(csr: CsrGraph, node: NodeId): int =
  ## Out-degree of `node`.
  csr.offsets[node.int + 1] - csr.offsets[node.int]

func hasEdge*(csr: CsrGraph, source, target: NodeId): bool =
  ## Check whether an edge exists from `source` to `target`.
  let start = csr.offsets[source.int]
  let stop = csr.offsets[source.int + 1]
  for j in start ..< stop:
    if csr.targets[j] == target:
      return true
  false

#=======================================================================================================================
#== CSR ITERATION ======================================================================================================
#=======================================================================================================================

iterator neighbors*(csr: CsrGraph, node: NodeId): (NodeId, float) =
  ## Yield (target, weight) pairs for neighbors of `node`.
  let start = csr.offsets[node.int]
  let stop = csr.offsets[node.int + 1]
  for j in start ..< stop:
    yield (csr.targets[j], csr.weights[j])

iterator neighborIds*(csr: CsrGraph, node: NodeId): NodeId =
  ## Yield neighbor node ids.
  let start = csr.offsets[node.int]
  let stop = csr.offsets[node.int + 1]
  for j in start ..< stop:
    yield csr.targets[j]

iterator nodes*(csr: CsrGraph): NodeId =
  ## Yield all node ids.
  for i in 0 ..< csr.nodeCount:
    yield NodeId(i)

iterator edges*(csr: CsrGraph): tuple[source: NodeId, target: NodeId, weight: float] =
  ## Yield all edges. For undirected graphs, each edge yielded once (source <= target).
  for i in 0 ..< csr.nodeCount:
    let start = csr.offsets[i]
    let stop = csr.offsets[i + 1]
    for j in start ..< stop:
      if csr.kind == gkUndirected:
        if i <= csr.targets[j].int:
          yield (NodeId(i), csr.targets[j], csr.weights[j])
      else:
        yield (NodeId(i), csr.targets[j], csr.weights[j])
