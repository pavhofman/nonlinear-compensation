function waitOrPrint(show='', filePath='plot', plotSuffix='', channel=0)
    if index(show, 'p') > 0
        [dir, name, ext] = fileparts(filePath);

        if (length(dir) != 0)
            printPath = strcat(dir, '/', name);
        else
            printPath = name;
        end
        if (length(plotSuffix) != 0)
            printPath = strcat(printPath, plotSuffix);
        end
        if (channel != 0)
            printPath = strcat(printPath, '-ch', num2str(channel));
        end
        printPath = strcat(printPath, '.pdf');

        print(printPath)
    end

    if index(show, 'w') > 0
        while 1
            waitforbuttonpress();
        endwhile
    end
endfunction
