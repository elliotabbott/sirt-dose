%Export all workspace variables to CSV

pathname = uigetdir(matlabroot,'Choose directory to save CSV files');
files = who;
w = waitbar(0);

for i = 1:length(files)
    waitbar(i/length(files),w,['Saving "' files{i} '" to file.']);
    if istable(eval(files{i}))
        save_table2csv(eval(files{i}), pathname, files{i} )
    end
end

close(w);

dos(['explorer ' pathname]);

clear pathname files w i