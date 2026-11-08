# The offline suite drives acquisition through injected transports and
# fixtures. Keep it on that path: held historical files would otherwise be read
# from the package's GitHub release, a network call. test-release-sources.R
# turns delivery back on locally and uses injected transports only.
withr::local_options(njschooldata.release_sources = FALSE,
                     .local_envir = testthat::teardown_env())
