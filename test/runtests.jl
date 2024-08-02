using Revise
using OceanGreensFunctionMethods
using Distributions
using DimensionalData
using DimensionalData: @dim, DimArrayOrStack
using Unitful
# using OrdinaryDiffEq, ModelingToolkit, MethodOfLines, DomadinSets, Unitful
# using DrWatson
# using Plots
using Test

include(srcdir("config_units.jl"))

@testset "OceanGreensFunctionMethods.jl" begin

    @testset "tracer inverse Gaussian distribution" begin
        # compare a Tracer Inverse Gaussian distribution
        # with geophysical arguments
        # to an Inverse Gaussian with statistical arguments
        Γ = 20.0 # mean
        Δ = 20.0 # width

        G = TracerInverseGaussian(Γ, Δ)

        # the Inverse Gaussian distribution in typical statistical toolboxes
        # has different input arguments
        μ = Γ # the same, but different notation
        λ = shape(G) # the shape parameter is the second argument 
        
        G2 = InverseGaussian(μ, λ)

        # both Inverse Gaussians should be the same
        @test isequal(shape(G),shape(G2))
        @test !isequal(params(G),params(G2))
        @test isequal(partype(G), partype(G2)) # parameter type
        @test isequal(mean(G), mean(G2))
        @test isequal(var(G), var(G2))
    end

    @testset "pedagogical tracer box model" begin

        @dim MeridionalLocation "meridional location"
        @dim VerticalLocation "vertical location"

        # define grid
        meridional_locs = ["High latitudes", "Mid-latitudes", "Low latitudes"]
        vertical_locs = [:Thermocline, :Deep, :Abyssal]
        Ny = length(meridional_locs); Nz = length(vertical_locs)
        
        V_uniform = 1e16m^3 |> km^3 # uniform value of volume for all boxes

        model_dims = (MeridionalLocation(meridional_locs),VerticalLocation(vertical_locs))
        V = DimArray(fill(V_uniform, Ny, Nz), model_dims)

        Ψ_abyssal = 20Sv
        Fv_abyssal = abyssal_overturning(Ψ_abyssal, model_dims) # volume fluxes

        Ψ_intermediate = 10Sv
        Fv_intermediate = intermediate_overturning(Ψ_intermediate, model_dims) # volume fluxes

        Fv_exchange = 5Sv
        Fv_diffusion = vertical_diffusion(Fv_exchange, model_dims) # volume fluxes

        Fv = Fv_abyssal + Fv_intermediate + Fv_diffusion

        C = ones(model_dims)

        J = tracer_flux(Fv,C)
        deldotJ = convergence(J)
        deldotFm = mass_convergence(Fv)

        @test all(isapprox.(
            mass_convergence(Fv),
            0.0Tg/s,
            atol=1e-8Tg/s)
        ) # check mass conservation
        
        @test all(isapprox.(
            mass_convergence(Fv_diffusion),
            0.0Tg/s,
            atol=1e-8Tg/s)
        ) # check mass conservation

        @test all(isapprox.(
            mass_convergence(Fv_abyssal),
            0.0Tg/s,
            atol=1e-8Tg/s)
        ) # check mass conservation

        @test all(isapprox.(
            mass_convergence(Fv_intermediate),
            0.0Tg/s,
            atol=1e-8Tg/s)
        ) # check mass conservation

        # other interesting functions
        J_abyssal = tracer_flux(Fv_abyssal,C)
        deldotJ_abyssal = convergence(J_abyssal)
        
        J_intermediate = tracer_flux(Fv_intermediate,C)
        deldotJ_intermediate = convergence(J_intermediate)

        # boundary exchange
        meridional_boundary = ["High latitudes", "Mid-latitudes"]
        vertical_boundary = [:Thermocline]
#        boundary_dims = (MeridionalLocation(meridional_boundary), VerticalLocation(vertical_boundary))
        boundary_dims = (MeridionalLocation(meridional_boundary))
        Fb = DimArray([10Sv 5Sv;], boundary_dims) # boundary flux
        Cb = DimArray(ones(size(boundary_dims)), boundary_dims) # boundary flux

        J_boundary = boundary_flux(Fb,Cb,C)

   end
    
end
