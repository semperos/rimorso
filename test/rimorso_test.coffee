# See bootstrap.coffee
if (typeof exports is 'object')
  R = root.Rimorso
else
  R = window.Rimorso

describe 'Housekeeping', ->
  describe 'Custom errors', ->
    it "should provide a custom error class for abstract methods", ->
      err = new R.AbstractMethodError
      err.should.be.instanceOf Error