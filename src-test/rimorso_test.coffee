#
# Prelude - see bootstrap.coffee for definitions
#
if (typeof exports is 'object')
  R = root.Rimorso
  failMessage = root.failMessage
else
  R = window.Rimorso
  failMessage = window.failMessage

describe 'Housekeeping', ->
  describe 'Custom errors', ->
    it "should provide a custom error class for abstract methods", ->
      err = new R.__impl.AbstractMethodError
      expect(err).to.be.an Error

    it "should provide a meaningful default message if none is provided", ->
      err = new R.__impl.AbstractMethodError
      expect(err.message).to.match /abstract\s+method/
      expect(err.message).to.match /subclass/

    it "should use a custom message if provided", ->
      msg = "Custom abstract method error message"
      err = new R.__impl.AbstractMethodError msg
      expect(err.message).to.equal msg

describe 'Type comparison', ->
  describe 'Is class', ->

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
      expect(R.Is.getClass(s)).to.equal sClass
      expect(R.Is.getClass(n)).to.equal nClass

    it "should differentiate between Objects and Arrays", ->
      expect(R.Is.getClass(a)).to.equal aClass
      expect(R.Is.getClass(o)).to.equal oClass
      expect(R.Is.getClass(a)).not.to.equal (R.Is.getClass(o))

    it "should provide a way to get the prototype of an object", ->
      expect(R.Is.getPrototype(testObj)).to.equal TestClass.prototype

    it "should provide map class information to a type", ->
      expect(R.Is.getType(s)).to.equal "String"
      expect(R.Is.getType(n)).to.equal "Number"
      expect(R.Is.getType(testObj)).to.equal "Object"

    describe 'Convenience type comparison functions', ->

      it 'should support booleans', ->
        expect(R.Is.a.boolean(true)).to.be true
        expect(R.Is.a.boolean(false)).to.be true

      it 'should not consider truthy/falsey as booleans', ->
        expect(R.Is.a.boolean("")).to.be false
        expect(R.Is.a.boolean(0)).to.be false

      it 'should support numers', ->
        expect(R.Is.a.number(42)).to.be true
        expect(R.Is.a.number(4.2)).to.be true

      it "should not consider strings as numbers", ->
        expect(R.Is.a.number("42")).to.be false

      it 'should support strings', ->
        expect(R.Is.a.string("foo")).to.be true
        expect(R.Is.a.string('')).to.be true

      describe 'Functions', ->
        it 'should support anonymous functions', ->
          expect(R.Is.a.function(->)).to.be true
          expect(R.Is.a.function((a,b) -> a+b)).to.be true

        it 'should support anonymous functions attached to vars', ->
          fn = (a,b) -> a+b
          expect(R.Is.a.function(fn)).to.be true

        it 'should support constructor functions/CoffeeScript classes', ->
          class Foo
          expect(R.Is.a.function(Foo)).to.be true
          f = new Foo
          expect(R.Is.a.function(f.constructor)).to.be true

        it 'should not consider regular expressions to be functions', ->
          r = /foo/
          expect(R.Is.a.function(r)).to.be false

      it 'should support arrays', ->
        a = [1,2,3]
        b = [{foo: "bar", bam: "boom"}, {js: "proto", java: "class"}]
        expect(R.Is.an.array(a)).to.be true
        expect(R.Is.an.array(b)).to.be true
        expect(R.Is.an.array(b[0])).to.be false

      it 'should support dates', ->
        d = new Date
        x = 42
        expect(R.Is.a.date(d)).to.be true
        expect(R.Is.a.date(x)).to.be false

      it 'should support regular expressions', ->
        r = /foo/
        x = "foo"
        expect(R.Is.a.regexp(r)).to.be true
        expect(R.Is.a.regexp(x)).to.be false
        expect(R.Is.a.regexp(new RegExp(x))).to.be true

      describe 'Objects', ->
        it 'should support regular objects', ->
          o = foo: "bar"
          expect(R.Is.an.object(o)).to.be true
          expect(R.Is.an.object(o.constructor.prototype)).to.be true

        it 'should not confuse arrays with objects', ->
          a = [1,2,3]
          expect(R.Is.an.object(a)).to.be false

      it 'should support errors', ->
        err1 = new Error
        err2 = new R.__impl.AbstractMethodError
        expect(R.Is.an.error(err1)).to.be true
        expect(R.Is.an.error(err2)).to.be false

      describe 'Null', ->
        it 'should support null values', ->
          x = null
          y = 42
          expect(R.Is.null(x)).to.be true
          expect(R.Is.null(y)).to.be false

        it 'should not consider undefined to be null', ->
          z = undefined
          expect(R.Is.null(z)).to.be false

      describe 'Undefined', ->
        it 'should support values that are undefined', ->
          a = undefined
          b = 42
          expect(R.Is.undefined(a)).to.be true
          expect(R.Is.undefined(b)).to.be false

        it 'should not consider null to be undefined', ->
          c = null
          expect(R.Is.undefined(c)).to.be false

describe 'Type checking functions', ->
  describe 'Labels for Functions', ->

    fnName = "testName"
    aLabel = new R.__impl.Label fnName

    it 'should hold the name of a function', ->
      expect(aLabel.name).to.equal fnName

    describe 'Polarity', ->

      it 'should keep track of polarity (domain vs. range)', ->
        expect(aLabel.name).to.be.ok

      it 'should provide a method to reverse polarity', ->
        orig = aLabel.polarity
        expect(aLabel.complement().polarity).to.equal (not orig)

      it 'should indicate polarity in the toString', ->
        aLabel.polarity = false
        expect(aLabel.toString()).to.match /^~/

    describe 'Reason', ->

      it 'should have an empty reason by default', ->
        expect(aLabel.reason).to.be.empty

      it 'should include the reason in toString if present', ->
        reason = "Expected: Foo, Actual: Bar"
        reasonR = new RegExp reason
        expect(aLabel.toString()).not.to.match reasonR
        aLabel.setReason reason
        expect(aLabel.toString()).to.match reasonR

      it 'should provide a format for describing expected/actual types', ->
        aLabel.setReason "foo", 'Number'
        expect(aLabel.toString()).to.match /Value:\s+foo/
        expect(aLabel.toString()).to.match /Expected:\s+Number/
        expect(aLabel.toString()).to.match /Actual:\s+String/

  describe 'Contracts', ->
    describe 'Default contract', ->

      fnName = "testFn"
      aLabel = new R.__impl.Label fnName
      aLabel.setReason 42, 'function'
      aContract = new R.__impl.Contract aLabel

      it "should provide an abstract definition for 'restrict'", ->
        expect(-> aContract.restrict()).to.throwError R.__impl.AbstractMethodError

      it "should provide an abstract definition for 'relax'", ->
        expect(-> aContract.relax()).to.throwError R.__impl.AbstractMethodError

      it "should provide a fail method that throws an error", ->
        expect(-> aContract.fail()).to.throwError TypeError

      it "should provide a meaningful message from a failure derived from its label", ->
        expect(-> aContract.fail()).to.throwError /function/
        expect(-> aContract.fail()).to.throwError /42/

    describe "Integer contract", ->

      fnName = "additionFunction"
      aLabel = new R.__impl.Label fnName
      ic = new R.__impl.IntegerContract aLabel

      it "should let integer values pass through", ->
        expect(ic.restrict(42)).to.equal 42
        expect(ic.relax(42)).to.equal 42

      it "should not allow non-integer numbers to pass", ->
        expect(-> ic.restrict(4.2)).to.throwError TypeError
        expect(-> ic.relax(4.2)).to.throwError TypeError

    describe "Number contract", ->

      fnName = "additionFunction"
      aLabel = new R.__impl.Label fnName
      nc = new R.__impl.NumberContract aLabel

      it "should let number values pass through", ->
        expect(nc.restrict(42)).to.equal 42
        expect(nc.relax(42)).to.equal 42

      it "shouldn't care whether it's an integer or not", ->
        expect(nc.restrict(42)).to.equal 42
        expect(nc.restrict(4.2)).to.equal 4.2

      it "should fail on non-numeric values", ->
        expect(-> nc.restrict("foo")).to.throwError TypeError
        expect(-> nc.relax(() ->)).to.throwError TypeError

    describe "String contract", ->

      fnName = "concatFunction"
      aLabel = new R.__impl.Label fnName
      sc = new R.__impl.StringContract aLabel

      it "should let string values pass through", ->
        expect(sc.restrict("foo")).to.equal "foo"
        expect(sc.relax("bar")).to.equal "bar"

      it "should not let non-string values pass", ->
        expect(-> sc.restrict(42)).to.throwError TypeError
        expect(-> sc.relax(() ->)).to.throwError TypeError

    describe "Unit contract", ->

      fnName = "aFunction"
      aLabel = new R.__impl.Label fnName
      uc = new R.__impl.UnitContract aLabel

      it "should let 'undefined' values pass through", ->
        x = console.log()
        expect(uc.restrict(x)).to.be undefined

      it "should not let 'real' values through", ->
        x = "foo"
        y = 42
        expect(-> uc.restrict x).to.throwError TypeError
        expect(-> uc.restrict y).to.throwError TypeError

    describe "Empty contract", ->

      fnName = "aFunction"
      aLabel = new R.__impl.Label fnName
      ec = new R.__impl.EmptyContract aLabel

      it "should let 'undefined' values pass through", ->
        x = console.log()
        expect(ec.restrict(x)).to.be undefined

      it "should not let 'real' values through", ->
        x = "foo"
        y = 42
        expect(-> ec.restrict x).to.throwError TypeError
        expect(-> ec.restrict y).to.throwError TypeError

    describe "Function contract", ->

      fnName = "fnFunction"
      aLabel = new R.__impl.Label fnName
      icDomain = new R.__impl.IntegerContract aLabel
      icRange = new R.__impl.IntegerContract aLabel
      fc = new R.__impl.FunctionContract aLabel, icDomain, icRange

      it "should let function values pass through", ->
        expect(fc.restrict(() ->)).to.be.a 'function'
        expect(fc.restrict((n) -> n*2)(21)).to.equal 42
        expect(fc.relax(() ->)).to.be.a 'function'
        expect(fc.relax((n) -> n*2)(21)).to.equal 42

      it "should not let non-function values pass", ->
        expect(-> fc.restrict(42)).to.throwError TypeError
        expect(-> fc.restrict(/test/)).to.throwError TypeError

  describe 'Spec parser', ->

    before ->
      input = 'add :: Int -> Int -> Int'
      @output = ['add', ' ', ':', ':', ' ', 'Int', ' ', '->', ' ', 'Int', ' ', '->', ' ', 'Int']
      @parser = new R.__impl.SpecParser(input)

    it 'should return a function that takes a label and returns a contract', ->
      splitOutput = @parser.split()
      expect(splitOutput).to.eql @output
