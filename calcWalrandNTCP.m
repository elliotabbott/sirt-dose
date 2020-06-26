function [ ntcp ] = calcWalrandNTCP(D, Vf, msA )
%CALCWALRANTNTCP calculates the NTCP value based on Stephen Walrand's
%functional subunit model of the liver (based on his parameter estimates)

TD50 = (25.2 + 22.1 * (1 - exp(- 2.74 .* msA))) / (Vf - 0.4).^0.584;
gamma = -13.7.*Vf.^2 + 30.6.*Vf - 8.41;
ntcp = 1 / (1+(TD50/D).^gamma);
end