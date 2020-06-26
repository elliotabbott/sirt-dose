function save_table2csv( table, pathname, filename )
%SAVE_TABLE2CSV saves table in the workspace to a csv file

if nargin == 1
    [filename, pathname] = uiputfile('*.csv','Choose location to save table.',inputname(1));
    filepath = [pathname filename];
elseif nargin == 2
    filepath = [pathname '\' inputname(1) '.csv'];
else
    filepath = [pathname '\' filename '.csv'];
end

writetable(table, filepath);

end