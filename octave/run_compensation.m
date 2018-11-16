% compensation running
bufLen = rows(buffer) + 1;
compenLen = rows(compenReference) + 1;
bufPos = 1;
while bufPos < bufLen
    bufRem = bufLen - bufPos;
    compenRem = compenLen - compenPos;
    step = min(bufRem, compenRem);
    buffer(bufPos:bufPos+step-1, :) += compenReference(compenPos:compenPos+step-1, :);
    bufPos += step;
    compenPos += step;
    if step == compenRem
        compenPos = 1;
    end
endwhile
