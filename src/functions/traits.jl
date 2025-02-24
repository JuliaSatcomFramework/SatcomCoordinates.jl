position_trait(::Type{<:AbstractPosition}) = CartesianPositionTrait()
position_trait(coords::AbstractPosition) = position_trait(typeof(coords))