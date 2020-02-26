function output = rs_encode(input, rate_id)
if(rate_id == 0)
    output = [input zeros(1,8)];
else
    switch(rate_id)
        case 1
            n = 32; k = 24;
        case 2
            n = 40; k = 36;
        case 3
            n = 64; k = 48;
        case 4
            n = 80; k = 72;
        case 5
            n = 108; k = 96;
        case 6
            n = 120; k = 108;
    end
    
    T = 8; %using GF(2^8)
    input = [input zeros(1,8)];
    if(length(input)<(k*8))
        in = [zeros(1, (8*k)-length(input)), input];
    else
        in = input;
    end
    in = bi2de(reshape(in,8,[]).','left-msb');
    msg = gf(in', T);
    rs_code = rsenc(msg,n,k);
    %out = rs_code((8*k)-length(input)+1:end);
    output = reshape(de2bi(double(rs_code.x)','left-msb').',1,[]);
end