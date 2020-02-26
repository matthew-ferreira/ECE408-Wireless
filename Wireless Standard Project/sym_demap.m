function output = sym_demap(input,rate_id)
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
    
    switch(rate_id)
        case {0,1,2}
            data = pskdemod(input,M,0,'gray');
        case {3,4,5,6}
            data = qamdemod(input,M); %gray by default
    end
    data = de2bi(data,'left-msb');
    output = reshape(data',1,[]);
end