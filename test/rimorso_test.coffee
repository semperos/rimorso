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

    it "should provide a meaningful default message if none is provided", ->
      err = new R.AbstractMethodError
      err.message.should.match /abstract\s+method/
      err.message.should.match /subclass/

    it "should use a custom message if provided", ->
      msg = "Custom abstract method error message"
      err = new R.AbstractMethodError msg
      err.message.should.equal msg

describe 'Type checking', ->
  describe 'Type comparison with Is class', ->

    s = "foo"
    sClass = "[object String]"
    n = 42
    nClass = "[object Number]"
    class TestClass
    testObj = new TestClass
    a = [1,2,3]
    aClass = "[object Array]"
    o = foo: "bar"
    oClass = "[object Object]"

    it "should provide a way to get the class of a data structure", ->
      R.Is.getClass(s).should.equal sClass
      R.Is.getClass(n).should.equal nClass

    it "should differentiate between Objects and Arrays", ->
      R.Is.getClass(a).should.equal aClass
      R.Is.getClass(o).should.equal oClass
      R.Is.getClass(a).should.not.equal(R.Is.getClass(o))

    it "should provide a way to get the prototype of an object", ->
      R.Is.getPrototype(testObj).should.equal TestClass.prototype

    it "should provide map class information to a type", ->
      R.Is.getType(s).should.equal "string"
      R.Is.getType(n).should.equal "number"
      R.Is.getType(testObj).should.equal "object"

    describe 'Convenience type comparison functions', ->

      it 'should support booleans', ->
        R.Is.isBoolean(true).should.be.true
        R.Is.isBoolean(false).should.be.true

      it 'should not consider truthy/falsey as booleans', ->
        R.Is.isBoolean("").should.be.false
        R.Is.isBoolean(0).should.be.false

      it 'should support numers', ->
        R.Is.isNumber(42).should.be.true
        R.Is.isNumber(4.2).should.be.true

      it "should not consider strings as numbers", ->
        R.Is.isNumber("42").should.be.false

      it 'should support strings', ->
        R.Is.isString("foo").should.be.true
        R.Is.isString('').should.be.true

      describe 'Functions', ->
        it 'should support anonymous functions', ->
          R.Is.isFunction(->).should.be.true
          R.Is.isFunction((a,b) -> a+b).should.be.true

        it 'should support anonymous functions attached to vars', ->
          fn = (a,b) -> a+b
          R.Is.isFunction(fn).should.be.true

        it 'should support constructor functions/CoffeeScript classes', ->
          class Foo
          R.Is.isFunction(Foo).should.be.true
          f = new Foo
          R.Is.isFunction(f.constructor).should.be.true

        it 'should not consider regular expressions to be functions', ->
          r = /foo/
          R.Is.isFunction(r).should.be.false

      it 'should support arrays', ->
        a = [1,2,3]
        b = [{foo: "bar", bam: "boom"}, {js: "proto", java: "class"}]
        R.Is.isArray(a).should.be.true
        R.Is.isArray(b).should.be.true
        R.Is.isArray(b[0]).should.be.false

      it 'should support dates', ->
        d = new Date
        x = 42
        R.Is.isDate(d).should.be.true
        R.Is.isDate(x).should.be.false

      it 'should support regular expressions', ->
        r = /foo/
        x = "foo"
        R.Is.isRegExp(r).should.be.true
        R.Is.isRegExp(x).should.be.false
        R.Is.isRegExp(new RegExp(x)).should.be.true

      describe 'Objects', ->
        it 'should support regular objects', ->
          o = foo: "bar"
          R.Is.isObject(o).should.be.true
          R.Is.isObject(o.constructor.prototype).should.be.true

        it 'should not confuse arrays with objects', ->
          a = [1,2,3]
          R.Is.isObject(a).should.be.false

      it 'should support errors', ->
        err1 = new Error
        err2 = new R.AbstractMethodError
        R.Is.isError(err1).should.be.true
        R.Is.isError(err2).should.be.false

      describe 'Null', ->
        it 'should support null values', ->
          x = null
          y = 42
          R.Is.isNull(x).should.be.true
          R.Is.isNull(y).should.be.false

        it 'should not consider undefined to be null', ->
          z = undefined
          R.Is.isNull(z).should.be.false

      describe 'Undefined', ->
        it 'should support values that are undefined', ->
          a = undefined
          b = 42
          R.Is.isUndefined(a).should.be.true
          R.Is.isUndefined(b).should.be.false

        it 'should not consider null to be undefined', ->
          c = null
          R.Is.isUndefined(c).should.be.false
