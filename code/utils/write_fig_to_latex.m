function write_fig_to_latex

folder = '../fig/initial_exploration/corrs_by_freq/';
logfolder = '../../fig/initial_exploration/corrs_by_logfreq/';
tex_filename = 'test.tex';

REPORT_FOLDER = '../doc/reports/';
tex_filename = fullfile(REPORT_FOLDER, tex_filename);
figures = dir(fullfile(folder, '*LW*x*.png'));


strbeg = [  '\\documentclass[12pt]{article}\n', ...
            '\\extrafloats{100}\n',...
            '\\usepackage{a4wide}\n', ...
            '\\usepackage{multicol, multirow}\n', ...
            '\\usepackage[cp1251]{inputenc}\n',...
            '\\usepackage[russian]{babel}\n',...
            '\\usepackage{amsmath, amsfonts, amssymb, amsthm, amscd}\n',...
            '\\usepackage{graphicx, epsfig, subfig, epstopdf}\n',...
            '\\usepackage{longtable}\n', ...
            '\\graphicspath{ {../', folder, '} }\n',...                      
            '\\begin{document}\n\n'];
strend =    '\\end{document}';

fid = fopen(tex_filename,'w+');
fprintf(fid,strbeg);

tex_str = '';
nfig = length(figures);
for i = 1:nfig
%     el = strsplit(figures(i).name, '.'); el = el{end-1}; 
%     el = strsplit(el, '_'); el = el{end};
    tex_str = [tex_str, '\\begin{figure}\n'];
    tex_str = [tex_str, '\\centering\n'];
    fgn = strsplit(figures(i).name, '.png'); fgn = fgn{end-1}; 
    fgnxyz = {fgn, strrep(fgn, 'x', 'y'), strrep(fgn, 'x', 'z')};
    for j = 1:3        
        tex_str = [tex_str, '\\includegraphics[width=0.32\\textwidth]{{',...
            fgnxyz{j},'}.png}\n'];
    end
    tex_str = [tex_str, '\\\\ \n'];
    for j = 1:3        
        tex_str = [tex_str, '\\includegraphics[width=0.32\\textwidth]{{',...
            logfolder, fgnxyz{j},'}.png}\n'];
    end
    %tex_str = [tex_str, '\\caption{Time d ', el,'}\n'];
    tex_str = [tex_str, '\\end{figure}\n'];
    tex_str = [tex_str,'\n\n'];  
end

fprintf(fid, tex_str);
fprintf(fid, strend);
fclose(fid);

end