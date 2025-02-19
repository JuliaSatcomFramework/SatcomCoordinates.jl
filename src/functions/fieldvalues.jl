property_aliases(::Type{<:AbstractFieldValue{T, N, CRS}}) where {T, N, CRS} = property_aliases(CRS)

function raw_properties(fv::AbstractFieldValue{T, N, CRS}) where {T, N, CRS}
    nms = property_names(CRS)
    svector = getfield(fv, :svector)
    return NamedTuple{nms}(Tuple(svector))
end

"""
    raw_svector(fv::AbstractFieldValue)

Return the `SVector` assumed to be contained in the `svector` field of `sv`, eventually stripped of its units if it originally storing `Quantity` elements.
"""
function raw_svector(fv::AbstractFieldValue)
    sv = getfield(fv, :svector)
    if eltype(sv) <: Quantity
        return map(ustrip, sv)
    else
        return sv
    end
end
