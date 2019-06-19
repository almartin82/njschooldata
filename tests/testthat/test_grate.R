context('grate')

test_that('fetch grate works properly', {
  ex <- fetch_grate(2015)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$graduated_count, na.rm = TRUE), 674621)
})