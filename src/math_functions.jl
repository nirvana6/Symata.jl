## First pass at math functions. There are more domain restrictions to be implemented.

# Taken from compat.jl
# Pull Request https://github.com/JuliaLang/julia/pull/13232
# Rounding and precision functions:
if VERSION >= v"0.5.0-dev+1182"
    import Base:
        setprecision, setrounding, rounding

else  # if VERSION < v"0.5.0-dev+1182"

    export setprecision
    export setrounding
    export rounding

    setprecision(f, ::Type{BigFloat}, prec) = with_bigfloat_precision(f, prec)
    setprecision(::Type{BigFloat}, prec) = set_bigfloat_precision(prec)

    # assume BigFloat if type not explicit:
    setprecision(prec) = setprecision(BigFloat, prec)
    setprecision(f, prec) = setprecision(f, BigFloat, prec)

    Base.precision(::Type{BigFloat}) = get_bigfloat_precision()

    setrounding(f, T, rounding_mode) =
        with_rounding(f, T, rounding_mode)

    setrounding(T, rounding_mode) = set_rounding(T, rounding_mode)

    rounding(T) = get_rounding(T)

end

# Bind SJulia symbols to Julia types so that, eg.
# Head(1.0) == Float64  is true
# But, this breaks the pattern matching code,
# which could be fixed to work this way as well.
# function bind_types()
#     for x in ("Int","Float64","Int64")  # etc.
#         t = Main.eval(parse(x))
#         s = symbol(x)
#         setsymval(s,t)
#     end
# end
# bind_types()

# Workaround till we solve the Int64 Symbol vs DataType problem is to make
# new symbols bound to the data types. So to test that 1//1 does not evaluate to
# Rational, we can do Head(1//1) == Int64T
function bind_types()
    for x in ("Int","Float64","Int64")  # etc.
        t = SJulia.eval(parse(x))
        s = symbol(x * "T")  # ie Int64T , etc
        setsymval(s,t)  #  SJulia symbol  Int64T is bound to Julia data type Int64
    end
end
bind_types()

# We want to put things into modules eventually
function evalmath(x)
    SJulia.eval(x)
end

## We also need to use these to convert SJulia expressions to Julia

## This function writes apprules for math functions. Usally dispatches floating point
## args to Julia functions. Some have a fall through to SymPy

## These tuples have 1,2, or 3 members. Symbols are for Julia, SJulia, and SymPy
## If only one member is present, the second is constructed by putting an inital capital on the first.
## If only one or two members are present, we do not fall back to SymPy.
## The last list has tuples with 2 args for which we do not use any Julia function.

## This is far from complete

# Typical symbols for Julia, SJulia, SymPy
function mtr(sym::Symbol)
    s = string(sym)
    sjf = uppercase(string(s[1])) * s[2:end]
    (sym, symbol(sjf), sym)
end

function make_math()
    single_arg_float_complex =   # check, some of these can't take complex args
#
        [ (:sin,), (:tan,), (:sind,:SinD), (:cosd,:CosD),(:tand,:TanD),
         (:sinpi,:SinPi), (:cospi,:CosPi), (:sinh,),(:cosh,),
         (:tanh,), (:acos,:ArcCos), (:asin,:ArcSin),
         (:atan,:ArcTan),(:atan2,:ArcTan2),(:acosd,:ArcCosD), (:asind,:ArcSinD),
         (:atand,:ArcTanD),(:sec,),(:csc,),(:cot,),(:secd,:SecD),(:csc,:CscD),(:cot,:CotD),
         (:asec,:ArcSec),(:acsc,:ArcCsc),(:acot,:ArcCot),  # (:acotd,:ArcCotD)
         (:csch,),(:coth,),(:asinh,:ASinh),(:acosh,:ACosh),(:atanh,:ATanh),
         (:asech,:ArcSech),(:acsch,:ArcCsch),(:acoth,:ArcCoth),
         (:sinc,),(:cosc,),
         (:log1p,),(:exp2,),(:exp10,),(:expm1,),(:abs2,),
         mtr(:erf), mtr(:erfc), mtr(:erfi),(:erfcx,),(:dawson,),(:real,:Re),(:imag,:Im),
         (:angle,:Arg),(:cis,),(:gamma, :Gamma, :gamma), (:lgamma, :LogGamma),
    (:lfact,:LogFactorial), mtr(:digamma), mtr(:trigamma),
    (:airyai,:AiryAi,:airyai),
         (:airybi,:AiryBi,:airybi),(:airyaiprime,:AiryAiPrime,:airyaiprime),(:airybiprime,:AiryBiPrime,:airybiprime),
         (:besselj0,:BesselJ0),(:besselj1,:BesselJ1),(:bessely0,:BesselY0),(:bessely1,:BesselY1),
         (:eta,), (:zeta,:Zeta,:zeta)
         ]

# (:log,),   removed from list above, because it must be treated specially (and others probably too!)

    single_arg_float_int_complex =
        [
         (:conj,:Conjugate)
         ]

    single_arg_float = [(:cbrt,:CubeRoot),(:erfinv,:InverseErf,:erfinv),(:erfcinv,:InverseErfc,:erfcinv),(:invdigamma,:InverseDigamma)
                        ]

    single_arg_float_int = [(:factorial,),(:sign,),(:signbit,:SignBit)]

    single_arg_int = [(:isqrt,:ISqrt),(:ispow2,:IsPow2),(:nextpow2,:NextPow2),(:prevpow2,:PrevPow2),
                      (:isprime,:PrimeQ)
                        ]

    two_arg_int = [(:binomial,),(:ndigits,:NDigits)
                   ]

    two_arg_float_and_float_or_complex =
     [
      (:besselj,:BesselJ, :besselj), (:besseljx,:BesselJx), (:bessely,:BesselY,:bessely),
      (:besselyx,:BesselYx), (:hankelh1,:HankelH1,:hankel1), (:hankelh1x,:HankelH1x),
      (:hankelh2,:HankelH2,:hankel2), (:hankelh2x,:HankelH2x), (:besseli,:BesselI, :besseli),
      (:besselix,:BesselIx), (:besselk,:BesselK,:besselk), (:besselkx,:BesselKx),
      ]

    two_arg_float = [ (:beta,),(:lbeta,:LogBeta),(:hypot,)]

    ## There are no Julia functions for these (or at least we are not using them).
    ## First symbol is for  SJulia, Second is SymPy

    # There is LambertW Julia code, but we do not use it.
    no_julia_function = [(:LambertW, :LambertW), (:Harmonic, :harmonic), (:ExpIntegralE, :expint)]
    
# two arg both float or complex : zeta(s,z)  (with domain restrictions)

    for x in no_julia_function
        set_up_sympy_default(x...)
    end
    
    for x in single_arg_float_complex
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf(mx::Mxpr{:$sjf},x::AbstractFloat) = $jf(x)"
        aprs3 = "do_$sjf{T<:AbstractFloat}(mx::Mxpr{:$sjf},x::Complex{T}) = $jf(x)"
        evalmath(parse(aprs2))
        evalmath(parse(aprs3))
    end

    for x in single_arg_float
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf(mx::Mxpr{:$sjf},x::AbstractFloat) = $jf(x)"
        evalmath(parse(aprs2))
    end

    for x in single_arg_float_int
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf(mx::Mxpr{:$sjf},x::Real) = $jf(x)" # may not work for rational
        evalmath(parse(aprs2))
    end

    # This is all numbers, I suppose
    for x in single_arg_float_int_complex
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf(mx::Mxpr{:$sjf},x::Number) = $jf(x)" # may not work for rational
        evalmath(parse(aprs2))
    end

    for x in single_arg_int
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf(mx::Mxpr{:$sjf},x::Integer) = $jf(x)"
        evalmath(parse(aprs2))
    end

    for x in two_arg_int
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf(mx::Mxpr{:$sjf},x::Integer,y::Integer) = $jf(x,y)"
        evalmath(parse(aprs2))
    end

    for x in two_arg_float
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf{T<:AbstractFloat,V<:AbstractFloat}(mx::Mxpr{:$sjf},x::T,y::V) = $jf(x,y)"
        evalmath(parse(aprs2))
    end

    for x in two_arg_float_and_float_or_complex
        jf,sjf = get_sjstr(x...)
        aprs2 = "do_$sjf(mx::Mxpr{:$sjf},x::AbstractFloat,y::AbstractFloat) = $jf(x,y)"
        aprs3 = "do_$sjf{T<:AbstractFloat}(mx::Mxpr{:$sjf},x::AbstractFloat,y::Complex{T}) = $jf(x,y)"
        aprs4 = "do_$sjf(mx::Mxpr{:$sjf},x::Int,y::AbstractFloat) = $jf(x,y)"        
        evalmath(parse(aprs2))
        evalmath(parse(aprs3))
        evalmath(parse(aprs4))        
    end
    
end

function get_sjstr(jf,sjf)
    do_common(sjf)    
    return jf, sjf
end
                
function get_sjstr(jf)
    st = string(jf)
    sjf = uppercase(string(st[1])) * st[2:end]
    do_common(sjf)
    return jf, sjf    
end

# Handle functions that fall back on SymPy
function get_sjstr(jf, sjf, sympyf)
    set_up_sympy_default(sjf, sympyf)
    return jf, sjf
end

function set_up_sympy_default(sjf, sympyf)
    aprs = "SJulia.apprules(mx::Mxpr{:$sjf}) = do_$sjf(mx,margs(mx)...)"
    aprs1 = "do_$sjf(mx::Mxpr{:$sjf},x...) = (sympy.$sympyf(map(mxpr2sympy,x)...) |> sympy2mxpr)"
    evalmath(parse(aprs))
    evalmath(parse(aprs1))
    set_attribute(symbol(sjf),:Protected)
    set_attribute(symbol(sjf),:Listable)        
end

# Handle functions that do *not* fall back on SymPy
function do_common(sjf)
    aprs = "SJulia.apprules(mx::Mxpr{:$sjf}) = do_$sjf(mx,margs(mx)...)"
    aprs1 = "do_$sjf(mx::Mxpr{:$sjf},x...) = mx"
    evalmath(parse(aprs))
    evalmath(parse(aprs1))
    set_attribute(symbol(sjf),:Protected)
    set_attribute(symbol(sjf),:Listable)
end

make_math()

do_Abs2(mx::Mxpr{:Abs2},x::Integer) = x*x
do_Abs2{T<:Integer}(mx::Mxpr{:Abs2},z::Complex{T}) = ((x,y) = reim(z); x*x + y*y)

do_ArcTan(mx::Mxpr{:ArcTan},x::Integer) = x == 1 ? 4 * :Pi : x == 0 ? 0 : mx
do_ArcTan(mx::Mxpr{:ArcTan},x::SJSym) = x == :Infinity ? 1//2 * :Pi : mx

do_Gamma(mx::Mxpr{:Gamma},x) = sympy2mxpr(sympy.gamma(mxpr2sympy(x)))
do_Gamma(mx::Mxpr{:Gamma},x,y) = sympy2mxpr(sympy.uppergamma(mxpr2sympy(x),mxpr2sympy(y)))

@sjdoc IntegerDigits "
IntegerDigits(n,[, base][, pad]) Returns an array of the digits of \"n\" in the given base,
optionally padded with zeros to a specified size. In contrast to Julia, more significant
digits are at lower indexes.
"

do_common("IntegerDigits")
#apprules(mx::Mxpr{:IntegerDigits}) = do_IntegerDigits(mx,margs(mx)...)
#do_IntegerDigits(mx,args...) = mx
do_IntegerDigits(mx::Mxpr{:IntegerDigits},n::Integer) = setfixed(mxpr(:List,reverse!(digits(n))...))
do_IntegerDigits(mx::Mxpr{:IntegerDigits},n::Integer,b::Integer) = setfixed(mxpr(:List,reverse!(digits(n,b))...))
do_IntegerDigits(mx::Mxpr{:IntegerDigits},n::Integer,b::Integer,p::Integer) = setfixed(mxpr(:List,reverse!(digits(n,b,p))...))

@sjdoc Primes "
Primes(n) returns a collection of the prime numbers <= \"n\"
"
apprules(mx::Mxpr{:Primes}) = do_Primes(mx,margs(mx)...)
do_Primes(mx,args...) = mx
do_Primes(mx,n::Integer) = setfixed(mxpr(:List,primes(n)...))

do_NDigits(mx::Mxpr{:NDigits},n::Integer) = ndigits(n)

# use SymPy instead
# do_Erf(mx::Mxpr{:Erf}, b::SJSym) = b == :Infinity ? 1 : mx
# do_Erf(mx::Mxpr{:Erf}, b::Integer) = b == 0 ? 0 : mx

# use SymPy instead
# do_Zeta(mx::Mxpr{:Zeta}, b::Integer) = b == 0 ? -1//2 : b == -1 ? 1//12 : b == 4 ? 1//90 * :Pi^4 : mx

do_common("Log")
do_Log(mx::Mxpr{:Log},x::AbstractFloat) = x > 0 ? log(x) : log(complex(x))
do_Log{T<:AbstractFloat}(mx::Mxpr{:Log},x::Complex{T}) = log(x)
do_Log{T<:AbstractFloat}(mx::Mxpr{:Log},b::Real,z::Complex{T}) = log(b,z)
do_Log{T<:AbstractFloat}(mx::Mxpr{:Log},b::Real,z::T) = z > 0 ? log(b,z) : log(b,complex(z))

# This is probably quite slow, but might be correct in many cases
# The same idea could be used for other functions, such as sqrts etc.
function do_Log(mx::Mxpr{:Log},b::Integer,x::Integer)
    res = round(Int,log(b,x))
    return b^res == x ? res : mx
end
do_Log(mx::Mxpr{:Log},pow::Mxpr{:Power}) = do_Log(mx,pow,base(pow),expt(pow))
do_Log(mx::Mxpr{:Log},pow::Mxpr{:Power},b,e) = mx
do_Log(mx::Mxpr{:Log},pow::Mxpr{:Power},b::SJSym,e::Integer) = b == :E ? e : mx
do_Log(mx::Mxpr{:Log},b::SJSym) = b == :E ? 1 : mx

@sjdoc N "
N(expr) tries to give a the numerical value of expr.
N(expr,p) tries to give p decimal digits of precision.
"

function apprules(mx::Mxpr{:N})
    do_N(margs(mx)...)
end

do_N(x,dig) = x
do_N(x) = x
do_N(n::Integer) = float(n)
do_N(n::Rational) = float(n)

function do_N(n::Integer,p::Integer)
    float_with_precision(n,p)
end
function do_N(n::Rational,p::Integer)
    float_with_precision(n,p)
end

# p is number of decimal digits of precision
# Julia doc says set_bigfloat_precision uses
# binary digits, but it looks more like decimal.
#
# The length of the string printed is about
# p digits long if we do set_bigfloat_precision(p).
# Or not sometimes. Don't know what is happening.
# propagation of precision with operations or something.
#
# One problem is that bigfloat arithmetic does not use the
# precision of the input types, but rather the current working
# precision.
# So N(2*Pi,1000) does not do what we want.
# It may be expensive to change it on the fly.

function float_with_precision(x,p)
    if p > 16
#        pr = precision(BigFloat)
        pr = precision(BigFloat)
        dig = round(Int,p*3.322)
#        set_bigfloat_precision(dig)  # deprecated
        setprecision( BigFloat, dig) # new form 
        res = BigFloat(x)
#        set_bigfloat_precision(pr)        
        setprecision(BigFloat, pr)
        return res
    else
        return float(x)
    end
end

# These rely on fixed-point evaluation to continue with N, this is not efficient
# We need to do it all here.
function do_N(m::Mxpr)
    len = length(m)
    args = margs(m)
    nargs = newargs(len)
    for i in 1:len
        nargs[i] = do_N(args[i])
    end
    return mxpr(mhead(m),nargs)
end

function do_N(m::Mxpr,p::Integer)
    len = length(m)
    args = margs(m)
    nargs = newargs(len)
    for i in 1:len
        nargs[i] = do_N(args[i],p)
    end
    return mxpr(mhead(m),nargs)
end

# We need to use dispatch as well, not conditionals
function do_N(s::Symbol)
    if s == :Pi || s == :π
        return float(pi)
    elseif s == :E
        return float(e)
    elseif s == :EulerGamma
        return float(eulergamma)
    end
    return s
end

function do_N(s::SJSym,pr::Integer)
    if s == :Pi || s == :π
        return float_with_precision(pi,pr)
    elseif s == :E
        return float_with_precision(e,pr)
    elseif s == :EulerGamma
        return float_with_precision(eulergamma,pr)
    end
    return s
end

@sjdoc Precision "
Precision(x) gets the precision of a floating point number x, as defined by the
effective number of bits in the mantissa.
"
apprules(mx::Mxpr{:Precision}) = do_Precision(mx,margs(mx)...)
do_Precision(mx::Mxpr{:Precision},args...) = mx
do_Precision(mx::Mxpr{:Precision},x::AbstractFloat) = precision(x)

@sjdoc Re "
Re(x) returns the real part of z.
"

@sjdoc Im "
Im(x) returns the imaginary part of z.
"

# Mma allows complex numbers of mixed Real type. Julia does not.
# Implementation not complete. eg  Im(a + I *b) --> Im(a) + Re(b)
mkapprule("Re")
do_Re{T<:Real}(mx::Mxpr{:Re}, x::Complex{T}) = real(x)
do_Re(mx::Mxpr{:Re}, x::Real) = x

function do_Re(mx::Mxpr{:Re}, m::Mxpr{:Times})
    f = m[1]
    return is_imaginary_integer(f) ? do_Re_imag_int(m,f) : mx
end

# dispatch on type of f. Maybe this is worth something.
function do_Re_imag_int(m,f)
    nargs = copy(margs(m))
    shift!(nargs)
    if length(nargs) == 1
        return mxpr(:Times,-imag(f),mxpr(:Im,nargs))
    else
        return mxpr(:Times,-imag(f),mxpr(:Im,mxpr(:Times,nargs)))
    end
end

mkapprule("Im")
do_Im{T<:Real}(mx::Mxpr{:Im}, x::Complex{T}) = imag(x)
do_Im(mx::Mxpr{:Im}, x::Real) = zero(x)

function do_Im(mx::Mxpr{:Im}, m::Mxpr{:Times})
    f = m[1]
    return is_imaginary_integer(f) ? do_Im_imag_int(m,f) : mx
end

function do_Im_imag_int(m,f)
    nargs = copy(margs(m))
    shift!(nargs)
    if length(nargs) == 1
        return mxpr(:Times,imag(f),mxpr(:Re,nargs))
    else
        return mxpr(:Times,imag(f),mxpr(:Re,mxpr(:Times,nargs)))
    end
end

#### Complex

@sjdoc Complex "
Complex(a,b) returns a complex number when a and b are Reals. This is done when the
expression is parsed, so it is much faster than 'a + I*b'.
"

# Complex with two numerical arguments is converted at parse time. But, the
# arguments may evaluate to numbers only at run time, so this is needed.
# mkapprule requires that the first parameter do_Complex be annotated with the Mxpr type.
mkapprule("Complex")
do_Complex(mx::Mxpr{:Complex},a::Number,b::Number) = complex(a,b)

@sjdoc Rational "
Rational(a,b), or a//b, returns a Rational for Integers a and b.  This is done when the
expression is parsed, so it is much faster than 'a/b'.
"

# Same here. But we need to use mdiv to reduce rationals to ints if possible.
mkapprule("Rational")
do_Rational(mx::Mxpr{:Rational},a::Number,b::Number) = mdiv(a,b)

#### Rationalize

@sjdoc Rationalize "
Rationalize(x) returns a Rational approximation of x.
Rationalize(x,tol) returns an approximation differing from x by no more than tol.
"

mkapprule("Rationalize")
do_Rationalize(mx::Mxpr{:Rationalize},x::AbstractFloat) = rationalize(x)
do_Rationalize(mx::Mxpr{:Rationalize},x::AbstractFloat,tol::Number) = rationalize(x,tol=float(tol))
function do_Rationalize(mx::Mxpr{:Rationalize},x::Symbolic)
    r = doeval(mxpr(:N,x))  # we need to redesign do_N so that we can call it directly. See above
    return is_type_less(r,AbstractFloat) ? do_Rationalize(mx,r) : x
end
function do_Rationalize(mx::Mxpr{:Rationalize},x::Symbolic,tol::Number)
    ndig = round(Int,-log10(tol))      # This is not quite correct.
    r = doeval(mxpr(:N,x,ndig))  # we need to redesign do_N so that we can call it directly. See above.
    return is_type_less(r,AbstractFloat) ? do_Rationalize(mx,r,tol) : x
end
do_Rationalize(mx::Mxpr{:Rationalize},x) = x

#### Numerator

@sjdoc Numerator "
Numerator(expr) returns the numerator of expr.
"

apprules(mx::Mxpr{:Numerator}) = do_Numerator(mx::Mxpr{:Numerator},margs(mx)...)
do_Numerator(mx::Mxpr{:Numerator},args...) = mx

do_Numerator(mx::Mxpr{:Numerator},x::Rational) = num(x)
do_Numerator(mx::Mxpr{:Numerator},x) = x
function do_Numerator(mx::Mxpr{:Numerator},x::Mxpr{:Power})
    find_numerator(x)
end

function do_Numerator(mx::Mxpr{:Numerator},m::Mxpr{:Times})
    nargsn = newargs()
    args = margs(m)
    for i in 1:length(args)
        arg = args[i]
        res = find_numerator(arg)
        if res != 1
            push!(nargsn,res)
        end
    end
    if isempty(nargsn)
        return 1  # which one ?
    end
    if length(nargsn) == 1
        return nargsn[1]
    end
    return mxpr(mhead(m),nargsn)
end

find_numerator(x::Rational) = num(x)
find_numerator(x::Mxpr{:Power}) = pow_sign(x,expt(x)) > 0 ? x : 1

function pow_sign(x, texpt::Mxpr{:Times})
    fac = texpt[1]
    return is_Number(fac) && fac < 0 ? -1 : 1
end

pow_sign(x, texpt::Number) = texpt < 0 ? -1 : 1
pow_sign(x, texpt) = 1
find_numerator(x) = x

## Exp

# The parser normally takes care of this,
# But, when converting expressions from Sympy, we get Exp, so we handle it here.

function apprules(mx::Mxpr{:Exp})
    mxpr(:Power,:E,mx[1])
end

@sjdoc I "
I is the imaginary unit
"

@sjdoc E "
E is the base of the natural logarithm
"

@sjdoc Pi "
Pi is the trigonometric constant π.
"

nothing
