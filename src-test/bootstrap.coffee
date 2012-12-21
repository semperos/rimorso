prettyArray = (arr) ->
  items = for x in arr
    x + ''
  items.join(', ')

array2columns = (a1, a2) ->
  pad = (arr, num) ->
    for n in [1..num]
      arr.push '(no item)'
    arr
  diff = a1.length - a2.length
  if diff < 0
    a1 = pad(a1, Math.abs(diff))
  else if diff isnt 0
    a2 = pad(a2, diff)
  for x,idx in a1
    '  ' + x + ' : ' + a2[idx] + '\n'

failMessage = (expected, actual, type = 'object') ->
  switch type
    when 'array'
      "Expected : Actual\n" +
        array2columns(expected, actual)
    else
      "Expected:\n#{expected}\nActual:\n#{actual}"

# Node
if (typeof exports is 'object')
  expect = require 'expect.js'
  root.expect = expect

  # Helpers
  root.prettyArray = prettyArray
  root.failMessage = failMessage

  # Library
  root.Rimorso = require "../"
# Browser
else
  mocha.setup
    ui: "bdd"
  # Bug in expect.js' throwException
  globals: ["message", "name"]

  # Helpers
  window.prettyArray = prettyArray
  window.failMessage = failMessage
