function [ ntcp ] = calcLymanNTCP( EQD, TD50, m )
%
%                   _            2
%             1    /  t       - s  / 2
% NTCP  =  ------  |        e          ds
%            ____ _/   - oo
%          |/2 pi
%
% LaTeX:  \text{NTCP} = \frac{1}{\sqrt{2 \pi}} \int_{-\infty}^t e^{-s^2/2} ds
%
% where EQD is the dose delivered in the equivalent context
% of the reference TD50 and m is the slope of the sigmoid
% curve at TD50


t =  (EQD - TD50)./(m*TD50);

ntcp = 0.5 .* (1 + erf(t./sqrt(2)));

%syms s;
%ntcp = eval(1/sqrt(2*pi) * int(exp(-s.^2 / 2),-Inf,t));

end