#[
======
Clique
======

Bron-Kerbosch max clique and clique enumeration.
]#

{.push raises: [Defect].}

# std...
import std/sets

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== BRON-KERBOSCH ======================================================================================================
#=======================================================================================================================

proc bronKerbosch*(g: Graph): seq[seq[NodeId]] =
  ## Enumerate all maximal cliques using Bron-Kerbosch with pivot.
  var cliques: seq[seq[NodeId]]

  proc neighborSet(v: system.int): HashSet[system.int] =
    for e in g.neighbors(NodeId(v)):
      result.incl(e.target.int)

  proc bk(r, p, x: HashSet[system.int]) =
    if p.len == 0 and x.len == 0:
      var clique: seq[NodeId]
      for v in r:
        clique.add(NodeId(v))
      cliques.add(clique)
      return

    # Choose pivot with maximum connections to P.
    var pivot = -1
    var maxConn = -1
    for u in p + x:
      let ns = neighborSet(u)
      let conn = (p * ns).len
      if conn > maxConn:
        maxConn = conn
        pivot = u

    let pivotNeighbors = if pivot >= 0: neighborSet(pivot) else: initHashSet[system.int]()
    let candidates = p - pivotNeighbors

    var pMut = p
    var xMut = x
    for v in candidates:
      let ns = neighborSet(v)
      bk(r + [v].toHashSet, pMut * ns, xMut * ns)
      pMut.excl(v)
      xMut.incl(v)

  var allNodes = initHashSet[system.int]()
  for i in 0 ..< g.nodeCount:
    allNodes.incl(i)

  bk(initHashSet[system.int](), allNodes, initHashSet[system.int]())
  cliques

proc maxClique*(g: Graph): seq[NodeId] =
  ## Find the maximum clique (largest by size).
  let cliques = g.bronKerbosch()
  if cliques.len == 0:
    return @[]
  var best = 0
  for i in 1 ..< cliques.len:
    if cliques[i].len > cliques[best].len:
      best = i
  cliques[best]

proc cliqueCount*(g: Graph): system.int =
  ## Number of maximal cliques.
  g.bronKerbosch().len
