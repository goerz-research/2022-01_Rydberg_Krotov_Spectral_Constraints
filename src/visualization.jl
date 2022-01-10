using Plots


function pop_m_l(rho_vec)
    N = isqrt(length(rho_vec))
    return abs.(diag(reshape(rho_vec, N, :))[1:2:end])
end;

function get_rho_pops(states, m_l_vals)
    NT = size(states)[2]
    data = zeros(length(m_l_vals), NT)
    exp_vals = zeros(NT)
    for i in 1:NT
        data[:, i] .=  pop_m_l(states[:, i])
        exp_vals[i] = sum(data[:, i] .* m_l_vals)
    end
    return data, exp_vals
end;

function show_rho_pops(states, m_l_vals)
    data, exp_vals = get_rho_pops(states, m_l_vals)
    fig = heatmap(
        log10.(clamp.(data, 1e-3, 1)),
        c=cgrad(:magma, rev=true),
        colorbar_title="log₁₀(p)",
    )
    n_timesteps = length(exp_vals)
    plot!(
        fig, exp_vals, color=:blue, label="⟨mₗ⟩",
        xlims=(0, n_timesteps), xlabel="time step",
        ylims=(m_l_vals[1], m_l_vals[end]), ylabel="mₗ",
        title="Population in level mₗ (range [10⁻³, 1]) and exp-value ⟨mₗ⟩ over time"
    )
    display(fig)
    println("")
    println("    Final time ⟨m_ₗ⟩: $(exp_vals[end])")
end;


function show_opt_result(opt_result)
    ϵ_real = opt_result.optimized_controls[1]
    ϵ_imag = opt_result.optimized_controls[2]
    show_pulse(ϵ_real, ϵ_imag; tlist=opt_result.tlist)
end


function show_pulse(
        ϵ_real, ϵ_imag;
        ampl_unit=:Vpcm, tlist=nothing, time_unit=:ns,
        xlims=nothing, spec_lims=(0,1), kwargs...
    )
    pulse = ϵ_real + 1im * ϵ_imag / eval(ampl_unit)
    abs_pulse = abs.(pulse)
    n_timesteps = length(pulse)
    ϵ_max = maximum(abs_pulse)
    if tlist ≡ nothing
        if xlims ≡ nothing
            xlims = (0, n_timesteps)
        end
        fig = plot(
            abs_pulse; label="abs(pulse)",
            xlabel="time step", ylabel="ϵ ($ampl_unit)",
            xlims=xlims, ylims=(0, ϵ_max),
            kwargs...
        )
    else
        if xlims ≡ nothing
            xlims = (0, tlist[end] / eval(time_unit))
        end
        if length(tlist) == length(pulse) + 1
            tlist_midpoints = get_tlist_midpoints(tlist)
        elseif length(tlist) == length(pulse)
            tlist_midpoints = tlist
        else
            @show length(tlist)
            @show length(pulse)
            @error "Mismatch between pulse and tlist"
        end
        p1 = plot(
            tlist_midpoints ./ eval(time_unit), abs_pulse; label="abs(pulse)",
            xlabel="time ($time_unit)", ylabel="ϵ ($ampl_unit)",
            xlims=xlims, ylims=(0, ϵ_max), kwargs...
        )
        dt = tlist[2] - tlist[1]
        spec = abs.(fft(pulse));
        freq = fftfreq(length(pulse), eval(time_unit)/dt);
        p2 = plot(
            fftshift(freq), fftshift(spec);
            label="spectrum", xlabel="freq (1/$time_unit)",
            xlims=spec_lims, ylims=(0, maximum(spec)), kwargs...
        )
        fig = plot(p1, p2, layout=(2, 1))
    end
    display(fig)
    println("")
end
