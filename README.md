# graph

Pure Nim graph algorithm library with 53 algorithms. Covers traversal, shortest paths, MST, flow, centrality, community detection, coloring, matching, isomorphism, and more.

## Install

```
nimble install
```

## Usage

```nim
import graph

var g = new_graph(5)
g.add_edge(0, 1, 1.0)
g.add_edge(1, 2, 2.0)
let dist = dijkstra(g, 0)
```

## License

Proprietary
