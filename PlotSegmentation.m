% === Daten aus Excel einlesen und aus caseData laden ===
case_id = 71;

data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);
target_canny_diff = result.BW_best;
reference_oval = result.oval_edge;
reference_kidney = result.kidney_edge;
reference_kidney_mod = result.kidney_mod_edge;


% Form 2 Kidney
[target_marked_k, reference_marked_k, YBest_k, XBest_k, ~, scale_k, score_k] = find_object(target_canny_diff, reference_kidney);
[target_marked_km, reference_marked_km, YBest_km, XBest_km, ~, scale_km, score_km] = find_object(target_canny_diff, reference_kidney_mod);
[target_marked_o, reference_marked_o, YBest_o, XBest_o, ~, scale_o, score_o] = find_object(target_canny_diff, reference_oval);

% Bester Score bestimmen
[scores, labels] = maxk([score_k, score_km, score_o], 1);
best_label = labels(1);
% XBest/YBest passend auswählen
switch best_label
    case 1  % Kidney
        Xbest = XBest_k; Ybest = YBest_k; scale_best = scale_k;
    case 2  % Kidney Mod
        Xbest = XBest_km; Ybest = YBest_km; scale_best = scale_km;
    case 3  % Oval
        Xbest = XBest_o; Ybest = YBest_o; scale_best = scale_o; 
end

im_norm = data.slice_kid_l;

opts.k_kidney = 4;
opts.k_tumor = 5;
opts.chanvese_iters_kidney = 300;
opts.chanvese_iters_tumor = 300;
opts.plot = true;
opts.tumor_size_ratio = 0.5;
doTumor = true;
opts.plotAll = true;
opts.case_id = case_id;

[mask_kidney, mask_tumor] = segment_kidney_and_tumor(im_norm, Ybest, Xbest, reference_oval, scale_best, doTumor, opts);

