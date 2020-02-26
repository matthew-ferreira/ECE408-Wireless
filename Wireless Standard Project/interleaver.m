function output = interleaver(input,N,rate_id)
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
    k = 0:1:N-1;
    M = (N/12)*mod(k,12) + floor(k/12);
    s = ceil(Ncpc/2);
    J = s*floor(M/s) + mod((M + N - floor(12*M/N)),s);
    output(J+1) = input;
end