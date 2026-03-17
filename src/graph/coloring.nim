#[
========
Coloring
========

Greedy graph coloring.
]#

{.push raises: [Defect].}

# std...
import std/sets

# graph...
import types

import basis/code/throw
standard_pragmas(effects=false, rise=false)

#=======================================================================================================================
#== GREEDY COLORING ====================================================================================================
#=======================================================================================================================

proc greedyColoring*(g: Graph): seq[system.int] =
  ## Greedy graph coloring. Returns color assignment per node.
  ## Colors are non-negative integers starting from 0.
  let n = g.nodeCount
  result.setLen(n)
  for i in 0 ..< n:
    result[i] = -1

  for i in 0 ..< n:
    var usedColors = initHashSet[system.int]()
    for e in g.neighbors(NodeId(i)):
      if result[e.target.int] >= 0:
        usedColors.incl(result[e.target.int])
    # Assign smallest available color.
    var color = 0
    while color in usedColors:
      color += 1
    result[i] = color

proc chromaticUpperBound*(g: Graph): system.int =
  ## Upper bound on chromatic number from greedy coloring.
  let colors = g.greedyColoring()
  var maxColor = 0
  for c in colors:
    if c > maxColor:
      maxColor = c
  maxColor + 1
