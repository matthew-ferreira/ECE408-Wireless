%Randomization, see 802.16-2017 section 8.3.3.1
%also performs unrandomization

function output = randomizer(input)
    output = zeros(1,length(input));
    reg = [1 0 0 1 0 1 0 1 0 0 0 0 0 0 0];
    for i = 1:length(input)
        temp = xor(reg(1),reg(2));
        output(i) = xor(input(i), temp);
        reg = [reg(2:15) temp];
    end    
end