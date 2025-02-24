# This is used to extract dimension directly from the unit type to construct a Quantity object
dimension_from_units_type(::Type{<:Units{N, D}}) where {N, D} = D

svector_size(::Type{<:AbstractFieldValue{U, CRS}}) where {U, CRS} = svector_size(CRS)

function _validate_crs(TP::Type{<:AbstractFieldValue{U, CRS}}) where {U, CRS}
    CRS <: AbstractPosition || throw(ArgumentError("The `CRS` parameter of $TP must be a subtype of `AbstractPosition`"))
    has_numbertype(CRS) && throw(ArgumentError("The `CRS` parameter of $TP must not contain the numbertype parameter."))
end

### Constructor
function construct_inner_svector(TP::Type{<:AbstractFieldValue{U, CRS, T}}, args::Vararg{Number, N}) where {U, CRS, T, N}
    _validate_crs(TP) # We validate the CRS parameter
    NS = svector_size(TP)
    N === NS || throw(ArgumentError("The provided `svector` has $N elements, but should have $(NS) elements as expected from the referenced `CRS` parameter ($CRS)."))
    U === NoUnits && return SVector{N, T}(args...)
    D = dimension_from_units_type(U)
    Q = Quantity{T, D, U}
    # We eventually add the unit and strip it to obtain the raw values
    vals = map(ustrip ∘ Q, args)
    return SVector{N, T}(vals...)
end
(P::Type{<:AbstractFieldValue})(args::Point{N, Number}) where {N} = P(args...)

properties_names(::Type{<:AbstractFieldValue{U, CRS}}) where {U, CRS} = properties_names(CRS)

function ConstructionBase.getproperties(fv::AbstractFieldValue{U, CRS}) where {U, CRS}
    U === NoUnits && return raw_properties(fv)
    D = dimension_from_units_type(U)
    Q{T} = Quantity{T, D, U}
    NamedTuple{properties_names(fv |> typeof)}(map(Q, raw_svector(fv)))
end

raw_svector(fv::AbstractFieldValue) = getfield(fv, :svector)
raw_properties(fv::AbstractFieldValue) = NamedTuple{properties_names(fv |> typeof)}(raw_svector(fv) |> Tuple)