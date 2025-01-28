using TestItemRunner

@testitem "Aqua" begin
    using Aqua
    Aqua.test_all(SatcomCoordinates; ambiguities = false) 
    Aqua.test_ambiguities(SatcomCoordinates)
end

@run_package_tests verbose=true