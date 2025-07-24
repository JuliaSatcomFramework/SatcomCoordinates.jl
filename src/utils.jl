##### Misc Utilities ####
macro define_properties(CRS, props)
	CRS isa Symbol || throw(ArgumentError("The first argument should be the name of the target CRS type"))
	Meta.isexpr(props, :vcat) || throw(ArgumentError("The macro only supports inputs of the form"))
	props = props.args
	propnames = Symbol[]
	units = Expr[]
	alternates = Vector{Symbol}[]
	for ex in props
		Meta.isexpr(ex, :call) && ex.args[1] === :(=>) || throw("The macro expects pairs")
		_, propname, rest = ex.args
		unit, alts = if rest isa Symbol
			rest, Symbol[]
		elseif Meta.isexpr(rest, :tuple)
			unit, alts... = rest.args
			unit, alts
		else
			throw(ArgumentError("The second part of the pair must be"))
		end
		push!(propnames, propname)
		push!(units, :(@u_str($(string(unit)))))
		push!(alternates, alts)
	end
    lnn = __source__
    blk = Expr(:block)
    push!(blk.args, resolve_property_expression(CRS; propnames, alternates, lnn))
    push!(blk.args, coords_units_expression(CRS; propnames, units, lnn))
    return Expr(:let, Expr(:block), blk)
end

function coords_units_expression(CRS::Symbol; propnames, units, lnn::LineNumberNode)
    length(propnames) == length(units) || throw(ArgumentError("The number of property names and units must be the same"))
    kws = Expr(:parameters)
    for i in eachindex(propnames, units)
        push!(kws.args, Expr(:kw, propnames[i], units[i]))
    end
    ntexpr = Expr(:tuple, kws)
    fdef = Expr(:function, Expr(:call, GlobalRef(@__MODULE__, :coords_units), esc(Expr(:(::), Expr(:curly, :Type, CRS)))), Expr(:block, lnn, ntexpr))
end 

function resolve_property_expression(CRS::Symbol; propnames, alternates, lnn::LineNumberNode)
    length(propnames) == length(alternates) || throw(ArgumentError("The number of property names and alternates must be the same"))
	allnames = vcat(propnames, alternates...)
	allunique(allnames) || throw(ArgumentError("The provided property names (with their aliases) are not unique"))
	nprops = length(propnames)
	# Here we build the if-else block. We start from the error
	ifex = :(throw(ArgumentError("The provided symbol is not a valid property"))) |> esc
	midargs(i) = [ 
		:($(esc(:propname)) in $((propnames[i], alternates[i]...))), 
		:(return $(QuoteNode(propnames[i]))) 
	]
	for i in reverse(2:nprops)
		ifex = Expr(:elseif, midargs(i)..., ifex)
	end
	ifex = Expr(:if, midargs(1)..., ifex)
	fdef = Expr(:function, Expr(:call, GlobalRef(@__MODULE__, :resolve_property), esc(Expr(:(::), :crs, Expr(:curly, :Type, CRS))), esc(Expr(:(::), :propname, Symbol))), Expr(:block, lnn, ifex))
	aex = :(Base.@constprop :aggressive $fdef)
end