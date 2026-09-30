# njschooldata Instructions

Follow [../AGENTS.md](../AGENTS.md) for shared state-schooldata instructions.

## Data and Plot Caching

Set global knitr `cache = FALSE`. Keep data fetching and plotting in separate
chunks: data-fetching chunks use `cache = TRUE`; plot chunks use `cache = FALSE`
(or inherit the global default). Never put data fetching and ggplot code in the
same cached chunk.
