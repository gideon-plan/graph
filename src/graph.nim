#[
=====
Graph
=====
]#
{.experimental: "strictFuncs".}

{.push raises: [Defect].}

############
## Import ##
############

# graph...
import graph/types
import graph/convert
import graph/unionfind
import graph/traversal
import graph/shortest_path
import graph/kpaths
import graph/mst
import graph/components
import graph/dag
import graph/distance
import graph/centrality
import graph/community
import graph/flow
import graph/matching
import graph/clique
import graph/coloring
import graph/cores
import graph/clustering
import graph/isomorphism
import graph/cover
import graph/embedding
import graph/tour
import graph/generation

import basis/code/throw
standard_pragmas(effects=false, rise=false)

############
## Export ##
############

# graph...
export types
export convert
export unionfind
export traversal
export shortest_path
export kpaths
export mst
export components
export dag
export distance
export centrality
export community
export flow
export matching
export clique
export coloring
export cores
export clustering
export isomorphism
export cover
export embedding
export tour
export generation
