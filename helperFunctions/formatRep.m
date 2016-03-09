function x = formatRep(n)
%FORMATREP returns the eRLE repetition number n in required format
% According to the DLPC900 programmers guide p.64, the repetition byte n for
% the enhanced run length encoding has to be in the form 
% n < 128  : x = n
% n >= 128 : x = [(n & 0xfF ) | 0x80, (n >> 7)]
% here, &, | and >> are the corresponding operators in C syntax. 
% Be careful, the example featured in the programmers guide seems to be
% wrong!
% For reference and to play around you can use the following C code:
% #include <stdio.h>
% int main()
% {
%     int x = 0;
%     int y = 0;
%     int z = 500;
%     x = ( z & 0x7F ) | 0x80;
%     y = z >> 7;
%     printf("%x, %x \n", x & 0xff, y & 0xff);
%     printf("%d, %d \n", x, y);
%     return 0;
% }
%
% Author: Klaus Hueck (e-mail: khueck (at) physik (dot) uni-hamburg (dot) de)
% Version: 0.0.1alpha
% Changes tracker:  28.01.2016  - First version
% License: GPL v3

if n < 128
    x = dec2hex(n, 2);
else
    x1 = dec2hex(bitor(bitand(n,127), 128), 2);
    x2 = dec2hex(bitshift(n, -7), 2);
    x = [x1, x2];
end

end