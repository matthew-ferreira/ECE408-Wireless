function output = sym_map(input, rate_id)
    switch(rate_id)
        case 0
            M = 2;
            k = 1;
        case {1,2}
            M = 4;
            k = 2;
        case {3,4}
            M = 16;
            k = 4;
        case {5,6}
            M = 64;
            k = 6;
    end
    
    syms = reshape(input, k, []);
    syms = bi2de(syms', 'left-msb');
    
    switch(rate_id)
        case {0,1,2}
            output = pskmod(syms,M,0,'gray');
        case {3,4,5,6}
            output = qammod(syms,M); %gray by default
    end
end