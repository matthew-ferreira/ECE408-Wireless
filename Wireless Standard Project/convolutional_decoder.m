function output = convolutional_decoder(input,rate_id)
    trellis = poly2trellis(7, [171, 133]);
    switch(rate_id)
        case {1,3} %2/3
            punct = [1 1 0 1];
            output = vitdec(input,trellis,35,'trunc','hard',punct);
        case {5} %3/4
            punct = [1 1 0 1 1 0];
            output = vitdec(input,trellis,35,'trunc','hard',punct);
        case {2,4,6}
            punct = [1 1 0 1 1 0 0 1 1 0];
            output = vitdec(input,trellis,35,'trunc','hard',punct);
        case 0
            output = vitdec(input,trellis,35,'trunc','hard');
    end
end