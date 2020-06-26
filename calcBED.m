function [ BED ] = calcBED( D, alpha_over_beta, Trep, Tphys )
%CALCBED Calculates BED based on dose D
%
%   calcBED(D, alpha_over_beta, Trep, Tphys) accepts physical decay and
%       cellular repair parameters and evalues k where k = Trep/(Trep+Tphys)

k = Trep / (Trep + Tphys);
BED = D + (k / alpha_over_beta) * D.^2;

end