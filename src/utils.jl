# These are struct just used to simplify the macro inner functions
# This is used to specify that explicit inputs were provided for a given property
struct ExplicitInput
    propname::Symbol
    userunit::Union{Symbol, Expr}
    aliases::Vector{Symbol}
end
# This is used for identifying a function over the CRS provided as input
struct CRSFunc
    ex::Expr
end

##### Functions copied from MacroTools.jl ####
walk(x, inner, outer) = outer(x)
walk(x::Expr, inner, outer) = outer(Expr(x.head, map(inner, x.args)...))
prewalk(f, x)  = walk(f(x), x -> prewalk(f, x), identity)
##### End of MacroTools.jl functions ####

function replace_single_underscore(ex::Expr, newval::Symbol)
    changed = Ref(false)
    newex = prewalk(ex) do x
        if x === :_
            changed[] = true
            return newval
        else
            return x
        end
    end
    return newex, changed[]
end

ispair(ex) = Meta.isexpr(ex, :call) && ex.args[1] === :(=>)

function parse_property_expression(ex::Expr)
    exception = ArgumentError("The macro expect a pair of one of the following forms:\n  - `propname => unit`\n  - `propname => unit => (aliases...)`")
    if Meta.isexpr(ex, :(...))
        # This is a complex expression on the CRS
        newex, changed = replace_single_underscore(ex, :CRS)
        return CRSFunc(newex.args[1])
    end
    ispair(ex) || throw(exception)
    _, propname, rest = ex.args # We extract the property name and the val of the second pair, which might contain only the unit or unit and aliases
    # We now try to extract the unit and eventually the aliases from `rest`
    propname isa Symbol || throw(exception)
    if ispair(rest)
        _, unit, aex = rest.args
        Meta.isexpr(aex, :tuple) || throw(exception)
        aliases = map(aex.args) do val
            val isa Symbol && return val
            val isa QuoteNode && return val.value
            throw(exception)
        end
        return ExplicitInput(propname, unit, aliases)
    else
        return ExplicitInput(propname, rest, Symbol[])
    end
end

function parse_properties_expression(ex::Expr)
    Meta.isexpr(ex, (:vcat, :vect)) || throw(ArgumentError("The macro only supports inputs of the form:\n@define_properties CRS [\n\t⋮\n\t⋮\n]"))
    props = []
    for ex in ex.args
        propspec = parse_property_expression(ex)
        push!(props, propspec)
    end
    allnames = mapreduce(vcat, props) do p
        p isa ExplicitInput || return Symbol[]
        return [p.propname, p.aliases...]
    end
    allunique(allnames) || throw(ArgumentError("The provided property names (with their aliases) are not unique"))
    sum(p -> p isa CRSFunc, props) <= 1 || throw(ArgumentError("You can not have more than one complex expression on the CRS within a set of properties"))
    return props
end

macro define_properties(CRS, props)
    propspecs = parse_properties_expression(props)
    lnn = __source__
    blk = Expr(:block)
    push!(blk.args, resolve_property_expression(CRS; propspecs, lnn))
    push!(blk.args, units_expression(CRS; propspecs, lnn))
    return Expr(:let, Expr(:block), blk) |> esc
end

# This function takes care of automatically generating the `units` function for the provided CRS
function units_expression(CRSTYPE; propspecs, lnn::LineNumberNode)
    #= This function create something of this form for all provided properties and units: 
        function SatcomCoordinates.units(CRS::Type{<:CRSTYPE})
            (; propname1 = unit1, propname2 = unit2, ...)
        end
    =#
    kws = Expr(:parameters)
    for spec in propspecs
        if spec isa ExplicitInput
            # We have explicit property name and unit, so we simply 
            push!(kws.args, Expr(:kw, spec.propname, spec.userunit))
        else
            push!(kws.args, Expr(:(...), Expr(:call, GlobalRef(@__MODULE__, :units), spec.ex)))
        end
    end
    ntexpr = Expr(:tuple, kws) # This is what creates the named tuple with the provided parameters
    body = Expr(:block, lnn, ntexpr) # We just wrap this in a block with the LineNumberNode of the macro call site (for `methods` and stacktraces)
    funcname = GlobalRef(@__MODULE__, :units) # This becomes `SatcomCoordinates.units`
    firstarg = Expr(:(::), :CRS, Expr(:curly, :Type, Expr(:(<:), CRSTYPE))) # This is the first argument of the method, and translates to `CRS::Type{<:CRSTYPE}`
    fdef = Expr(:function, Expr(:call, funcname, firstarg), body)
    return fdef
end

# This function takes care of automatically generating the `resolve_property` function for the provided CRS
function resolve_property_expression(CRSTYPE; propspecs, lnn::LineNumberNode)
    #= This function create something of this form for all provided properties and aliases: 
        function SatcomCoordinates.resolve_property(CRS::Type{<:CRSTYPE}, propname::Symbol)
            if propname in (:propname1, aliases1...)
                return :propname1
            elseif propname in (:propname2, aliases2...)
                return :propname2
            elseif # For all other properties
                ⋮
            else
                __could_not_resolve_property__
            end
        end
    =#
    # We put the eventual complex expression at the end as it falls within the last else clause
    sorted = sort(propspecs; by = p -> p isa CRSFunc ? 1 : 0)
    nprops = length(sorted)
    # Here we build the if-else block. We start from the last (i.e. `else`) block
    spec = last(sorted)
    ifex = if spec isa ExplicitInput
        # If we don't have a complex expression on the CRS, we just return the a placeholder symbol to then throw an error within getproperty
        QuoteNode(:__could_not_resolve_property__)
    else
        spec = last(sorted)
        # If we have a complex expression, we just put a nestec call to `resolve_property` on the CRS resulting from the expression
        Expr(:call, GlobalRef(@__MODULE__, :resolve_property), spec.ex, :propname)
    end
    # This helper function generates automatically the condition and body of our if-else blocks
    cond_body(spec) = (;
        cond = :(propname in $((spec.propname, spec.aliases...))), # This is the if (or elseif) condition
        body = :(return $(QuoteNode(spec.propname))) # This is the body which simply returns the default name for the specific property
    )
    for i in reverse(2:nprops)
        spec = sorted[i]
        spec isa CRSFunc && continue # We don't process CRSFunc as they are already processed
        ifex = let
            cond, body = cond_body(spec)
            Expr(:elseif, cond, body, ifex) # The last ifex is the one from the previous cycle. If-else statements are recursively nested in expression starting from the last branch
        end
    end
    firstspec = first(sorted)
    if firstspec isa ExplicitInput
        # This it's inside an if in the case there is only one property specified as a complex CRSFunc
        ifex = Expr(:if, cond_body(firstspec)..., ifex) # This is the first branch (i.e. the `if` one)
    end
    fdef = let
        body = Expr(:block, lnn, ifex) # We wrap the if-else in a block and add the LNN of the macro call-site to get source information (for `methods` and stacktraces)
        funcname = GlobalRef(@__MODULE__, :resolve_property) # This becomes `SatcomCoordinates.resolve_property`
        firstarg = Expr(:(::), :CRS, Expr(:curly, :Type, Expr(:(<:), CRSTYPE))) # This is the first argument of the method, and translates to `CRS::Type{<:CRSTYPE}`
        secondarg = Expr(:(::), :propname, Symbol) # This is the second argument and translates to `propname::Symbol`
        sig = Expr(:call, funcname, firstarg, secondarg) # This is the part specifying the call signature, and we explicitly put a GlobalRef with this package's module name to make sure the method is added to the corect function
        Expr(:function, sig, body)
    end
    aex = :(Base.@constprop :aggressive $fdef) # We wrap this with `@constprop :aggressive` to make sure the constant propagation of symbols is forced as much as possible (to allow for optimization of getproperty)
    return aex
end