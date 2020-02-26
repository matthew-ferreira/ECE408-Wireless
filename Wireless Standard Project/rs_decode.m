function output = rs_decode(input, rate_id)
if(rate_id == 0)
    output = input(1:end-8);
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
    
    data = reshape(input,8,[]);
    data = bi2de(data.','left-msb');
    data = gf(data.',T);
    out = rsdec(data,n,k);
    out = out.x';
    out = out(1:end-1);
    out = de2bi(out,'left-msb');
    
    out = reshape(out.',1,[]);
    
    output = out;
end