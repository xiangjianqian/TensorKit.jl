# Sectors corresponding to irreducible representations of compact groups
#==============================================================================#
# Irreps of Abelian groups
#------------------------------------------------------------------------------#
abstract type AbelianIrrep <: Sector end

Base.@pure fusiontype(::Type{<:AbelianIrrep}) = Abelian
Base.@pure braidingtype(::Type{<:AbelianIrrep}) = Bosonic

Nsymbol(a::G, b::G, c::G) where {G<:AbelianIrrep} = c == first(a ⊗ b)
Fsymbol(a::G, b::G, c::G, d::G, e::G, f::G) where {G<:AbelianIrrep} =
    Int(Nsymbol(a,b,e)*Nsymbol(e,c,d)*Nsymbol(b,c,f)*Nsymbol(a,f,d))
frobeniusschur(a::AbelianIrrep) = 1
Bsymbol(a::G, b::G, c::G) where {G<:AbelianIrrep} = Float64(Nsymbol(a, b, c))
Rsymbol(a::G, b::G, c::G) where {G<:AbelianIrrep} = Float64(Nsymbol(a, b, c))

fusiontensor(a::G, b::G, c::G, v::Void = nothing) where {G<:AbelianIrrep} = fill(Float64(Nsymbol(a,b,c)), (1,1,1))

# ZNIrrep: irreps of Z_N are labelled by integers mod N; do we ever want N > 127?
struct ZNIrrep{N} <: AbelianIrrep
    n::Int8
    function ZNIrrep{N}(n::Integer) where {N}
        new{N}(mod(n, N))
    end
end
Base.one(::Type{ZNIrrep{N}}) where {N} =ZNIrrep{N}(0)
Base.conj(c::ZNIrrep{N}) where {N} = ZNIrrep{N}(-c.n)
⊗(c1::ZNIrrep{N}, c2::ZNIrrep{N}) where {N} = (ZNIrrep{N}(c1.n+c2.n),)

Base.convert(Z::Type{<:ZNIrrep}, n::Real) = Z(convert(Int, n))

const ℤ₂ = ZNIrrep{2}
const ℤ₃ = ZNIrrep{3}
const ℤ₄ = ZNIrrep{4}
const Parity = ZNIrrep{2}
Base.show(io::IO, ::Type{ZNIrrep{2}}) = print(io, "ℤ₂")
Base.show(io::IO, ::Type{ZNIrrep{3}}) = print(io, "ℤ₃")
Base.show(io::IO, ::Type{ZNIrrep{4}}) = print(io, "ℤ₄")
Base.show(io::IO, c::ZNIrrep{2}) = get(io, :compact, false) ? print(io, c.n) : print(io, "ℤ₂(", c.n, ")")
Base.show(io::IO, c::ZNIrrep{3}) = get(io, :compact, false) ? print(io, c.n) : print(io, "ℤ₃(", c.n, ")")
Base.show(io::IO, c::ZNIrrep{4}) = get(io, :compact, false) ? print(io, c.n) : print(io, "ℤ₄(", c.n, ")")
Base.show(io::IO, c::ZNIrrep{N}) where {N} = get(io, :compact, false) ? print(io, c.n) :
    print(io, "ZNIrrep{", N, "}(" , c.n, ")")

# U1Irrep: irreps of U1 are labelled by integers
struct U1Irrep <: AbelianIrrep
    charge::Rational{Int}
end
Base.one(::Type{U1Irrep}) = U1Irrep(0)
Base.conj(c::U1Irrep) = U1Irrep(-c.charge)
⊗(c1::U1Irrep, c2::U1Irrep) = (U1Irrep(c1.charge+c2.charge),)

Base.convert(::Type{U1Irrep}, c::Real) = U1Irrep(convert(Rational{Int}, c))

const U₁ = U1Irrep
Base.show(io::IO, ::Type{U1Irrep}) = print(io, "U₁")
Base.show(io::IO, c::U1Irrep) = get(io, :compact, false) ? print(io, c.charge) : print(io, "U₁(", c.charge, ")")

# NOTE: FractionalU1Charge?

# Nob-abelian groups
#------------------------------------------------------------------------------#
# HalfInteger
struct HalfInteger <: Real
    num::Int
end
Base.:+(a::HalfInteger, b::HalfInteger) = HalfInteger(a.num+b.num)
Base.:-(a::HalfInteger, b::HalfInteger) = HalfInteger(a.num-b.num)
Base.:-(a::HalfInteger) = HalfInteger(-a.num)
Base.:<=(a::HalfInteger, b::HalfInteger) = a.num <= b.num
Base.:<(a::HalfInteger, b::HalfInteger) = a.num < b.num
Base.one(::Type{HalfInteger}) = HalfInteger(2)
Base.zero(::Type{HalfInteger}) = HalfInteger(0)

Base.promote_rule(::Type{HalfInteger}, ::Type{<:Integer}) = HalfInteger
Base.promote_rule(::Type{HalfInteger}, T::Type{<:Rational}) = T
Base.promote_rule(::Type{HalfInteger}, T::Type{<:Real}) = T

Base.convert(::Type{HalfInteger}, n::Integer) = HalfInteger(2*n)
function Base.convert(::Type{HalfInteger}, r::Rational)
    if r.den == 1
        return HalfInteger(2*r.num)
    elseif r.den == 2
        return HalfInteger(r.num)
    else
        throw(InexactError())
    end
end
Base.convert(::Type{HalfInteger}, r::Real) = convert(HalfInteger, convert(Rational, r))
Base.convert(T::Type{<:Real}, s::HalfInteger) = convert(T, s.num//2)
Base.convert(::Type{HalfInteger}, s::HalfInteger) = s

# SU2Irrep: irreps of SU2 are labelled by half integers j, internally we use the integer dimension 2j+1 instead
import WignerSymbols

struct SU2IrrepException <: Exception end
Base.show(io::IO, ::SU2IrrepException) = print(io, "Irreps of (bosonic or fermionic) `SU₂` should be labelled by non-negative half integers, i.e. elements of `Rational{Int}` with denominator 1 or 2")

struct SU2Irrep <: Sector
    j::HalfInteger
end
_getj(s::SU2Irrep) = s.j.num//2

Base.one(::Type{SU2Irrep}) = SU2Irrep(zero(HalfInteger))
Base.conj(s::SU2Irrep) = s
⊗(s1::SU2Irrep, s2::SU2Irrep) = SectorSet{SU2Irrep}(HalfInteger, abs(s1.j.num-s2.j.num):2:(s1.j.num+s2.j.num) )

Base.convert(::Type{SU2Irrep}, j::HalfInteger) = SU2Irrep(j)
Base.convert(::Type{SU2Irrep}, j::Real) = SU2Irrep(convert(HalfInteger, j))

dim(s::SU2Irrep) = s.j.num+1

Base.@pure fusiontype(::Type{SU2Irrep}) = SimpleNonAbelian
Base.@pure braidingtype(::Type{SU2Irrep}) = Bosonic

Nsymbol(sa::SU2Irrep, sb::SU2Irrep, sc::SU2Irrep) = WignerSymbols.δ(_getj(sa), _getj(sb), _getj(sc))
Fsymbol(s1::SU2Irrep, s2::SU2Irrep, s3::SU2Irrep, s4::SU2Irrep, s5::SU2Irrep, s6::SU2Irrep) =
    WignerSymbols.racahW(map(_getj,(s1,s2,s4,s3,s5,s6))...)*sqrt(dim(s5)*dim(s6))
function Rsymbol(sa::SU2Irrep, sb::SU2Irrep, sc::SU2Irrep)
    Nsymbol(sa, sb, sc) || return 0.
    iseven(convert(Int, _getj(sa)+_getj(sb)-_getj(sc))) ? 1.0 : -1.0
end

function fusiontensor(a::SU2Irrep, b::SU2Irrep, c::SU2Irrep, v::Void = nothing)
    C = Array{Float64}(uninitialized, dim(a), dim(b), dim(c))
    ja, jb, jc = map(_getj, (a, b, c))

    for kc = 1:dim(c), kb = 1:dim(b), ka = 1:dim(a)
        C[ka,kb,kc] = WignerSymbols.clebschgordan(ja, ka-ja-1, jb, kb-jb-1, jc, kc-jc-1)
    end
    return C
end

const SU₂ = SU2Irrep
Base.show(io::IO, ::Type{SU2Irrep}) = print(io, "SU₂")
Base.show(io::IO, s::SU2Irrep) = get(io, :compact, false) ? print(io, _getj(s)) : print(io, "SU₂(", _getj(s), ")")

# U₁ ⋉ C (U₁ and charge conjugation)
struct CU1Irrep <: Sector
    j::HalfInteger # value of the U1 charge
    s::Int # rep of charge conjugation: if j == 0, s = 0 (trivial) or s = 1 (non-trivial), else s = 2 (two-dimensional representation)
    # Let constructor take the actual half integer value j
    CU1Irrep(j::HalfInteger, s::Int = ifelse(j>0, 2, 0)) = ((j > 0 && s == 2) || (j == 0 && (s == 0 || s == 1))) ? new(j, s) : error("Not a valid CU₁ irrep")
end
_getj(s::CU1Irrep) = s.j.num//2

CU1Irrep(j::Real, s::Int = ifelse(j>0, 2, 0)) = CU1Irrep(convert(HalfInteger, j), s)

Base.convert(::Type{CU1Irrep}, j::Real) = CU1Irrep(j)
Base.convert(::Type{CU1Irrep}, js::Tuple{Real,Int}) = CU1Irrep(js...)

Base.one(::Type{CU1Irrep}) = CU1Irrep(zero(HalfInteger), 0)
Base.conj(c::CU1Irrep) = c

struct CU1ProdIterator
    a::CU1Irrep
    b::CU1Irrep
end
Base.start(p::CU1ProdIterator) = 1
function Base.next(p::CU1ProdIterator, s::Int)
    if s == 1
        if p.a == p.b
            return one(CU1Irrep), s+1
        elseif p.a.j == p.b.j == zero(HalfInteger)
            return CU1Irrep(zero(HalfInteger), 1), s+1
        else
            return CU1Irrep(abs(p.a.j - p.b.j)),  s+1
        end
    elseif s == 2
        (p.a == p.b  ? CU1Irrep(zero(HalfInteger), 1) : CU1Irrep(p.a.j + p.b.j)), s+1
    else
        CU1Irrep(p.a.j + p.b.j), s+1
    end
end
function Base.done(p::CU1ProdIterator, s::Int)
    if p.a.j == zero(HalfInteger) || p.b.j == zero(HalfInteger)
        s > 1
    elseif p.a == p.b
        s > 3
    else
        s > 2
    end
end
function Base.length(p::CU1ProdIterator)
    if p.a.j == zero(HalfInteger) || p.b.j == zero(HalfInteger)
        return 1
    elseif p.a == p.b
        return 3
    else
        return 2
    end
end

⊗(a::CU1Irrep, b::CU1Irrep) = CU1ProdIterator(a, b)

dim(c::CU1Irrep) = ifelse(c.j == zero(HalfInteger), 1, 2)

Base.@pure fusiontype(::Type{CU1Irrep}) = SimpleNonAbelian
Base.@pure braidingtype(::Type{CU1Irrep}) = Bosonic

function Nsymbol(a::CU1Irrep, b::CU1Irrep, c::CU1Irrep)
    ifelse(c.s == 0, (a.j == b.j) & ((a.s == b.s == 2) | (a.s == b.s)),
        ifelse(c.s == 1, (a.j == b.j) & ((a.s == b.s == 2) | (a.s != b.s)),
        (c.j == a.j + b.j) | (c.j == abs(a.j - b.j)) ))
end
function Fsymbol(a::CU1Irrep, b::CU1Irrep, c::CU1Irrep, d::CU1Irrep, e::CU1Irrep, f::CU1Irrep)
    Nabe = convert(Int, Nsymbol(a,b,e))
    Necd = convert(Int, Nsymbol(e,c,d))
    Nbcf = convert(Int, Nsymbol(b,c,f))
    Nafd = convert(Int, Nsymbol(a,f,d))

    Nabe*Necd*Nbcf*Nafd == 0 && return 0.

    op = CU1Irrep(0,0)
    om = CU1Irrep(0,1)

    if a == op || b == op || c == op
        return 1.
    end
    if (a == b == om) || (a == c == om) || (b == c == om)
        return 1.
    end
    if a == om
        if d.j == zero(HalfInteger)
            return 1.
        else
            return (d.j == c.j - b.j) ? -1. : 1.
        end
    end
    if b == om
        return (d.j == abs(a.j - c.j)) ? -1. : 1.
    end
    if c == om
        return (d.j == a.j - b.j) ? -1. : 1.
    end
    # from here on, a,b,c are neither 0+ or 0-
    s = sqrt(2)/2
    if a == b == c
        if d == a
            if e.j == 0
                if f.j == 0
                    return f.s == 1 ? -0.5 : 0.5
                else
                    return e.s == 1 ? -s : s
                end
            else
                return f.j == 0 ? s : 0.
            end
        else
            return 1.
        end
    end
    if a == b # != c
        if d == c
            if f.j == b.j + c.j
                return e.s == 1 ? -s : s
            else
                return s
            end
        else
            return 1.
        end
    end
    if b == c
        if d == a
            if e.j == a.j + b.j
                return s
            else
                return f.s == 1 ? -s : s
            end
        else
            return 1.
        end
    end
    if a == c
        if d == b
            if e.j == f.j
                return 0.
            else
                return 1.
            end
        else
            return d.s == 1 ? -1. : 1.
        end
    end
    if d == om
        return b.j == a.j + c.j ? -1. : 1.
    end
    return 1.
end
function Rsymbol(a::CU1Irrep, b::CU1Irrep, c::CU1Irrep)
    R = convert(Float64, Nsymbol(a, b, c))
    return c.s == 1 && a.j > 0 ? -R : R
end

function fusiontensor(a::CU1Irrep, b::CU1Irrep, c::CU1Irrep, ::Void = nothing)
    C = fill(0., dim(a), dim(b), dim(c))
    !Nsymbol(a,b,c) && return C
    if c.j == 0
        if a.j == b.j == 0
            C[1,1,1] = 1.
        else
            if c.s == 0
                C[1,2,1] = 1./sqrt(2)
                C[2,1,1] = 1./sqrt(2)
            else
                C[1,2,1] = 1./sqrt(2)
                C[2,1,1] = -1./sqrt(2)
            end
        end
    elseif a.j == 0
        C[1,1,1] = 1.
        C[1,2,2] = a.s == 1 ? -1. : 1.
    elseif b.j == 0
        C[1,1,1] = 1.
        C[2,1,2] = b.s == 1 ? -1. : 1.
    elseif c.j == a.j + b.j
        C[1,1,1] = 1.
        C[2,2,2] = 1.
    elseif c.j == a.j - b.j
        C[1,2,1] = 1.
        C[2,1,2] = 1.
    elseif c.j == b.j - a.j
        C[2,1,1] = 1.
        C[1,2,2] = 1.
    end
    return C
end
#
const CU₁ = CU1Irrep
Base.show(io::IO, ::Type{CU1Irrep}) = print(io, "CU₁")
Base.show(io::IO, c::CU1Irrep) = get(io, :compact, false) ? print(io, "(", _getj(c), ", ", c.s, ")") : print(io, "CU₁(", _getj(c), ", ", c.s, ")")
