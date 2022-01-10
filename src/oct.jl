using FFTW
using QuantumControl
using QuantumControl.Shapes: flattop

function get_objective(α)

    Ψ₀ = zeros(ComplexF64, N_HILBERT)
    Ψ₀[begin+4] = 1;

    ρ₀ = Ψ₀ * Ψ₀';

    ρ₀_vec = reshape(ρ₀, :);

    Ψ_tgt = zeros(ComplexF64, N_HILBERT)
    Ψ_tgt[end] = 1
    ρ_tgt = Ψ_tgt * Ψ_tgt'
    ρ_tgt_vec = reshape(ρ_tgt, :);

    H_0, H_π, H_σ, pulse = read_data(datadir("PRA"))

    H_drift = H_0 + F_DC * H_π

    L = Liouvillian(H_drift, H_σ, pulse, Dissipator(α));
    objective = Objective(
            initial_state=ρ₀_vec,
            generator=L,
            target_state=ρ_tgt_vec
    )

    return objective
end


function get_tlist_midpoints(tlist)
    tlist_midpoints = zeros(eltype(tlist), length(tlist) - 1)
    tlist_midpoints[1] = tlist[1]
    tlist_midpoints[end] = tlist[end]
    for i in 2:length(tlist_midpoints) - 1
        dt = tlist[i+1] - tlist[i]
        tlist_midpoints[i] = tlist[i] + 0.5 * dt
    end
    return tlist_midpoints
end


function chi_re!(χ, ϕ, objectives)
    @assert length(ϕ) == 1
    χ[1] .= 0.5 .* objectives[1].target_state
end;


function J_T_re(ϕ, objectives)
    @assert length(ϕ) == 1
    return 1.0 - real(dot(objectives[1].target_state, ϕ[1]))
end;


function propagate_guess(objective, tlist, m_l_vals)
    states = propagate_objective(objective, tlist; method=:newton, storage=true)
    show_rho_pops(states, m_l_vals)
end


function propagate_optimized(objective, tlist, m_l_vals, opt_result)
    ϵ0_real, ϵ0_imag = getcontrols([objective])
    states_optimal = propagate_objective(
        objective, tlist; method=:newton, storage=true, m_max=50,
        controls_map=IdDict(
            ϵ0_real => opt_result.optimized_controls[1],
            ϵ0_imag => opt_result.optimized_controls[2],
        )
    )
    show_rho_pops(states_optimal, m_l_vals)
end


function spectral_filter(
        ϵ0_real, ϵ0_imag, tlist;
        ν_min::Float64, ν_max::Float64, t_rise::Float64
    )

    ϵ = ϵ0_real + 1im * ϵ0_imag
    fft = plan_fft!(ϵ)
    ifft = plan_ifft!(ϵ)
    N = length(ϵ)
    @assert length(tlist) == N + 1
    dt = tlist[2] - tlist[1]
    T = tlist[end]
    freq = fftfreq(N, 1/dt)
    filter = ν_min .≤ freq .≤ ν_max;
    shape = flattop.(
        get_tlist_midpoints(tlist);
        t₀=0, T=T, t_rise=t_rise
    );

    function apply_filter(wrk, i, ϵ⁽ⁱ⁺¹⁾, ϵ⁽ⁱ⁾)
        ϵ_real, ϵ_imag = ϵ⁽ⁱ⁺¹⁾
        @. ϵ = ϵ_real + 1im * ϵ_imag
        fft * ϵ
        @. ϵ = filter * ϵ
        ifft * ϵ
        @. ϵ = shape * ϵ
        ϵ_real .= real.(ϵ)
        ϵ_imag .= imag.(ϵ)
    end

    return apply_filter

end


function run_oct(;
    α=1e-11, T=138ns, nt=1380, λₐ=1e12, iter_stop=10000,
    ν_min=0.0, ν_max=0.0, spec_filter_t_rise=2.155ns
)

    println("** Initialize objective")
    @show α
    @show T/ns
    @show nt
    tlist = collect(range(0, T, length=nt))
    objective = get_objective(α)
    ϵ0_real, ϵ0_imag = getcontrols([objective])

    println("** Propagate guess pulse")
    show_pulse(ϵ0_real, ϵ0_imag; tlist=tlist)
    propagate_guess(objective, tlist, M_L_VALS)

    println("** Define control problem")
    update_shape(t) = flattop(t, T=tlist[end], t_rise=5e8, func=:blackman);
    problem = ControlProblem(
        objectives=[objective],
        pulse_options=IdDict(
            ϵ0_real => Dict(:lambda_a => λₐ, :update_shape => update_shape),
            ϵ0_imag => Dict(:lambda_a => λₐ, :update_shape => update_shape),
        ),
        tlist=tlist,
        chi=chi_re!,
        J_T=J_T_re,
        iter_stop=iter_stop,
    );

    println("** Run optimization")
    if (ν_min ≠ 0.0) || (ν_max ≠ 0.0)
        opt_result = optimize(
            problem, method=:krotov,
            update_hook=spectral_filter(
                ϵ0_real, ϵ0_imag, tlist;
                ν_min=ν_min, ν_max=ν_max, t_rise=spec_filter_t_rise,
            )
        )
    else
        opt_result = optimize(
            problem, method=:krotov,
        )
    end
    show_opt_result(opt_result)

    println("** Propagate optimized pulse")
    propagate_optimized(objective, tlist, M_L_VALS, opt_result)

    println("DONE")

    return opt_result

end
