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

"""
    @define_properties CRS [
        propname1 => unit1
        propname2 => unit2[ => (aliases2...)]
        ...
    ]

This macro simplifies the definition of properties for a custom `CRS` type and association between each property and its _user-facing_ unit as well as optional property aliases (supported by `Base.getproperty` on coordinates, i.e. instances of `AbstractSatcomCoordinate`).

The arguments expected by the macro are the following: 
- **1st argument**: The desired custom CRS type to extend
- **2nd argument**: A vector of pairs (one per property of coordinates of the custom CRS)

The pairs are of the form `propname => unit` (or `propname => unit => (aliases...)` in case aliases are desired for specific properties) where:
- `propname`: is the name of the property/coordinate of the custom CRS
- `unit`: is the unit of the property/coordinate. This **MUST** be a `Unit` (and not a `Quantity`) from `Unitful.jl`. In case of properties without a unit (e.g. the coords for UV pointing), `NoUnits` must be used.
- `aliases`: **[OPTIONAL]** A tuple of names the corresponding property can be accessed to via `Base.getproperty` on coordinates defined over the custom CRS.

# Example

```jldoctest
julia> using SatcomCoordinates

julia> struct CustomCartesian <: AbstractCRS end;

julia> SatcomCoordinates.@define_properties CustomCartesian [
           x => u"km" # For some reason, we want x to be shown and parsed in km by default
           y => u"m" => (y2,) # And for some other reason, we want to be able to access y also with the name y2
           z => u"m"
       ]

julia> p = Position(CustomCartesian(), 1,2,3);

julia> p.x
1.0 km

julia> (; y2) = p;

julia> y2
2.0 m
```

!!! note "When to use this macro"
    By default, CRSs (i.e. subtypes of `AbstractCRS`) are cartesian CRSs and have the following default properties:
    - `x`
    - `y`
    - `z`
    which are all associated to the `u"m"` unit and no custom aliases.
    For all other CRSs (or if one wants to customize either the units or add aliases for custom CRSs) this macro must be used on the custom CRS type properly use the other types and function of `SatcomCoordinates.jl`.

See the extended help section below for more details and advanced usage.

See also: [`AbstractSatcomCoordinate`](@ref), [`AbstractCRS`](@ref), [`Position`](@ref)

# Extended Help

## Generated Code
This macro automatically adds custom methods for the provided CRS (and following the provided properties and associated units) to the following functions which are internal to `SatcomCoordinates.jl`:
- [`SatcomCoordinates.units`](@ref)(CRS::Type{<:AbstractCRS})
- [`SatcomCoordinates.resolve_property`](@ref)(CRS::Type{<:AbstractCRS}, propname::Symbol)

### `SatcomCoordinates.units`
The `SatcomCoordinates.units` function operates on a CRS type and must returns a `NamedTuple` with the properties as keys and the associated units as values.

In the default case for custom CRSs, the function method is the following:

```julia
SatcomCoordinates.units(CRS::Type{<:AbstractCRS}) = (; x = u"m", y = u"m", z = u"m")
```

And all additional methods for custom CRSs are expected to be of the same form (i.e. returning a `NamedTuple` with the properties (the baseline ones, not the aliases) as keys and the associated units as values).


### `SatcomCoordinates.resolve_property`
The `SatcomCoordinates.resolve_property` function operates on a CRS type and a property name and must return the name of the property to be used for the `getproperty` call on any coordinate defined over the extended CRS.

Let's consider as an example the the standard (ISO) spherical CRS, which can be mocked up as follows (**this package actually defines and export a more generic `SphericalCRS` which includes the ISO one, the one below is just a simplified mockup**):
```julia
using SatcomCoordinates

struct ISOSpherical <: AbstractCRS end

SatcomCoordinates.@define_properties CustomCRS [
    θ => u"°" => (theta, t)
    φ => u"°" => (phi, p, ϕ)
    r => u"m" => (distance, range)
]
```

In the above code, we want to be able to access e.g. the polar angle `θ` also with the alternative aliases `theta` or `t`.

The `SatcomCoordinates.resolve_property` function generated by the macro in the snippet above is the following:

```julia
Base.@constprop :aggressive function SatcomCoordinates.resolve_property(CRS::Type{<:ISOSpherical}, propname::Symbol)
    if propname in (:θ, :theta, :t)
        :θ
    elseif propname in (:φ, :phi, :p, :ϕ)
        :φ
    elseif propname in (:r, :distance, :range)
        :r
    else
        :__could_not_resolve_property__
    end
end
```

The `Base.@constprop :aggressive` macro is used to encourage constant propagation of symbols when accessed via `getproperty` resulting in no cost access to the same property via multiple aliases.

## Advanced Usage
The macro actually supports also a more advance signature for cases of CRSs that *wrap* a parent CRS and simply want to reuse the same properties of the parent CRS.

This is for example the case for the [`SphericalCRS`](@ref) type, which is a wrapper around another CRS specifying the pointing type (e.g. [`ThetaPhi`](@ref) or [`AzEl`](@ref)).
The [`SphericalCRS`](@ref) needs to _inherit_ the first 2 properties from it's wrapped pointing CRS and just add the third one (`r`).

It is not possible to statically define all the CRS properties in this case, and so the following synthax is used:

```julia
@define_properties SphericalCRS [
    pointingcrs(_)...
    r => u"m" => (distance, range)
]
```

In this alternative synthax, the macro looks for any occurrence of the `...` at the end of an expression 

This expression (without the `...`, so `pointingcrs(_)` above) need to return the wrapped CRS (i.e. the pointing CRS in this example) type.

For convenience, the expression can contain the `_` placeholder to represent the CRS type being extended.

In the specific case above, `pointingcrs` is a function of `SatComCoordinates` which returns the underlying pointing CRS type when called with a `SphericalCRS` type as input.

This special synthax currently only supports a single `...` within a `@define_properties` call, and creates the following generated code (in the case of the example above):

```julia
function SatcomCoordinates.units(CRS::Type{<:SphericalCRS})
    (; SatcomCoordinates.units(SatcomCoordinates.pointingcrs(CRS))..., r = u"m")
end

Base.@constprop :aggressive function SatcomCoordinates.resolve_property(CRS::Type{<:SphericalCRS}, propname::Symbol)
    if propname in (:r, :distance, :range)
        :r
    else
        SatcomCoordinates.resolve_property(SatcomCoordinates.pointingcrs(CRS), propname)
    end
end
```
"""
macro define_properties(CRS, props)
    propspecs = parse_properties_expression(props)
    lnn = __source__
    blk = Expr(:block)
    push!(blk.args, resolve_property_expression(CRS; propspecs, lnn))
    push!(blk.args, units_expression(CRS; propspecs, lnn))
    push!(blk.args, nothing) # This last one is to avoid returning something
    return Expr(:let, Expr(:block), blk) |> esc
end