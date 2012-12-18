# ## Module Definition ##
# Use UMD pattern to expose Rimorso correctly across environments.
umd = (root, factory) ->
  # Node.js
  if (typeof exports is 'object')
    module.exports = factory()
  # AMD loader
  else if (typeof define is 'function' and define.amd)
    define(factory)
  # Browser global (root is window)
  else
    root.Rimorso = factory()

# We now call the UMD module, passing in `this` as the `root` and a function that returns our library's exported values as the `factory`.
umd this, ->
  #
  # ## Housekeeping ##
  #

  #
  # ### Custom Errors ###
  #

  # AbstractMethodError for simulating abstract functions
  # attached to object prototypes.
  #
  class AbstractMethodError extends Error
    constructor: (message) ->
      @message = message or 'You tried to call an abstract method. You must override this method in your subclass.'
      @name = 'AbstractMethodError'

  #
  # ### Builtin Classes/Types ###
  #

  # Taken from jQuery, we list out the builtin classes...
  builtinClasses = ["Boolean", "Number", "String", "Function", "Array", "Date", "RegExp", "Object", "Error", "Null", "Undefined"]
  # ...And then build out a map of class representations to types, e.g., `[object Number]` to `number`.
  class2type = {}
  for klass in builtinClasses
    class2type[ "[object #{klass}]" ] = klass

  # Taken from jQuery, use a plain object to get the definitions
  # of `toString` and `hasOwnProperty` used below.
  #
  core_toString = class2type.toString
  core_hasOwn = class2type.hasOwnProperty

  #
  # ### Type Comparison ###
  #
  class Is
    #
    # Get the `[[Class]]` of a data structure. This works on
    # any JavaScript data structure.
    #
    # This is the `Object.prototype.toString.call(obj)`
    # method of determining an object's class. Amongst
    # available methods, this is generally the most reliable.
    #
    @getClass: (obj) ->
      core_toString.call(obj)

    #
    # For objects, get the "class" (prototype).
    #
    # This checks if Object.getPrototypeOf is available,
    # and if not will fall back to using either __proto__
    # or constructor.prototype. To understand the
    # ramifications of this, you are encouraged to read
    # the MDN docs as well as John Resig's post
    # on the subject.
    #
    @getPrototype: (obj) ->
      if (typeof Object.getPrototypeOf is 'function')
        Object.getPrototypeOf obj
      else if (typeof 'test'.__proto__ is 'object')
        obj.__proto__
      else
        obj.constructor.prototype

    #
    # Return the type of an object.
    #
    # Taken from jQuery. At its root, this is just
    # Object.prototype.toString.call(obj), but with lower-casing
    # and consideration of null/undefined values.
    #
    @getType: (obj) =>
      if obj == null
        ret = String(obj)
      else
        ret = class2type[ @getClass(obj) ]
      ret or "Object"

    #
    # #### Convenience Methods ####
    #
    # Yes, we could have dynamically defined these,
    # but for an API that's not very clear,
    # and at least one of these already has exceptional
    # behavior for cross-platform compatibility.
    #

    #
    # Chaining methods for "fluent" API
    #
    @a: @
    @an: @

    #
    # Is the object `true` or `false`?
    #
    @boolean: (obj) =>
      @getType(obj) is 'Boolean'

    #
    # Is the object a number?
    #
    @number: (obj) =>
      @getType(obj) is 'Number'

    #
    # Is the object a string?
    #
    @string: (obj) =>
      @getType(obj) is 'String'

    #
    # Is the object a function?
    #
    @function: (obj) =>
      @getType(obj) is 'Function'

    #
    # Is the object an array?
    #
    @array: (Array.isArray) or (obj) =>
      @getType(obj) is 'Array'

    #
    # Is the object a date?
    #
    @date: (obj) =>
      @getType(obj) is 'Date'

    #
    # Is the object a regular expression?
    #
    @regexp: (obj) =>
      @getType(obj) is 'RegExp'

    #
    # This matches for everything that doesn't match the other type methods.
    #
    @object: (obj) =>
      @getType(obj) is 'Object'

    #
    # Is the object an error?
    #
    @error: (obj) =>
      @getType(obj) is 'Error'

    #
    # Is the object null?
    #
    @null: (obj) =>
      @getType(obj) is 'null'

    #
    # Is the object undefined?
    #
    @undefined: (obj) =>
      (@getType(obj) is 'Undefined') or
        (typeof(obj) is 'undefined') or
        (@getClass(obj) is '[object DOMWindow]' and typeof(obj) is 'undefined')

  #
  # ## Labels ##
  #

  #
  # Objects that represent the functions being type checked.
  # The name field is the name of the function; the polarity determines
  # where a type error occurred in the chain of curried functions that comprise
  # a function definition; and finally the reason field contains more detailed
  # error messaging for type errors.
  #
  class Label
    #
    # Give this Label a name and polarity
    #
    constructor: (name) ->
      @name = name
      @polarity = true
      @reason = ''

    #
    # The Label is used for returning error messages
    # on type check failure. Take into account polarity
    # and a detailed reason for failure when creating a String
    # representation of a Label.
    #
    toString: ->
      polarityStr = if @polarity then "" else "~"
      out = polarityStr + @name
      if @reason.length > 0
        out += @reason
      out

    #
    # Return a label with the same name as the current one,
    # but with opposite polarity.
    #
    complement: ->
      label = new Label(@name)
      label.polarity = !@polarity
      label

    setReason: (value, type) =>
      # Use default message format if type is provided
      if type?
        @reason =
          """

          Value: #{value},
          Expected: #{type},
          Actual: #{Is.getType(value)}.
          """
      # Else `value` is simply a string to be set directly
      else
        @reason = value

  #
  # ## Contracts ##
  #

  #
  # An abstract definition for all type contracts.
  #
  class Contract
    constructor: (label) ->
      @label = label

    restrict: ->
      throw new AbstractMethodError

    relax: ->
      throw new AbstractMethodError

    #
    # The `fail` function is called whenever type checking
    # fails. It uses the String representation of its label
    # for detailed error messaging.
    #
    fail: ->
      throw TypeError(@label.toString())

  #
  # ### Integer Contract ###
  #
  # Contract used for validating "integers." Since JavaScript does
  # not support an Integer numeric type, values are checked for
  # the type `Number` and then checked to see if their value changes
  # when rounded.
  #
  class IntegerContract extends Contract
    #
    # @Override `Contract.restrict`
    #
    restrict: (x) ->
      if (Is.a.number(x) and Math.round(x) is x)
        return x
      else if (not Is.number(x))
        @label.setReason x, 'Number'
        @fail()
      else
        @label.setReason x, 'Integer'
        @fail()

    #
    # @Override `Contract.relax`
    #
    relax: @::restrict

  IntegerContractFactory = ->
    f = (label) ->
      new IntegerContract(label)
    f.repr = ->
      "IntegerContractFactory()"
    f

  #
  # ### Number Contract ###
  #
  # Contract for managing validation of generic numbers.
  # See the IntegerContract for a more specific numeric type
  # validation.
  #
  class NumberContract extends Contract
    #
    # @Override `Contract.restrict`
    #
    restrict: (x) ->
      if (Is.a.number x)
        return x
      else
        @label.setReason x, 'Number'
        @fail()

    #
    # @Override `Contract.relax`
    #
    relax: @::restrict

  NumberContractFactory = ->
    f = (label) ->
      new NumberContract(label)
    f.repr = ->
      "NumberContractFactory()"
    f

  #
  # ### String Contract ###
  #
  class StringContract extends Contract
    #
    # @Override `Contract.restrict`
    #
    restrict: (x) ->
      if (Is.a.string x)
        return x
      else
        @label.setReason x, 'String'
        @fail()

    #
    # @Override `Contract.relax`
    #
    relax: @::restrict

  StringContractFactory = ->
    f = (label) ->
      new StringContract(label)
    f.repr = ->
      "StringContractFactory()"
    f

  class EmptyContract extends Contract
  class ObjectContract extends Contract
  class MaybeContract extends Contract
  class MaybeContractFactory
  class VariableContractFactoryPlaceholder

  #
  # ### Function Contract ###
  #
  # The most important contract, this contract manages
  # validating types for functions.
  #
  # The "domain" is the set of inputs to a function. The
  # "range" is the output. Both must be typechecked and
  # support any JavaScript value, including other functions.
  #
  class FunctionContract extends Contract
    constructor: (label, domain, range) ->
      super
      @domain = domain
      @range = range

    #
    # @Override `Contract.restrict`
    #
    # The parameter numArgs specifies the number of arguments that should be expected.
    # If it is the last argument, then we simply call the function. If numArgs is not
    # specified, the number of arguments is predicted (because JavaScript does not enforce how many arguments are passed to a function) and used.
    #
    restrict: (f, numArgs) ->
      unless (Is.a.function f)
        @label.setReason f, 'function'
        @fail()
      #
      # Only add an extra layer if:
      #
      #  * The range is a function
      #  * The domain is not an EmptyContract (0)
      #  * Num args is provided and more than 1 arg is required.
      #
      # If num args is not provided, then the length property of
      # the function (i.e., the number of named parameters declared
      # for it) is used as num args instead.
      #
      if (@range instanceof FunctionContract) and
           (not (@domain instanceof EmptyContract)) and
           (numArgs is undefined or numArgs > 1) and
           (numArgs isnt undefined or f.length > 1 or f.length is 0)
        # If number of required arguments not specified,
        # use number of named parameters in function definition instead.
        if (numArgs is undefined)
          numArgs = f.length
        # Return the restricted version of the function itself -
        # i.e. it relaxes inputs and restricts output
        return () =>
          args = Array.prototype.slice.apply(arguments)
          # Take the args and apply the domain check to the first one.
          # In the simple case, we want a function that takes an arg
          # and returns f(args ++ arg).
          #
          # This is the restricted output of the function.  This actually recursively
          # restricts function ranges until it hits a range that is not a function, so that
          # every input argument gets relaxed and the final output gets restricted appropriately.
          # This only supports unary functions - i.e. if I have f :: A -> B -> C -> D then I
          # expect it to be called f(a)(b)(c).
          out = @range.restrict((() =>
            args2 = Array.prototype.slice.apply(arguments)
            args2 = [@domain.relax(args[0])].concat(args2)
            if (@domain instanceof ObjectContract)
              @domain.restrict args[0]
            f.apply(null, args2))
            , if (numArgs is 0) then undefined else numArgs - 1
          )

          # We obviously want to preserve JavaScript behaviour of allowing multiple arguments
          # to be supplied to functions, so this converts f(a, b, c) to f(a)(b)(c).
          for arg,idx in args
            # Skip first arg, handled in definition of out above
            continue if idx is 0
            out = out(arg)

          out
      #
      # If the range is not a function (which is the case for all non-higher-order functions):
      #
      else
        return (x) =>
          args = Array.prototype.slice.apply(arguments)
          #
          # Fail if empty function called with any args
          #
          if (@domain instanceof EmptyContract) and args.length > 1
            @label.setReason('The function was called with ' + value + ' but should have been called with zero arguments.')
            @fail()
          restOfArgs = args.slice(1)
          result = @range.restrict(f(@domain.relax(x)))
          if (@domain instanceof ObjectContract)
            @domain.restrict(x)
          #
          # Function called with one argument
          #
          if (restOfArgs.length is 0)
            return result
          #
          # Not at end of -> function chain yet,
          # keep going (until a non-function result is
          # hit, which will be when restOfArgs is 0)
          result.apply(undefined, restOfArgs)

    #
    # @Override `Contract.relax`
    #
    relax: (f, numArgs) ->
      unless (Is.a.function(f))
        @label.setReason f, 'function'
        @fail()
      if (@range instanceof FunctionContract) and
           (not @domain instanceof EmptyContract) and
           (numArgs is undefined or numArgs > 1) and
           (numArgs isnt undefined or f.length > 1 or f.length is 0)
        if (numArgs is undefined)
          numArgs = f.length
        return () =>
          args = Array.prototype.slice.apply(arguments)
          out = @range.relax((() =>
            args2 = Array.prototype.slice.apply(arguments)
            args2 = [@domain.restrict(args[0])].concat(args2)
            f.apply(null, args2)), numArgs - 1
          )
          for arg in args
            out = out(arg)

          out
      else
        return (x) =>
          args = Array.prototype.slice.apply(arguments);
          # Rest of the args are captured and we continue to apply
          # arguments in order to preserve identical behavior in currying.
          if (@domain instanceof EmptyContract) and (args.length > 1)
            @label.setReason('The function was called with ' + value + ' but should have been called with zero arguments.')
            @fail()
          restOfArgs = args.slice(1)
          result = @range.relax(f(@domain.restrict(x)))
          if (restOfArgs.length is 0)
            return result
          result.apply(undefined, restOfArgs)

  FunctionContractFactory = (domainFactory, rangeFactory, isRet) ->
    f = (label) ->
      new FunctionContract(label, domainFactory(label), rangeFactory(label.complement()), isRet)
    f.repr = ->
      "FunctionContractFactory(#{domainFactory.repr()}, #{rangeFactory.repr()})"
    f

  # ## Typedefs ##
  #
  # Allow for custom type definitions.
  #
  class Typedef
    @typedefs: {}
    @reserved:
      Int: true
      String: true
      Bool: true
      Num: true
      Unit: true
      0: true
      forall: true

    @create: (label, typedef) ->
      if (@typedefs[label])
        throw TypeError("Error creating typedef for #{label} - already exists")
      else if (@reserved[label])
        throw TypeError("Error creating typedef for #{label} - using reserved word")
      @typedefs[label] = typedef

  class SpecParser
    constructor: (input, pos = 0) ->
      @input = input
      @pos = pos

    parse: ->
      result = undefined
      while @pos < @input.length
        if @input[@pos] is ")" or @input[@pos] is "]" or @input[@pos] is ">"
          @pos += 1
          return result
        return result  if @input[@pos] is "," or @input[@pos] is "}"
        result = @parseHead()
      result

    parseKeyVal: ->
      name = @input[@pos++]
      @pos += 1
      val = @parse()
      {name: name, contract: val}

    parseObject: ->
      record = []

      # Allow empty record contract
      unless @input[@pos + 1] is "}"
        until @input[@pos] is "}"
          @pos += 1
          record.push @parseKeyVal()
      @pos += 1
      name = undefined
      if @input[@pos] is "@"
        @pos += 1
        name = @input[@pos]
        @pos += 1
      ObjectContractFactory name, record

    parseHead: ->
      if @input[@pos] is "Int"
        @pos += 1
        out = IntegerContractFactory()
      else if @input[@pos] is "Num"
        @pos += 1
        out = NumberContractFactory()
      else if @input[@pos] is "String"
        @pos += 1
        out = StringContractFactory()
      else if @input[@pos] is "Bool"
        @pos += 1
        out = BooleanContractFactory()
      else if @input[@pos] is "Unit"
        @pos += 1
        out = UnitContractFactory()
      else if @input[@pos] is "0"
        @pos += 1
        out = EmptyContractFactory()
        @pos += 1 # ->
        range = @parse()
        out = FunctionContractFactory(EmptyContractFactory(), range)
      else if @input[@pos] is "("
        @pos += 1
        out = @parse()
      else if @input[@pos] is "["
        @pos += 1
        inner = @parse()
        out = ListContractFactory(inner)
      else if @input[@pos] is "<"
        @pos += 1
        key = StringContractFactory()
        value = @parse()
        out = MapContractFactory(key, value)
      else if @input[@pos] is "{"

        # @Parses and returns one ObjectContractFactory
        out = @parseObject()

        # Checks for union operator and performs a merge operation if
        # present and does so until there are no more merges necessary.
        while @input[@pos] is "U" and @input[@pos + 1] is "{"
          @pos += 1
          out = ObjectContractFactoryMerge(out, @parseObject())
      else if @input[@pos] is "forall"
        @pos += 1
        vars = []
        until @input[@pos] is "."
          vars.push @input[@pos]
          @pos += 1
        @pos += 1
        out = @parseHead()

        # Inserting a forall for each variable.
        vars.reverse().forEach (v) ->
          typeFunc = "function(" + v + ") { return " + out.repr() + "}"
          typeFunc = eval_("typeFunc = " + typeFunc)
          out = ForAllContractFactory(typeFunc)

        return out
      # else if adts[@input[@pos]]?
      #   out = adts[@input[@pos++]]
      else
        out = VariableContractFactoryPlaceholder(@input[@pos])
        @pos += 1
      if @input[@pos] is "?"
        @pos += 1
        out = MaybeContractFactory(out)
      if @input[@pos] is "->"
        @pos += 1
        range = @parseHead()
        return FunctionContractFactory(out, range)
      out

  #
  # Build contracts by parsing string inputs for type annotations
  #
  # Returns the result of calling a `FooContractFactory` based on the type annotation.
  # Those factories themselves return a function that takes a `Label` and returns an
  # instance of the correct type of Contract, e.g., an `IntegerContract`.
  #
  buildContract = (input) ->
    # Split input, but keep brackets
    input = input.split(/(\(|\)|->|\{|\}|\?|[a-zA-Z0-9]*)/)
    input = input.filter((s) -> s.trim() isnt '' )

    # Check for typedefs
    for item in input
      if Typedef.typedefs[item]
        input[idx] = Typedef.typedefs[item]
        return buildContract(input.join ' ')

    p = new SpecParser(input)
    p.parse()

  # ## Rimorso ##
  #
  # Rimorso defines utilities for applying types to functions
  # and for building ADT's.
  #
  class Rimorso
    @T: (spec, value) ->
      input = spec.split " "

      #
      # Handle typedefs
      #
      if (input[0].trim() is 'typedef')
        typedef = spec.substring(input[0].length).split '::'
        Typedef.create typedef[0].trim(), typedef[1].trim()
        return null

      #
      # Instantiate the appropriate type of contract
      # based on the type spec provided.
      #
      values = spec.split '::'
      #
      # Named type spec
      #
      if (values.length is 2)
        name = values[0].trim()
        type = values[1].trim()
      #
      # Type spec for anonymous function
      #
      else
        name = "anonymous"
        type = spec.trim()

      factory = buildContract(type)
      contract = factory(new Label(name))

      #
      # Return a version of the original function, with
      # the type contract in "restrict" mode to enable
      # type checking when called.
      #
      contract.restrict(value)

    @D: -> console.log "Algebraic datatypes"
    @Is: Is
    @__impl:
      AbstractMethodError: AbstractMethodError
      SpecParser: SpecParser
      Label: Label
      Contract: Contract
      FunctionContract: FunctionContract
      IntegerContract: IntegerContract
      NumberContract: NumberContract
      StringContract: StringContract
