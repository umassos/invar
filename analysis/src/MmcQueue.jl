module MmcQueue
export erlang_c, erlang_c_ub

function erlang_c(c, r)
    c = big(c)
    c = big(c)
    t = (r^c) / (factorial(c) * (1 - r / c))
    t / (t + sum(r^n / factorial(n) for n in 0:c-1))
end

import Distributions: Normal, cdf, pdf
n = Normal()
Φ(x) = cdf(n, x)
ϕ(x) = pdf(n, x)

function erlang_c_ub(c, r)
    ρ = r / c
    α = sqrt(-2 * c * (1 - ρ + log(ρ)))
    γ = (c - r) / sqrt(c)
    (ρ + γ * (Φ(α) / ϕ(α) + 2 / (3 * sqrt(c))))^-1
end

function mean_waiting_time(c, λ, μ)
    r = λ / μ
    ρ = r / c
    1 / λ * erlang_c(c, r) * ρ / (1 - ρ)
end
end
