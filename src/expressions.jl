## Expand, Apply, Reverse

function _doexpand(x)
    ! is_Mxpr(x) && return x
    n = length(x)
    args = margs(x)
    nargs = newargs(n)
    for i in 1:n
        nargs[i] = doexpand(args[i])
    end
    return doexpand(mxpr(mhead(x),nargs))
end

doexpand(p::Mxpr{:Power}) = do_expand_power(p,base(p),expt(p))

function doexpand(prod::Mxpr{:Times})
    a = margs(prod)
    len = length(a)
    for i in 1:len
        a[i] = doexpand(a[i])
    end
    have_sum = false
    j = 0
    for i in 1:len # check if we have anything to do
        j += 1
        if is_Mxpr(a[i],:Plus)
            have_sum = true
            break
        end
    end
    ! have_sum && return prod
    nonsums = newargs()
    for i in 1:j-1  # none of these are sums
        push!(nonsums,a[i])
    end
    sums = newargs()
    push!(sums,a[j]) # already know its a sum
    for i in j+1:len   # push more sums, if there are any
        if is_Mxpr(a[i],:Plus)
            push!(sums,a[i])
        else
            push!(nonsums,a[i])
        end
    end
    sumres = length(sums) == 1 ? sums[1] : mulfacs(sums...)
    nlen = length(nonsums)
    if nlen == 0
        mxout = sumres
    elseif nlen == 1
        mxout = mulfacs(nonsums[1],sumres)
    else
        mxout = mulfacs(mxpr(:Times,nonsums),sumres)
    end
    setfixed(mxout)
    return mxout
end

doexpand(mx) = mx

do_expand_power(p,b::Mxpr{:Plus}, n::Integer) =
    length(b) != 2 ? p : do_expand_binomial(p,b[1],b[2],n)
do_expand_power(p,b,ex) = p

#do_expand_binomial(mx::Mxpr{:Expand}, a, b, n::Integer) = @time(expand_binomial(a,b,n))
do_expand_binomial(p,a, b, n::Integer) = expand_binomial(a,b,n)
do_expand_binomial(a,b,n) = p

function doexpand(s::Mxpr{:Plus})
    args = margs(s)
    for i in 1:length(args)
        args[i] = doexpand(args[i])
    end
    return s
end

## expand product of two sums
# a an b are the factors
# In test cases, this is fast. later, canonicalizing each term is slowest thing.
function mulfacs(a::Mxpr{:Plus},b::Mxpr{:Plus})
    terms = newargs(length(a)*length(b))
    i = 0
    for ax in a.args
        for bx in b.args
            i += 1
#            println("  1:  $ax,  $bx")
            t = flatcanon!(mxpr(:Times, ax, bx)) # TODO specialize for types of ax, bx
            mergesyms(t,ax)
            mergesyms(t,bx)
            setfixed(t)
            terms[i] = t
        end
    end
    mx = flatcanon!(mxpr(:Plus,terms))
    for t in terms
        mergesyms(mx,t)
    end
    setfixed(mx)
    mx
end

# Not the right way to do this. We need to expand each term, as well.
mulfacs(a,b,c) = mulfacs(mulfacs(a,b),c)
mulfacs(a,b,c,xs...) = mulfacs(mulfacs(mulfacs(a,b),c),xs...)

# Should probably write this
#function mulfacs(a::Mxpr{:Plus}, b::SJSym)
#end

function _pushfacs!(facs,mx::Mxpr{:Times})
    append!(facs,margs(mx))
end

# Make this more efficient. numbers, symbols, etc.
function _pushfacs!(facs,b)
    push!(facs,b)    
end

function mulfacs(a::Mxpr{:Plus},b)
#    println("2:  $a,  $b")    
    terms = newargs(length(a))
    i = 0
    for ax in a.args
        i += 1
        if is_Mxpr(ax) && mxprtype(ax) == :Times
            facs = copy(margs(ax))
            _pushfacs!(facs,b)  # I hope type inference optimizes this.
            terms[i] = mxpr(:Times,facs)
        else
            terms[i] = b * ax
        end
        canonexpr!(terms[i]) 
        mergeargs(terms[i])
#        setfixed(terms[i])
    end
    mx = mxpr(:Plus,terms)
    mergeargs(mx)
    mx
end

function mulfacs(a, b::Mxpr{:Plus})
#   println("3:  $a,  $b")
    mulfacs(b,a)
end

# factors are not sums, but other things!
# This should not be called!
# function mulfacs(a::Number,b::Union(SJSym,Mxpr{:Power}))
#     mx = mxpr(:Times,a,b)
#     setfixed(mx)
#     mergesyms(mx,b)
#     mx
# end

# mulfacs(a::SJSym,b::Number)

## construct Power. Decide whether to canonicalize according to types of args
function canonpower{T<:Real}(base,expt::T)
    canonexpr!(base^expt)
end
function canonpower(base::SJSym,expt)
    base^expt
end
function canonpower(base,expt)
    base^expt
end

## 

# Be careful to construct expression in canonical form.
# Lots of ways to go wrong.
# Assume a < b in canonical order
# This is the only place we are testing meta data in Mxpr giving which
# symbols it depends on.
function expand_binomial(a,b,n::Integer)
    args = newargs(n+1)
    args[1] = canonpower(a,n)
    mergesyms(args[1],a)
    setfixed(args[1])
    args[n+1] =  canonpower(b,n)
    mergesyms(args[n+1],b)
    setfixed(args[n+1])    
    if n == 2
        args[2] = flatcanon!(mxpr(:Times,2,a,b))  # we have to flatcanon
    else
        # TODO optimize for symbols a,b, as in general case below. No flatcanon.
        args[2] = flatcanon!(mxpr(:Times,n,canonpower(a,(n-1)),b)) 
        args[n] = flatcanon!(mxpr(:Times,n,a,canonpower(b,(n-1))))
        mergesyms(args[2],a)
        mergesyms(args[2],b)
        mergesyms(args[n],a)
        mergesyms(args[n],b)
        setfixed(args[2])
        setfixed(args[n])
        fac = n
        k = n
        l = one(n)
        expand_binomial_aux(k,l,n,fac,a,b,args)
    end
    mx = mxprcf(:Plus,args)
    mergesyms(mx,a)
    mergesyms(mx,b)
    setage(mx)
    setfixed(mx)
    mx
end

# Big increase in efficiency (> 10x) for both these types
typealias ExpNoCanon Union(SJSym,Number)

# Expand((a+b*c)^n) is 10x slower than Expand((a+b)^n)
function _expand_mulpowers(fac,b1,e1,b2,e2)
    m1 = canonpower(b1,e1)  # adds 10-15% time  
    m2 = canonpower(b2,e2)
    setfixed(m1)
    setfixed(m2)
    mergesyms(m1,b1)
    mergesyms(m2,b2)            
    return flatcanon!(mxpr(:Times, fac, m1, m2)) # flatcanon adds 10x time !, even if nothing is done
end

function _expand_mulpowers(fac,b1::ExpNoCanon,e1,b2::ExpNoCanon,e2)
    m1 = b1^e1
    m2 = b2^e2
    setfixed(m1)
    setfixed(m2)
    mergesyms(m1,b1)
    mergesyms(m2,b2)            
    return mxpr(:Times, fac, m1, m2)
end

function _expand_mulpowers(fac,b1::ExpNoCanon,e1,b2,e2)
    m1 = b1^e1
#    m2 = b2^e2    
    m2 = canonpower(b2,e2)
    setfixed(m1)
    setfixed(m2)
    mergesyms(m1,b1)
    mergesyms(m2,b2)
    return flatcanon!(mxpr(:Times, fac, m1, m2))    
end

function _expand_mulpowers(fac,b1,e1,b2::ExpNoCanon,e2)
    m1 = canonpower(b1,e1)
#    m1 = b1^e1    
    m2 = b2^e2    
    setfixed(m1)
    setfixed(m2)
    mergesyms(m1,b1)
    mergesyms(m2,b2)
    return flatcanon!(mxpr(:Times, fac, m1, m2))    
end


function expand_binomial_aux(k,l,n,fac,a,b,args)
        @inbounds for j in 2:n-2
            k = k - 1
            l = l + 1
            fac *= k
            fac = div(fac,l)
            args[j+1] = _expand_mulpowers(fac,a,n-j,b,j)
            mergesyms(args[j+1],a)
            mergesyms(args[j+1],b)
            setfixed(args[j+1])
        end
end

@sjdoc Apply "
Apply(f,expr) replaces the Head of expr with f.
"
apprules(mx::Mxpr{:Apply}) = doapply(mx,mx[1],mx[2])

function doapply(mx::Mxpr,h::SJSym,mxa::Mxpr)
    if (h == :Plus || h == :Times ) # 4 or 5 times faster for plus on numbers, don't evaluate
        mx = mxpr(h,copy(margs(mxa)))
        mx = canonexpr!(mx)
        setcanon(mx)
    else
        mx = mxpr(h,margs(mxa))        
    end
    length(mx) == 0 && return 0  # maybe return zero(something) ?
    mx
end


# Apply operation to a typed numeric array.
# We can build these functions with a macro and
# mapping from  :Times -> mmul
# :Cos -> cos, etc.
function doapply{T<:Number}(mx::Mxpr,h::SJSym,arr::Array{T})
    if h == :Plus
        s = zero(T)
        for i in 1:length(arr)
            s += arr[i]
        end
        return s
    end
    return mx
end

doapply(mx,x,y) = mx

function Base.reverse(mx::Mxpr)
    mx1 = copy(mx)
    Base.reverse!(margs(mx1))
    return mx1
end

@sjdoc Reverse "
Reverse(expr) reverses the order of the arguments in expr.    
"
function apprules(mx::Mxpr{:Reverse})
    do_reverse(mx[1])
end

# they would only be resorted
do_reverse(mx::Orderless) = mx

function do_reverse(mx::Mxpr)
    mxpr(mx.head,reverse(margs(mx)))
end

## Permutations

@sjdoc Permutations "
Permutations(expr) give a list of all permuations of elements in expr.
"

function apprules(mx::Mxpr{:Permutations})
    perms = collect(permutations(margs(mx[1])))
    h = mhead(mx[1])
    len = length(perms)
    nargs = newargs(len)
    for i in 1:len
        nargs[i] = setfixed(mxpr(:List,perms[i]))
    end
    setfixed(mxpr(:List,nargs))
end

@sjdoc FactorInteger "
FactorInteger(n) gives a list of prime factors of n and their multiplicities.
"
apprules(mx::Mxpr{:FactorInteger}) = setfixed(mxpr(:List,do_unpack(factor(mx[1]))))
