function [ gcd ] = euclid_algorithm_list( vec ) 
% EUCLID_ALGORITHM_LIST  Find the greatest common divisor (GCD) in a vector
%     euclid_algorithm_list( vec )

%%%%%%CHANGE THIS VALUE BASED ON SCANNER USED
%%%%%%(theoretically this value could be very small)
minimum_gcd = 4.1;
%%%%%
%%%%%

vec = unique(abs(vec));

if isempty( vec )
    error('GCD is undefined for empty list.');
elseif length ( vec ) == 1
    gcd = vec;
else
    gcd = euclid_algorithm ( vec(1), vec(2), minimum_gcd);
    for i = 3: length(vec)
        gcd = euclid_algorithm ( gcd, vec(i), minimum_gcd);
    end
end
end

function [ gcd ] = euclid_algorithm( a, b, minimum_gcd )

r = b;
old_r = a;

while abs(r) > minimum_gcd
    quotient = floor(old_r / r);
    prov = r;
    r = old_r - quotient * prov;
    old_r = prov;
end

gcd = old_r;

if abs(gcd) < 0.02
    warning('Algorithm may return wrong GCD.');
end
end