using DelimitedFiles
using MatrixMarket
using LinearAlgebra
using SparseArrays


const F_DC = 4.5622440804451624e-10 # Electric field used for the DC dressed basis
const M_L_MAX = 50  # 0... M_L_MAX
const N_HILBERT = 2 * M_L_MAX + 1
const M_L_VALS = collect(0:M_L_MAX)

const 𝕚 = 1im;

⊗(A, B) = kron(A, B);


function read_pulse(filename, unit)
    data = readdlm(filename, skipstart=2)
    return (data[:, 2] + 𝕚 * data[:, 3]) * unit
end


function lindblad_to_superop(A)
    A⁺ = sparse(A')
    Aᵀ = sparse(transpose(A))
    A⁺_A = A⁺ * A
    A⁺_Aᵀ = sparse(transpose(A⁺_A))
    𝟙 = SparseMatrixCSC{ComplexF64, Int64}(sparse(I, size(A)[1], size(A)[2]))
    D = Aᵀ ⊗ A - (𝟙 ⊗ A⁺_A)/2 - (A⁺_Aᵀ ⊗ 𝟙)/2
    return 𝕚 * D  # factor 𝕚 accounts for 𝕚ħρ̇ = Lρ (TDSE equivalence)
end;


"""Construct the total dissipator for the Rydberg system."""
function Dissipator(α, n_hilbert=N_HILBERT, n=M_L_MAX+1)
    m_l_max = n - 1
    n_D = n_hilbert^2
    op_n(n, n_hilbert=N_HILBERT) = (
        sparse([n+1,], [n+1,], [1+0im], n_hilbert, n_hilbert)
    )
    D = spzeros(ComplexF64, n_D, n_D)
    for mₗ = 0:m_l_max
        γ = α * (n - mₗ - 1)
        L₁ = √γ * op_n(2mₗ)
        D += lindblad_to_superop(L₁)
        if mₗ < m_l_max
            L₂ = √γ * op_n(2mₗ + 1)
            D += lindblad_to_superop(L₂)
        end
    end
    return D
end;


function ham_to_superop(H)
    𝟙 = SparseMatrixCSC{ComplexF64, Int64}(sparse(I, size(H)[1], size(H)[2]))
    H_T = sparse(transpose(H))
    L = 𝟙 ⊗ H - H_T ⊗ 𝟙
    return L
end;


@doc raw"""Construct the time-dependent Liouvillian in nested-tuple format.

Note that this Liouvillian is for the equation of motion ``i\hbar\rho\dot(T) =
L \rho(t)``, to be exactly analogous to the Schrödinger equation. This is
contrary to common conventions, but it make propagation much easier.
"""
function Liouvillian(H_drift, H_σ, pulse, dissipator)
    L0 = ham_to_superop(H_drift) + dissipator
    H_re = H_σ + H_σ'
    H_im = 𝕚 * (H_σ - H_σ')
    L_re = ham_to_superop(H_re)
    L_im = ham_to_superop(H_im)
    S_re = real(pulse)
    S_im = imag(pulse)
    return (L0, (L_re, S_re), (L_im, S_im))
end;


function read_data(datadir)
    H_0 = mmread("$datadir/ham_drift.mtx");
    H_π = mmread("$datadir/ham_pi.mtx");
    H_σ = mmread("$datadir/ham_sig.mtx");
    S = read_pulse("$datadir/pulse_sig.dat", Vpcm)
    return H_0, H_π, H_σ, S
end
