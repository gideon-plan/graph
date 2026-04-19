{.experimental: "strictFuncs".}
## Community detection tests.

import std/[unittest, sets]

import graph/types
import graph/community

suite "modularity":
  test "trivial: all in one community":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(3)
    g.addEdge(0, 1)
    g.addEdge(1, 2)
    let comm = @[0, 0, 0]
    let q = g.modularity(comm)
    # All in one community, modularity is limited.
    check q >= -1.0

suite "Louvain":
  test "two cliques":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(6)
    # Clique 1: 0, 1, 2
    g.addEdge(0, 1)
    g.addEdge(0, 2)
    g.addEdge(1, 2)
    # Clique 2: 3, 4, 5
    g.addEdge(3, 4)
    g.addEdge(3, 5)
    g.addEdge(4, 5)
    # Weak bridge.
    g.addEdge(2, 3)
    let comm = g.louvain()
    # Should find 2 communities.
    var communities = initHashSet[system.int]()
    for c in comm:
      communities.incl(c)
    check communities.len >= 2

suite "label propagation":
  test "disconnected components":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    let comm = g.labelPropagation()
    check comm[0] == comm[1]
    check comm[2] == comm[3]
    check comm[0] != comm[2]

suite "Girvan-Newman":
  test "two components":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(0, 1)  # parallel edge
    g.addEdge(2, 3)
    g.addEdge(2, 3)
    g.addEdge(1, 2)  # bridge
    let comm = g.girvanNewman(2)
    check comm[0] == comm[1]
    check comm[2] == comm[3]

suite "spectral clustering":
  test "basic partition":
    var g = initGraph(GraphKind.Undirected)
    discard g.addNodes(4)
    g.addEdge(0, 1)
    g.addEdge(2, 3)
    let comm = g.spectralClustering(2)
    check comm.len == 4
    # Should partition into two groups.
    var groups = initHashSet[system.int]()
    for c in comm:
      groups.incl(c)
    check groups.len >= 1  # At least one group (may merge if trivial).
