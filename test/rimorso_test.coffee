chai = require 'chai'

assert = chai.assert
expect = chai.expect
should = chai.should()

describe 'First test', ->
  it 'should work', ->
    "foo".should.equal "foo"