
T testUserSyms

#### ArcSin

# FIXME N(ArcSin(3)) domain error. julia requires explicity comlex input. We need to check for this.

#### BigIntInput

 bigintval = BigIntInput(True)
T   2^1000 != 0
 BigIntInput(False)
T   2^1000 == 0
 BigIntInput(bigintval)
 ClearAll(bigintval)

#### BigFloatInput

 bigfloatval = BigFloatInput(True)
T   2.0^1000 != Infinity
 BigFloatInput(False)
T   2.0^10000 == Infinity
  BigFloatInput(bigfloatval)
 ClearAll(bigfloatval)

## FIXME   1 < Infinity, etc. are not implemented

#### BesselJ

T Rewrite(BesselJ(nu,z), jn) == (2^(1/2))*(Pi^(-1/2))*(z^(1/2))*(SphericalBesselJ((-1/2 + nu),z))

# FIXME: translate jn somehow
ClearAll(jn)

#### CatalanNumber

T  Table(CatalanNumber(i), [i,10]) == [1,2,5,14,42,132,429,1430,4862,16796]
T  D(CatalanNumber(n),n) == CatalanNumber(n)*(Log(4) + -(PolyGamma(0,2 + n)) + PolyGamma(0,1/2 + n))
T  Rewrite(CatalanNumber(n), HypergeometricPFQ) == HypergeometricPFQ(([1 + -n,-n]),[2],1)
T  Rewrite(CatalanNumber(n), Gamma) == (4^n)*(Pi^(-1/2))*(Gamma(2 + n)^(-1))*Gamma(1/2 + n)
T  Rewrite(CatalanNumber(1/2), Gamma) == (8/3)*(Pi^(-1))
T  Rewrite(CatalanNumber(n), Binomial) == (Binomial((2n),n))*((1 + n)^(-1))
T  CombSimp(CatalanNumber(n+1)/CatalanNumber(n)) == (4^(-n))*(4^(1 + n))*(Gamma(1/2 + n)^(-1))*Gamma(3/2 + n)*((2 + n)^(-1))
# T  Rewrite(CombSimp(CatalanNumber(n+1)/CatalanNumber(n)), Binomial)  FIXME.
# FIXME. A number is converted to a float
#T  Rewrite(CatalanNumber(I), Gamma) == (0.183457 + 0.983028I)*(Pi^(-1/2))*(Gamma(2 + I)^(-1))*Gamma(1/2 + I)


#### Erf

T Erf(0) == 0
T Head(Erf(0)) == Int
T Erf(DirectedInfinity(I)) == DirectedInfinity(I)
T Erf(I*Infinity) == DirectedInfinity(I)
T Erf(-Infinity) == -1
T Erf(-z) == -Erf(z)
T Conjugate(Erf(-z)) == -Erf(Conjugate(z))
T Args(Conjugate(Erf(-z))) == [-1,Erf(Conjugate(z))]

#### Gamma

T Chop(Gamma(.5) - 1.772453850905516) == 0
T Gamma(1/2) == Pi^(1/2)
T Gamma(3/2) == 1/2 * (Pi ^ (1/2))
T Gamma(0) == ComplexInfinity
T Gamma(1) == 1
T Gamma(4) == 6
T Chop(Gamma(1,.5) - 0.6065306597126334) == 0
#T isapprox(Gamma(.5), 1.772453850905516)  don't know if this is worth the trouble
T Gamma(1,2) == E^(-2)
T Gamma(a,0) == Gamma(a)
T Gamma(a, Infinity) == 0
T D(Gamma(x),x) == Gamma(x) * (PolyGamma(0,x))
T Gamma(3,x) == 2 * (E ^ (-x)) + 2 * (E ^ (-x)) * x + E ^ (-x) * (x ^ 2)
# The first term in the || is for sympy < 1.0 (0.7 something). The second is for sympy 1.0
T ( Gamma(-1/2,x) == 2 * (E ^ (-x)) * (x ^ (-1/2)) + -2 * (Pi ^ (1/2)) * (1 + -Erf(x ^ (1/2))) ) ||
         ( Gamma(-1/2,x) ==  2(E^(-x))*(x^(-1/2)) + -2(Pi^(1/2))*Erfc(x^(1/2)))
T Gamma(-2,x) == x ^ (-2) * (ExpIntegralE(3,x))
# T
# T
# T
# T 

# FIXME.
# Cutting and pasting the output of the Series
# is not equal to the output. The ordering of terms is different.
# No idea why.
T Series(Gamma(x), [x, 0, 3])[1] == -EulerGamma

T Conjugate(Gamma(x)) == Gamma(Conjugate(x))

#### HermiteH

T   HermiteH(0,x) == 1
T   HermiteH(1,x) == 2 * x
T   HermiteH(2,x) == -2 + 4*(x^2)
T   D(HermiteH(n,x), x) == 2*n*(HermiteH((-1 + n),x))
T   HermiteH(n,-x) == (-1)^n*(HermiteH(n,x))

 ClearAll(a,x,z)
T testUserSyms

# FIXME. this returns false. should return true
# c= Exp( Sin(Sqrt(2)) + BesselJ(3,4))
#  NumericQ(c)