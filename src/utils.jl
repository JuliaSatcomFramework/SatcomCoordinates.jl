##### Misc Utilities ####
ispair(ex) = Meta.isexpr(ex, :call) && ex.args[1] === :(=>)

function parse_property_expression(ex::Expr)
    exception = ArgumentError("The macro expect a pair of one of the following forms:\n  - `propname => unit`\n  - `propname => unit => (aliases...)`")
    ispair(ex) || throw(exception)
    _, propname, rest = ex.args # We extract the property name and the val of the second pair, which might contain only the unit or unit and aliases
    # We now try to extract the unit and eventually the aliases from `rest`
    propname isa Symbol || throw(exception)
    if ispair(rest)
        _, unit, aex = rest.args
        Meta.isexpr(aex, :tuple) || throw(exception)
        aliases = [aex.args...]
        aliases isa Vector{Symbol} || throw(exception)
        return propname, unit, aliases
    else
        return propname, rest, Symbol[]
    end
end

function parse_properties_expression(ex::Expr)
    Meta.isexpr(ex, :vcat) || throw(ArgumentError("The macro only supports inputs of the form"))
    props = ex.args
    propnames = Symbol[]
    userunits = []
    aliases = Vector{Symbol}[]
    for ex in props
        propname, userunit, _aliases = parse_property_expression(ex)
        push!(propnames, propname)
        push!(userunits, userunit)
        push!(aliases, _aliases)
    end
    allnames = vcat(propnames, aliases...)
    allunique(allnames) || throw(ArgumentError("The provided property names (with their aliases) are not unique"))
    return propnames, userunits, aliases
end

macro define_properties(CRS, props)
    propnames, userunits, aliases = parse_properties_expression(props)
    lnn = __source__
    blk = Expr(:block)
    push!(blk.args, resolve_property_expression(CRS; propnames, aliases, lnn))
    push!(blk.args, units_expression(CRS; propnames, userunits, lnn))
    return Expr(:let, Expr(:block), blk) |> esc
end

# This function takes care of automatically generating the `units` function for the provided CRS
function units_expression(CRS; propnames, userunits, lnn::LineNumberNode)
    length(propnames) == length(userunits) || throw(ArgumentError("The number of property names and units must be the same"))
    kws = Expr(:parameters)
    for i in eachindex(propnames, userunits)
        push!(kws.args, Expr(:kw, propnames[i], userunits[i]))
    end
    ntexpr = Expr(:tuple, kws)
    fdef = Expr(:function, Expr(:call, GlobalRef(@__MODULE__, :units), Expr(:(::), Expr(:curly, :Type, Expr(:(<:), CRS)))), Expr(:block, lnn, ntexpr))
end

# This function takes care of automatically generating the `resolve_property` function for the provided CRS
function resolve_property_expression(CRS; propnames, aliases, lnn::LineNumberNode)
    length(propnames) == length(aliases) || throw(ArgumentError("The number of property names and alternates must be the same"))
    allnames = vcat(propnames, aliases...)
    allunique(allnames) || throw(ArgumentError("The provided property names (with their aliases) are not unique"))
    nprops = length(propnames)
    # Here we build the if-else block. We start from the error
    ifex = QuoteNode(:__could_not_resolve_property__)
    midargs(i) = [
        :(propname in $((propnames[i], aliases[i]...))),
        :(return $(QuoteNode(propnames[i])))
    ]
    for i in reverse(2:nprops)
        ifex = Expr(:elseif, midargs(i)..., ifex)
    end
    ifex = Expr(:if, midargs(1)..., ifex)
    fdef = Expr(:function, Expr(:call, GlobalRef(@__MODULE__, :resolve_property), Expr(:(::), :crs, Expr(:curly, :Type, Expr(:(<:), CRS))), Expr(:(::), :propname, Symbol)), Expr(:block, lnn, ifex))
    aex = :(Base.@constprop :aggressive $fdef)
end