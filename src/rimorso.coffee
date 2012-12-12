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
  # ## Custom Exceptions ##
  #
  # Includes: AbstractMethodError for simulating abstract functions
  # attached to object prototypes.
  #
  class AbstractMethodError extends Error
    constructor: (message) ->
      @message = message or 'You tried to call an abstract method. You must override this method in your sub-class.'
      @name = 'AbstractMethodError'

  # ## Labels ##
  #
  # Not sure what these are yet. We'll find out.
  class Label
    #
    # Give this Label a name and set other defaults.
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

  # ## Contracts ##
  #
  # The vehicle of type checking itself.
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
      console.log "FAIL TIME", @label
      throw TypeError(@label.toString())

    #
    # This function does not appear to be used.
    #
    swap: ->
      @label.swap()

  getClass = (obj) ->
    Object.prototype.toString.call(obj).slice(8, -1)

  #
  # This function needs *serious* consideration for cross-platform
  # compatibility.
  #
  is_ = (type, obj) ->
    klass = getClass obj
    objNotNull = obj isnt null
    # PhantomJS gives klass of `DOMWindow` for undefined...
    if (type is 'Undefined' and klass is 'DOMWindow')
      objNotNull and (typeof obj) is 'undefined'
    else
      objNotNull and klass is type

  formatFailMsg = (value, type) ->
    """

    Value: #{value}
    Expected: #{type}
    Actual: #{getClass(value)}
    """

  class IntegerContract extends Contract
    #
    # @Override
    #
    restrict: (x) ->
      if (is_('Number', x) and Math.round(x) is x)
        return x
      else if (not is_('Number', x))
        @label.reason = formatFailMsg x, 'Number'
        @fail()
      else
        @label.reason = formatFailMsg x, 'Integer'
        @fail()

    #
    # @Override
    #
    relax: @::restrict

  IntegerContractFactory = ->
    f = (label) ->
      new IntegerContract(label)
    f.repr = ->
      "IntegerContractFactory()"
    f

  class EmptyContract extends Contract
  class ObjectContract extends Contract

  class FunctionContract extends Contract
    constructor: (label, domain, range) ->
      super
      @domain = domain
      @range = range
      console.log "FnContract, domain and range", @domain, @range

    #
    # @Override
    #
    # The parameter numArgs specifies the number of arguments that should be expected.
    # If it is the last argument, then we simply call the function. If numArgs is not
    # specified, the number of arguments is predicted and used.
    #
    restrict: (f, numArgs) ->
      unless (is_('Function', f))
        @label.reason = formatFailMsg(f, 'function')
        @fail()
      if (@range instanceof FunctionContract) and
           (not @domain instanceof EmptyContract) and
           (numArgs is undefined or numArgs > 1) and
           (numArgs isnt undefined or f.length > 1 or f.length is 0)
        if (numArgs is undefined)
          numArgs = f.length
        # Return the restricted version of the function itself - i.e. it relaxes inputs and restricts output
        return () =>
          args = Array.prototype.slice.apply(arguments)
          # take the args and apply the domain check to the first one.
          # in the simple case, we want a function that takes an arg
          # and returns f(args ++ arg).

          # This is the restricted output of the function.  This actually recursively
          # restricts function ranges until it hits a range that is not a function, so that
          # every input argument gets relaxed and the final output gets restricted appropriately.
          # This only supports unary functions - i.e. if I have f :: A -> B -> C -> D then I
          # expect it to be called f(a)(b)(c).
          out = @range.restrict((() ->
            args2 = Array.prototype.slice.apply(arguments)
            args2 = [@domain.relax(args[0])].concat(args2)
            if (@domain instanceof ObjectContract)
              @domain.restrict args[0]
            f.apply(null, args2))
            , if (numArgs is 0) then undefined else numArgs - 1
          )

          # We obviously want to preserve javascript behaviour of allowing multiple arguments
          # to be supplied to functions, so this converts f(a, b, c) to f(a)(b)(c).
          for arg in args
            out = out(arg)

          out
      # 'else' to the massive 'if' above
      else
        return (x) =>
          console.log "Restrict's else", @domain, @range
          args = Array.prototype.slice.apply(arguments)
          if (@domain instanceof EmptyContract) and args.length > 1
            @label.reason = 'The function was called with ' + value + ' but should have been called with zero arguments.'
            @fail()
          restOfArgs = args.slice(1)
          result = @range.restrict(f(@domain.relax(x)))
          if (@domain instanceof ObjectContract)
            @domain.restrict(x)
          if (restOfArgs.length is 0)
            return result
          result.apply(undefined, restOfArgs)

    #
    # @Override
    #
    relax: (f, numArgs) ->
      if (not is_('Function', f))
        @label.reason = formatFailMsg(f, 'function')
        @fail()
      if (@range instanceof FunctionContract) and
           (not @domain instanceof EmptyContract) and
           (numArgs is undefined or numArgs > 1) and
           (numArgs isnt undefined or f.length > 1 or f.length is 0)
        if (numArgs is undefined)
          numArgs = f.length
        return () =>
          args = Array.prototype.slice.apply(arguments)
          out = @range.relax((() ->
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
            @label.reason = 'The function was called with ' + value + ' but should have been called with zero arguments.'
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

    pos = 0

    parse = ->
      parseKeyVal = ->
        name = input[pos++]
        pos += 1
        val = parse()
        {name: name, contract: val}
      parseHead = ->
        if input[pos] is "Int"
          pos += 1
          out = IntegerContractFactory()
        else if input[pos] is "Num"
          pos += 1
          out = NumberContractFactory()
        else if input[pos] is "String"
          pos += 1
          out = StringContractFactory()
        else if input[pos] is "Bool"
          pos += 1
          out = BooleanContractFactory()
        else if input[pos] is "Unit"
          pos += 1
          out = UnitContractFactory()
        else if input[pos] is "0"
          pos += 1
          out = EmptyContractFactory()
          pos += 1 # ->
          range = parse()
          out = FunctionContractFactory(EmptyContractFactory(), range)
        else if input[pos] is "("
          pos += 1
          out = parse()
        else if input[pos] is "["
          pos += 1
          inner = parse()
          out = ListContractFactory(inner)
        else if input[pos] is "<"
          pos += 1
          key = StringContractFactory()
          value = parse()
          out = MapContractFactory(key, value)
        else if input[pos] is "{"

          # Parses and returns one ObjectContractFactory
          parseObject = ->
            record = []

            # Allow empty record contract
            unless input[pos + 1] is "}"
              until input[pos] is "}"
                pos += 1
                record.push parseKeyVal()
            pos += 1
            name = `undefined`
            if input[pos] is "@"
              pos += 1
              name = input[pos]
              pos += 1
            ObjectContractFactory name, record

          out = parseObject()

          # Checks for union operator and performs a merge operation if
          # present and does so until there are no more merges necessary.
          while input[pos] is "U" and input[pos + 1] is "{"
            pos += 1
            out = ObjectContractFactoryMerge(out, parseObject())
        else if input[pos] is "forall"
          pos += 1
          vars = []
          until input[pos] is "."
            vars.push input[pos]
            pos += 1
          pos += 1
          out = parseHead()

          # Inserting a forall for each variable.
          vars.reverse().forEach (v) ->
            typeFunc = "function(" + v + ") { return " + out.repr() + "}"
            typeFunc = eval_("typeFunc = " + typeFunc)
            out = ForAllContractFactory(typeFunc)

          return out
        else if adts[input[pos]]?
          out = adts[input[pos++]]
        else
          out = VariableContractFactoryPlaceholder(input[pos])
          pos += 1
        if input[pos] is "?"
          pos += 1
          out = MaybeContractFactory(out)
        if input[pos] is "->"
          pos += 1
          range = parseHead()
          return FunctionContractFactory(out, range)
        out
      result = `undefined`
      while pos < input.length
        if input[pos] is ")" or input[pos] is "]" or input[pos] is ">"
          pos += 1
          return result
        return result  if input[pos] is "," or input[pos] is "}"
        result = parseHead()
      result
    parse()

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
      factory = buildContract(values[1].trim())
      contract = factory(new Label(values[0].trim()))

      #
      # Return a version of the original function, with
      # the type contract in "restrict" mode to enable
      # type checking when called.
      #
      contract.restrict(value)

    @D: -> console.log "Algebraic datatypes"