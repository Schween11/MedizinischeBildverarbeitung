tic
%% caseData laden und Kantendetektion ausführen
case_id = 91;

data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);
target = result.BW_best_l;
reference_oval = result.oval_edge;
reference_kidney = result.kidney_edge;
reference_kidney_mod = result.kidney_mod_edge;
reference_circle = result.circle_edge;

%% GHT (find_object) für alle Formen ausführen
[target_marked_k, reference_marked_k, YBest_k, XBest_k, ~, scale_k, score_k] = find_object(target, reference_kidney);
[target_marked_km, reference_marked_km, YBest_km, XBest_km, ~, scale_km, score_km] = find_object(target, reference_kidney_mod);
[target_marked_o, reference_marked_o, YBest_o, XBest_o, ~, scale_o, score_o] = find_object(target, reference_oval);
[target_marked_cd, reference_marked_c, YBest_c ,XBest_c, ~, scale_c, score_c] = find_object(target, reference_circle);


%% manuelle Paramterauswahl, je nach Case
if ismember(case_id, [116, 146])
    Xbest = XBest_k; Ybest = YBest_k;
else  
    % Bester Score bestimmen
    [scores, labels] = maxk([score_k, score_km, score_o, score_c], 1);
    best_label = labels(1);
    
    % XBest/YBest passend auswählen
    switch best_label
        case 1  % Kidney
            Xbest = XBest_k; Ybest = YBest_k; 
        case 2  % Kidney Mod
            Xbest = XBest_km; Ybest = YBest_km; 
        case 3  % Oval
            Xbest = XBest_o; Ybest = YBest_o; 
        case 4 %Circle
            Xbest = XBest_c; Ybest = YBest_c; 
    end
end

    
    
scale_best = 1.15;
opts.k_kidney = 2;
opts.chanvese_iters_kidney = 500;
opts.plotAll = true;
opts.case_id = case_id;

%im_norm = data.slice_tum_r; % Auswahl Tumorschicht oder Nierenschicht, rechts/links
im_norm = data.slice_kid_l;
%im_norm = data.slice_kid_r;
%im_norm = data.slice_kid_l;

[mask_kidney] = segment_kidney(im_norm, Ybest, Xbest, reference_oval, scale_best, opts);

toc