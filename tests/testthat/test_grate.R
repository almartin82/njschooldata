context('grate')

testthat('fetch grate works properly', {
  
  ex <- fetch_grate(2015)
  expect_is(ex, 'data.frame')
  expect_equal(sum(ex$num_grad, na.rm = TRUE), na.rm = TRUE)
})