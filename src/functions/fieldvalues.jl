property_aliases(::Type{<:AbstractFieldValue{T, N, CRS}}) where {T, N, CRS} = property_aliases(CRS)

function raw_properties(fv::AbstractFieldValue{T, N, CRS}) where {T, N, CRS}
    nms = property_names(CRS)
    svector = getfield(fv, :svector)
    return NamedTuple{nms}(Tuple(svector))
end