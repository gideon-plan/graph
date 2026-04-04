{.experimental: "strictFuncs".}
## Generation tests.

import std/unittest

import graph/types
import graph/generation

suite "Erdos-Renyi":
  test "generates correct node count":
    let g = erdosRenyi(20, 0.3)
    check g.nodeCount == 20

  test "p=0 has no edges":
    let g = erdosRenyi(10, 0.0)
    check g.edgeCount == 0

  test "p=1 is complete":
    let g = erdosRenyi(5, 1.0)
    check g.edgeCount == 10  # C(5,2)

suite "Barabasi-Albert":
  test "correct node count":
    let g = barabasiAlbert(20, 2)
    check g.nodeCount == 20

  test "has edges":
    let g = barabasiAlbert(10, 2)
    check g.edgeCount > 0

suite "random walk graph":
  test "correct node count":
    let g = randomWalkGraph(10, 20)
    check g.nodeCount == 10

  test "has edges after steps":
    let g = randomWalkGraph(10, 50)
    check g.edgeCount > 0
