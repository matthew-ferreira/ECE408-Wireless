function output = deinterleaver(input,N,rate_id)
    switch(rate_id)
        case 0
            Ncpc = 1;
        case {1,2}
            Ncpc = 2;
        case {3,4}
            Ncpc = 4;
        case {5,6}
            Ncpc = 6;
    end
    j = 0:1:N-1;
    s = ceil(Ncpc/2);
    m = s*floor(j/s)+mod((j+floor(12*j/N)),s);
    k = 12*m-(N-1)*floor(12*m/N);
    output(k+1) = input;
end