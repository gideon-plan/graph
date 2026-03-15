#[
==========
Union-Find
==========

Disjoint set data structure with path compression and union by rank.
Used by connected components, Kruskal's MST, and other graph algorithms.
]#

{.push raises: [Defect].}
{.experimental: "strict_funcs".}

#=======================================================================================================================
#== TYPES ==============================================================================================================
#=======================================================================================================================

type
  UnionFind* = object
    ## Disjoint set forest with path compression and union by rank.
    parent: seq[int]
    rank: seq[int]
    count: int
      ## Number of disjoint sets.

#=======================================================================================================================
#== CONSTRUCTION =======================================================================================================
#=======================================================================================================================

proc initUnionFind*(n: int): UnionFind =
  ## Create a union-find structure with `n` elements, each in its own set.
  result.parent.setLen(n)
  result.rank.setLen(n)
  result.count = n
  for i in 0 ..< n:
    result.parent[i] = i
    # rank[i] is already 0 from setLen.

#=======================================================================================================================
#== OPERATIONS =========================================================================================================
#=======================================================================================================================

proc find*(uf: var UnionFind, x: int): int =
  ## Find the representative of the set containing `x`.
  ## Applies path compression.
  var node = x
  while uf.parent[node] != node:
    # Path splitting: make every node on the path point to its grandparent.
    let next = uf.parent[node]
    uf.parent[node] = uf.parent[next]
    node = next
  node

proc union*(uf: var UnionFind, x, y: int): bool {.discardable.} =
  ## Merge the sets containing `x` and `y`.
  ## Returns true if a merge occurred (they were in different sets).
  var rx = uf.find(x)
  var ry = uf.find(y)
  if rx == ry:
    return false
  # Union by rank: attach smaller tree under larger.
  if uf.rank[rx] < uf.rank[ry]:
    swap(rx, ry)
  uf.parent[ry] = rx
  if uf.rank[rx] == uf.rank[ry]:
    uf.rank[rx] += 1
  uf.count -= 1
  true

proc connected*(uf: var UnionFind, x, y: int): bool =
  ## Check whether `x` and `y` are in the same set.
  uf.find(x) == uf.find(y)

#=======================================================================================================================
#== ACCESSORS ==========================================================================================================
#=======================================================================================================================

func setCount*(uf: UnionFind): int =
  ## Number of disjoint sets.
  uf.count

func size*(uf: UnionFind): int =
  ## Total number of elements.
  uf.parent.len
