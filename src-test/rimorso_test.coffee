#
# Prelude - see bootstrap.coffee for definitions
#
if (typeof exports is 'object')
  assert = root.assert
  expect = root.expect
  R = root.Rimorso
  failMessage = root.failMessage
else
  assert = window.assert
  expect = window.expect
  R = window.Rimorso
  failMessage = window.failMessage

describe 'Housekeeping', ->
  describe 'Custom errors', ->
    it "should provide a custom error class for abstract methods", ->
      err = new R.__impl.AbstractMethodError
      err.should.be.instanceOf Error

    it "should provide a meaningful default message if none is provided", ->
      err = new R.__impl.AbstractMethodError
      err.message.should.match /abstract\s+method/
      err.message.should.match /subclass/

    it "should use a custom message if provided", ->
      msg = "Custom abstract method error message"
      err = new R.__impl.AbstractMethodError msg
      err.message.should.equal msg

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
      R.Is.getClass(s).should.equal sClass
      R.Is.getClass(n).should.equal nClass

    it "should differentiate between Objects and Arrays", ->
      R.Is.getClass(a).should.equal aClass
      R.Is.getClass(o).should.equal oClass
      R.Is.getClass(a).should.not.equal(R.Is.getClass(o))

    it "should provide a way to get the prototype of an object", ->
      R.Is.getPrototype(testObj).should.equal TestClass.prototype

    it "should provide map class information to a type", ->
      R.Is.getType(s).should.equal "String"
      R.Is.getType(n).should.equal "Number"
      R.Is.getType(testObj).should.equal "Object"

    describe 'Convenience type comparison functions', ->

      it 'should support booleans', ->
        R.Is.a.boolean(true).should.be.true
        R.Is.a.boolean(false).should.be.true

      it 'should not consider truthy/falsey as booleans', ->
        R.Is.a.boolean("").should.be.false
        R.Is.a.boolean(0).should.be.false

      it 'should support numers', ->
        R.Is.a.number(42).should.be.true
        R.Is.a.number(4.2).should.be.true

      it "should not consider strings as numbers", ->
        R.Is.a.number("42").should.be.false

      it 'should support strings', ->
        R.Is.a.string("foo").should.be.true
        R.Is.a.string('').should.be.true

      describe 'Functions', ->
        it 'should support anonymous functions', ->
          R.Is.a.function(->).should.be.true
          R.Is.a.function((a,b) -> a+b).should.be.true

        it 'should support anonymous functions attached to vars', ->
          fn = (a,b) -> a+b
          R.Is.a.function(fn).should.be.true

        it 'should support constructor functions/CoffeeScript classes', ->
          class Foo
          R.Is.a.function(Foo).should.be.true
          f = new Foo
          R.Is.a.function(f.constructor).should.be.true

        it 'should not consider regular expressions to be functions', ->
          r = /foo/
          R.Is.a.function(r).should.be.false

      it 'should support arrays', ->
        a = [1,2,3]
        b = [{foo: "bar", bam: "boom"}, {js: "proto", java: "class"}]
        R.Is.an.array(a).should.be.true
        R.Is.an.array(b).should.be.true
        R.Is.an.array(b[0]).should.be.false

      it 'should support dates', ->
        d = new Date
        x = 42
        R.Is.a.date(d).should.be.true
        R.Is.a.date(x).should.be.false

      it 'should support regular expressions', ->
        r = /foo/
        x = "foo"
        R.Is.a.regexp(r).should.be.true
        R.Is.a.regexp(x).should.be.false
        R.Is.a.regexp(new RegExp(x)).should.be.true

      describe 'Objects', ->
        it 'should support regular objects', ->
          o = foo: "bar"
          R.Is.an.object(o).should.be.true
          R.Is.an.object(o.constructor.prototype).should.be.true

        it 'should not confuse arrays with objects', ->
          a = [1,2,3]
          R.Is.an.object(a).should.be.false

      it 'should support errors', ->
        err1 = new Error
        err2 = new R.__impl.AbstractMethodError
        R.Is.an.error(err1).should.be.true
        R.Is.an.error(err2).should.be.false

      describe 'Null', ->
        it 'should support null values', ->
          x = null
          y = 42
          R.Is.null(x).should.be.true
          R.Is.null(y).should.be.false

        it 'should not consider undefined to be null', ->
          z = undefined
          R.Is.null(z).should.be.false

      describe 'Undefined', ->
        it 'should support values that are undefined', ->
          a = undefined
          b = 42
          R.Is.undefined(a).should.be.true
          R.Is.undefined(b).should.be.false

        it 'should not consider null to be undefined', ->
          c = null
          R.Is.undefined(c).should.be.false

describe 'Type checking functions', ->
  describe 'Labels for Functions', ->

    fnName = "testName"
    aLabel = new R.__impl.Label fnName

    it 'should hold the name of a function', ->
      aLabel.name.should.equal fnName

    describe 'Polarity', ->

      it 'should keep track of polarity (domain vs. range)', ->
        aLabel.name.should.be.ok

      it 'should provide a method to reverse polarity', ->
        orig = aLabel.polarity
        aLabel.complement().polarity.should.equal (not orig)

      it 'should indicate polarity in the toString', ->
        aLabel.polarity = false
        aLabel.toString().should.match /^~/

    describe 'Reason', ->

      it 'should have an empty reason by default', ->
        aLabel.reason.should.be.empty

      it 'should include the reason in toString if present', ->
        reason = "Expected: Foo, Actual: Bar"
        reasonR = new RegExp reason
        aLabel.toString().should.not.match reasonR
        aLabel.setReason reason
        aLabel.toString().should.match reasonR

      it 'should provide a format for describing expected/actual types', ->
        aLabel.setReason "foo", 'Number'
        aLabel.toString().should.match /Value:\s+foo/
        aLabel.toString().should.match /Expected:\s+Number/
        aLabel.toString().should.match /Actual:\s+String/

  describe 'Contracts', ->
    describe 'Default contract', ->

      fnName = "testFn"
      aLabel = new R.__impl.Label fnName
      aLabel.setReason 42, 'function'
      aContract = new R.__impl.Contract aLabel

      it "should provide an abstract definition for 'restrict'", ->
        (=> aContract.restrict()).should.throw R.__impl.AbstractMethodError

      it "should provide an abstract definition for 'relax'", ->
        (=> aContract.relax()).should.throw R.__impl.AbstractMethodError

      it "should provide a fail method that throws an error", ->
        (=> aContract.fail()).should.throw TypeError

      it "should provide a meaningful message from a failure derived from its label", ->
        (=> aContract.fail()).should.throw /function/
        (=> aContract.fail()).should.throw /42/

    describe "Integer contract", ->

      fnName = "additionFunction"
      aLabel = new R.__impl.Label fnName
      ic = new R.__impl.IntegerContract aLabel

      it "should let integer values pass through", ->
        ic.restrict(42).should.equal 42
        ic.relax(42).should.equal 42

      it "should not allow non-integer numbers to pass", ->
        (=> ic.restrict(4.2)).should.throw TypeError
        (=> ic.relax(4.2)).should.throw TypeError

    describe "Number contract", ->

      fnName = "additionFunction"
      aLabel = new R.__impl.Label fnName
      nc = new R.__impl.NumberContract aLabel

      it "should let number values pass through", ->
        nc.restrict(42).should.equal 42
        nc.relax(42).should.equal 42

      it "shouldn't care whether it's an integer or not", ->
        nc.restrict(42).should.equal 42
        nc.restrict(4.2).should.equal 4.2

      it "should fail on non-numeric values", ->
        (=> nc.restrict("foo")).should.throw TypeError
        (=> nc.relax(() ->)).should.throw TypeError

    describe "String contract", ->

      fnName = "concatFunction"
      aLabel = new R.__impl.Label fnName
      sc = new R.__impl.StringContract aLabel

      it "should let string values pass through", ->
        sc.restrict("foo").should.equal "foo"
        sc.relax("bar").should.equal "bar"

      it "should not let non-string values pass", ->
        (=> sc.restrict(42)).should.throw TypeError
        (=> sc.relax(() ->)).should.throw TypeError

    describe "Unit contract", ->

      fnName = "aFunction"
      aLabel = new R.__impl.Label fnName
      uc = new R.__impl.UnitContract aLabel

      it "should let 'undefined' values pass through", ->
        x = console.log()
        expect(uc.restrict(x)).to.be.undefined

      it "should not let 'real' values through", ->
        x = "foo"
        y = 42
        expect(=> uc.restrict x).to.throw TypeError
        expect(=> uc.restrict y).to.throw TypeError

    describe "Empty contract", ->

      fnName = "aFunction"
      aLabel = new R.__impl.Label fnName
      ec = new R.__impl.EmptyContract aLabel

      it "should let 'undefined' values pass through", ->
        x = console.log()
        expect(ec.restrict(x)).to.be.undefined

      it "should not let 'real' values through", ->
        x = "foo"
        y = 42
        expect(=> ec.restrict x).to.throw TypeError
        expect(=> ec.restrict y).to.throw TypeError

    describe "Function contract", ->

      fnName = "fnFunction"
      aLabel = new R.__impl.Label fnName
      icDomain = new R.__impl.IntegerContract aLabel
      icRange = new R.__impl.IntegerContract aLabel
      fc = new R.__impl.FunctionContract aLabel, icDomain, icRange

      it "should let function values pass through", ->
        fc.restrict(() ->).should.be.a 'function'
        fc.restrict((n) -> n*2)(21).should.equal 42
        fc.relax(() ->).should.be.a 'function'
        fc.relax((n) -> n*2)(21).should.equal 42

      it "should not let non-function values pass", ->
        (=> fc.restrict(42)).should.throw TypeError
        (=> fc.restrict(/test/)).should.throw TypeError

  ## Test Parser ##

  describe 'Spec parser', ->

    before ->
      input = 'add :: Int -> Int -> Int'
      @output = ['add', ':', ':', 'Int', '->', 'Int', '->', 'Int']
      @parser = new R.__impl.SpecParser(input)

    it "should split up a type spec string correctly", ->
      splitOutput = @parser.split()
      splitOutput.should.eql @output

    it 'should return a function that takes a label and returns a contract', ->
      @parser.parse(@input).should.be.a 'function'

  ## Public-facing API ##

  describe 'End-to-end type checking with Rimorso.T', ->
    describe 'Functions', ->

      before ->
        @passTwo = R.T 'passTwo :: (Int -> Int) -> Int', (f) -> f 2
        @greeter = R.T 'greeter :: String -> (String -> String)', ((s) -> (greeting) -> "#{greeting}, #{s}")
        @badGreeter = R.T 'badGreeter :: String -> (String -> String)', ((s) -> s)

      it "should accept functions for parameters", ->
        @passTwo((x) -> x*2).should.equal 4

      it "should accept functions for return values", ->
        @greeter("John").should.be.a 'function'
        @greeter("John")("Hello").should.equal "Hello, John"

      it "should fail on non-function parameters", ->
        (=> @passTwo(42)).should.throw TypeError

      it "should fail if the supplied function returns a non-function value", ->
        (=> @badGreeter("John")).should.throw TypeError



    describe 'Numbers', ->

      before ->
        @add = R.T 'add :: Num -> Num -> Num', (a,b) -> a+b
        @badAdd = R.T 'badAdd :: Num -> Num -> Num', (a,b) -> '' + a + b
        @id = R.T 'id :: Num -> String', (x) -> x; "foo"

      it "should accept numbers for parameters", ->
        @id(2).should.equal 'foo'

      it "should accept numbers for return values", ->
        answer = R.T 'answer :: 0 -> Num', () -> 42
        answer().should.equal 42

      it "should fail on non-numeric parameters", ->
        (=> @add("foo", 42)).should.throw TypeError
        (=> @add(42, "foo")).should.throw TypeError

      it "should not fail on numeric parameters that have decimal parts", ->
        @add(2,3.4).should.be.ok

      it "should fail if the supplied function returns a non-numeric value", ->
        (=> @badAdd(2,2)).should.throw TypeError

      describe 'Integers', ->

        before ->
          @add = R.T 'add :: Int -> Int -> Int', (a,b) -> a+b
          @badAdd = R.T 'badAdd :: Int -> Int -> Int', (a,b) -> '' + a + b
          @id = R.T 'id :: Int -> String', (x) -> x; "foo"

        it "should accept integers for parameters", ->
          @id(2).should.equal 'foo'

        it "should accept integers for return values", ->
          answer = R.T 'answer :: 0 -> Int', () -> 42
          answer().should.equal 42

        it "should fail on non-numeric parameters", ->
          (=> @add("foo", 42)).should.throw TypeError
          (=> @add(42, "foo")).should.throw TypeError

        it "should fail on numeric parameters that have decimal parts", ->
          (=> @add(2,3.4)).should.throw TypeError

        it "should fail if the supplied function returns a non-numeric value", ->
          (=> @badAdd(2,2)).should.throw TypeError

    describe 'Strings', ->

      before ->
        @upper = R.T "upper :: String -> Num", (s) -> 42
        @howMany = R.T "howMany :: Num -> String", (n) -> n + '!'
        @badUpper = R.T "badUpper :: String -> String", (s) -> 42

      it "should accept strings for parameters", ->
        @upper("foo").should.equal 42

      it "should accept strings for return values", ->
        @howMany(42).should.equal "42!"

      it "should reject non-string parameters", ->
        (=> @upper(42)).should.throw TypeError

      it "should reject non-string return values", ->
        (=> @badUpper("foo")).should.throw TypeError

    describe 'Functions that take no arguments (EmptyContract)', ->

      before ->
        @myLog = R.T 'myLog :: 0 -> Unit', () -> undefined
        @badLog = R.T 'badLog :: 0 -> Unit', (s) -> undefined

      it "should pass for functions that take no arguments", ->
        expect(@myLog()).to.be.undefined

      it "should fail if the function is passed arguments", ->
        (=> @myLog(42)).should.throw TypeError

      it "should fail for functions that take arguments", ->
        (=> @badLog(42)).should.throw TypeError

    describe "Functions that return 'undefined'", ->

      before ->
        @myLog = R.T 'myLog :: 0 -> Unit', () -> undefined
        @badLog = R.T 'badLog :: 0 -> Unit', (s) -> s + '!'

      it "should pass for functions that take return 'undefined'", ->
        expect(@myLog()).to.be.undefined

      it "should fail if the function returns a value", ->
        (=> @badLog("whoa")).should.throw TypeError

    describe 'Booleans', ->

      before ->
        @truth = R.T "upper :: Bool -> Num", (s) -> 42
        @falsehood = R.T "howMany :: Num -> Bool", (n) -> false
        @truthy = R.T "truthy :: Num -> Bool", (n) -> Math.abs(n) + 1
        @badTruth = R.T "badUpper :: Bool -> Bool", (s) -> 42

      it "should accept booleans for parameters", ->
        @truth(true).should.equal 42

      it "should accept booleans for return values", ->
        @falsehood(42).should.equal false

      it "should reject non-boolean parameters", ->
        (=> @truth(42)).should.throw TypeError

      it "should reject non-boolean return values", ->
        (=> @badTruth(true)).should.throw TypeError

      it "should reject truthy return values", ->
        (=> @truthy(42)).should.throw TypeError
        (=> @truthy(42)).should.throw /Number/

    describe 'Lists', ->

      before ->
        @lastOne = R.T "lastOne :: [String] -> String", (l) -> l[l.length - 1]
        @oneMinus = R.T "oneMinus :: Int -> [Int]", (n) -> [n, n-1]
        @badMinus = R.T "badMinus :: Int -> [Int]", (n) -> n
        @badItems = R.T "badItems :: 0 -> [Int]", () -> [42, "foo"]

      it "should accept lists for parameters", ->
        @lastOne(["foo", "bar"]).should.equal "bar"

      it "should accept lists for return values", ->
        @oneMinus(42).should.eql [42, 41]

      it "should reject non-list parameters", ->
        (=> @lastOne(42)).should.throw TypeError
        (=> @lastOne(42)).should.throw /Number/

      it "should reject non-list return values", ->
        (=> @badMinus(42)).should.throw /Number/

      it "should reject lists that do not have homogenous items", ->
        (=> @lastOne(["foo",1,2])).should.throw TypeError
        (=> @lastOne(["foo",1,2])).should.throw /Number/
        (=> @badItems()).should.throw TypeError

    describe "'Maybe' values", ->

      before ->
        @optional = R.T 'optional :: Int? -> Int', (n) -> if n then n*2 else 41
        @nullMe = R.T 'nullMe :: Int -> Int?', (n) -> if n is 21 then n*2 else null
        @undefMe = R.T 'undefMe :: String -> String?', (s) -> if s is "foo" then "bar" else undefined

      it "should accept functions that take optional arguments", ->
        @optional().should.equal 41
        @optional(null).should.equal 41
        @optional(undefined).should.equal 41
        @optional(21).should.equal 42

      it "should accept functions that return null or a non-null, non-undefined value", ->
        expect(@nullMe(1)).not.to.throw
        expect(@nullMe(1)).to.be.null
        expect(@nullMe(21)).to.equal 42

      it "should accept functions that return undefined or a non-null, non-undefined value", ->
        expect(@undefMe("wow")).not.to.throw
        expect(@undefMe("wow")).to.be.undefined
        expect(@undefMe("foo")).to.equal "bar"

    describe 'Maps (Dictionaries)', ->

      before ->
        @stringDict =
          foo: "bar"
          baz: "boom"
        @getIt = R.T 'getIt :: <String> -> String -> String', (m,k) -> m[k]
        # @todo The following doesn't work with a more complex type scenario,
        # like: String -> List<String> -> <List<String>>
        @genIt = R.T 'genIt :: String -> String -> <String>', (s1,s2) ->
          ret = {}
          ret[s1] = s2
          ret
        @badGenIt = R.T 'badGenIt :: String -> String -> <String>', (s1,s2) -> 42

      it "should accept maps for parameters", ->
        @getIt(@stringDict, "foo").should.equal "bar"

      it "should accept maps for return values", ->
        @genIt("foo", "bar").should.eql {foo: "bar"}

      it "should reject non-map parameters", ->
        (=> @getIt("foo", "bar")).should.throw TypeError

      it "should reject maps with the wrong value type", ->
        (=> @getIt({foo: 42}, "foo")).should.throw TypeError

      it "should reject maps that don't have homogenous values", ->
        (=> @getIt({foo: "bar", baz: 42}, "foo")).should.throw TypeError

      # TODO: It seems like dealing with Map/Dict return values
      # is not properly supported in Ristretto...
      #
      # it "should reject non-map return values", ->
      #   console.log "What's this?", @badGenIt("foo", "bar")
      #   (=> @badGenIt("foo", "bar")).should.throw TypeError

    describe 'Type variables', ->
      it "should allow them to be used with map types", ->
        lookup = R.T 'lookup :: forall b. <b> -> String -> String', (m, k) -> m[k]
        obj = foo: "bar"
        lookup(obj, "foo").should.equal "bar"