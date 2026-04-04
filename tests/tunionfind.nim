{.experimental: "strictFuncs".}
## Union-find tests.

import std/unittest

import graph/unionfind

suite "union-find":
  test "initial state":
    var uf = initUnionFind(5)
    check uf.size == 5
    check uf.setCount == 5
    # Each element is its own representative.
    for i in 0 ..< 5:
      check uf.find(i) == i

  test "union merges sets":
    var uf = initUnionFind(5)
    check uf.union(0, 1) == true
    check uf.setCount == 4
    check uf.connected(0, 1)
    check not uf.connected(0, 2)

  test "union returns false for same set":
    var uf = initUnionFind(5)
    uf.union(0, 1)
    check uf.union(0, 1) == false
    check uf.setCount == 4

  test "transitive connectivity":
    var uf = initUnionFind(6)
    uf.union(0, 1)
    uf.union(1, 2)
    check uf.connected(0, 2)
    check uf.setCount == 4

  test "separate components":
    var uf = initUnionFind(6)
    uf.union(0, 1)
    uf.union(2, 3)
    check uf.connected(0, 1)
    check uf.connected(2, 3)
    check not uf.connected(0, 2)
    check not uf.connected(1, 3)
    check uf.setCount == 4

  test "merge all into one set":
    var uf = initUnionFind(5)
    uf.union(0, 1)
    uf.union(2, 3)
    uf.union(0, 2)
    uf.union(3, 4)
    check uf.setCount == 1
    for i in 0 ..< 5:
      for j in 0 ..< 5:
        check uf.connected(i, j)

  test "path compression":
    var uf = initUnionFind(10)
    # Build a chain: 0-1-2-3-4-5-6-7-8-9.
    for i in 0 ..< 9:
      uf.union(i, i + 1)
    check uf.setCount == 1
    # After find, path compression should flatten the tree.
    let root = uf.find(0)
    let root2 = uf.find(9)
    check root == root2

  test "single element":
    var uf = initUnionFind(1)
    check uf.size == 1
    check uf.setCount == 1
    check uf.find(0) == 0
