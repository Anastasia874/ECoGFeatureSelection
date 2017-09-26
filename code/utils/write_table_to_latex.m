function write_table_to_latex(res_struct, selected)


REPORT_FOLDER = '../doc/reports/';
tex_filename = 'test.tex';


strbeg = [  '\\documentclass[12pt]{article}\n', ...
            '\\extrafloats{100}\n',...
            '\\usepackage{a4wide}\n', ...
            '\\usepackage{multicol, multirow}\n', ...
            '\\usepackage[cp1251]{inputenc}\n',...
            '\\usepackage[russian]{babel}\n',...
            '\\usepackage{amsmath, amsfonts, amssymb, amsthm, amscd}\n',...
            '\\usepackage{graphicx, epsfig, subfig, epstopdf}\n',...
            '\\usepackage{longtable}\n', ...                 
            '\\begin{document}\n\n'];
strend =    '\\end{document}';

fid = fopen(fullfile(REPORT_FOLDER, tex_filename),'w+');
fprintf(fid,strbeg);

if ischar(res_struct)
    res_struct = load(res_struct);  
end

tns_err = res_struct.tns_err;
mat_err = res_struct.mat_err;
tns_pls_err = res_struct.tns_pls_err;
mat_pls_err = res_struct.mat_pls_err;

% tnser = cell(8, 1); mplser = cell(8, 1); tnsplser = cell(8, 1); mer = cell(8, 1);
% for i = 1:8; 
%     tnser{i} = tns_err{i, 1}{4}; mplser{i} = mat_pls_err{i, 1}{4}; 
%     mer{i} = tns_err{i, 1}{3}; tnsplser{i} = tns_pls_err{i, 1}{4}; 
% end;
% res = {mer, tnser, mplser, tnsplser};

res = {mat_err, tns_err, mat_pls_err, tns_pls_err};
alg_names = {'QPFS', 'NQPFS', 'PLS', 'NPLS'};
feats_range = res_struct.ncomp_to_try;
experiments = res_struct.experiments;

if nargin < 2
    selected = feats_range;
end
idx_sel = ismember(feats_range, selected);

nfeats = sum(idx_sel);
tabular = strjoin(repmat({'|'}, 1, nfeats + 3), 'c');
feats = arrayfun(@(x) ['$ N = ', num2str(x), '$'], feats_range(idx_sel), 'UniformOutput', 0);
feats = strjoin(feats, ' & ');

tex_str = '';
tex_str = [tex_str, '\\begin{table}\\caption{All monkeys, correlation coefficient.}\n'];
tex_str = [tex_str, '{\\footnotesize \n'];
tex_str = [tex_str, '\\begin{tabular}{', tabular, '}\n'];
tex_str = [tex_str, '\\hline\n'];
% tex_str = [tex_str, 'Monkey, date  & Algorithm & \\multicolumn{', ...
%             num2str(nfeats), '}{c|}{N. features / components} \\\\ \n'];
tex_str = [tex_str, 'Monkey, date  & Algorithm & ', feats, '\\\\ \n'];
all_vals = zeros(numel(res), nfeats); all_std = all_vals;
for i = 1:numel(experiments)    
    tex_str = [tex_str, '\\hline\n'];
    name = parse_exp_names(experiments{i});
    tex_str = [tex_str, '\\multirow{4}{*}{',  name,' }'];
    [meanvals, stdvals, idxbest] = read_all_errors(res, i, 'crr', idx_sel);
    all_vals = all_vals + meanvals; 
    all_std = all_std + stdvals;
    for j = 1:numel(res)
        vals_str(1, 1:nfeats) = arrayfun(@(x) num2str(x, 3), meanvals(j, :), 'UniformOutput', 0);
        vals_str(2, 1:nfeats) = arrayfun(@(x) num2str(x, '%0.3f'), stdvals(j, :), 'UniformOutput', 0);
        for jbest = find(idxbest == j)
            vals_str{1, jbest} =  ['\\mathbf{', vals_str{1, jbest}, '}'];
            vals_str{2, jbest} =  ['\\mathbf{', vals_str{2, jbest}, '}'];
        end        
        vals = arrayfun(@(x) ['$', vals_str{1, x}, ' \\pm ', vals_str{2, x}, '$'],...
                                                1:nfeats, 'UniformOutput', 0);
    
        vals = strjoin(vals, ' & ');
        tex_str = [tex_str, ' & ', alg_names{j}, ' & '];
        tex_str = [tex_str, vals, '\\\\ \n']; 
        if j ~= numel(res)
            tex_str = [tex_str, '\\cline{2-', num2str(nfeats + 2),'} \n'];
        end
    end 
    tex_str = [tex_str, '\\hline\n'];
end

all_vals = all_vals/numel(experiments); 
all_std = all_std/numel(experiments);  
tex_str = [tex_str, '\\hline\n'];    
tex_str = [tex_str, '\\multirow{4}{*}{ Average }'];    
for j = 1:numel(res)
        vals_str(1, 1:nfeats) = arrayfun(@(x) num2str(x, 3), all_vals(j, :), 'UniformOutput', 0);
        vals_str(2, 1:nfeats) = arrayfun(@(x) num2str(x, '%0.3f'), all_std(j, :), 'UniformOutput', 0);       
        vals = arrayfun(@(x) ['$', vals_str{1, x}, ' \\pm ', vals_str{2, x}, '$'],...
                                                1:nfeats, 'UniformOutput', 0);
    
        vals = strjoin(vals, ' & ');
        tex_str = [tex_str, ' & ', alg_names{j}, ' & '];
        tex_str = [tex_str, vals, '\\\\ \n']; 
        if j ~= numel(res)
            tex_str = [tex_str, '\\cline{2-', num2str(nfeats + 2),'} \n'];
        end
    end 
    tex_str = [tex_str, '\\hline\n'];    
tex_str = [tex_str, '\\end{tabular} }\n'];
tex_str = [tex_str, '\\end{table}\n'];
tex_str = [tex_str,'\n\n'];  


fprintf(fid, tex_str);
fprintf(fid, strend);
fclose(fid);

end

function [meanvals, stdvals, idxbest] = read_all_errors(errs, nexp, metric, idxsel)

meanvals = [];
stdvals = [];
for j = 1:numel(errs)
    if isempty(errs{j}{nexp})
        meanvals = [meanvals; NaN(1, length(idxsel))];
        stdvals = [stdvals; NaN(1, length(idxsel))];
        continue;
    end
    [mse, crr, ~, ~, ~, ~, crr_ho] = read_errors(errs{j}{nexp});
    if strcmp(metric, 'mse')
        vals = mse;
    else
        vals = crr;%crr_ho{1};
    end
    idx = ~isnan(mean(vals));
    vals = vals(:, idx);
    meanvals = [meanvals; nanmean(vals(:, idxsel), 1)];
    stdvals = [stdvals; nanstd(vals(:, idxsel), 1)];   
            
%         vals = repmat({'NaN'}, 1, nfeats);   
end
[~, idxbest] = max(meanvals);
end

function name = parse_exp_names(experiment)

date = experiment(1:8);
idx = strfind(experiment, 'FTT_');
monkey = experiment(idx + 4);

name = [monkey, ', ', date];

end