function [ EQD, d ] = calcEQD( BED, alpha_over_beta, d )
EQD = BED ./ (1 + (d / alpha_over_beta) );
end