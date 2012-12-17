# Node
if (typeof exports is 'object')
  chai = require 'chai'
  assert = chai.assert
  expect = chai.expect
  chai.should()

  root.Rimorso = require "../"
# Browser
else
  mocha.setup
    ui: "bdd"

  assert = window.chai.assert
  expect = window.chai.expect
  window.chai.should()
