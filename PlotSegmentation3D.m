tic
% === Daten aus Excel einlesen und aus caseData laden ===
case_id = 33;

data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);
target_canny_diff = result.BW_best;
reference_oval = result.oval_edge;
reference_kidney = result.kidney_edge;
reference_kidney_mod = result.kidney_mod_edge;
reference_circle = result.circle_edge;

% Form 2 Kidney
[target_marked_k, reference_marked_k, YBest_k, XBest_k, ~, scale_k, score_k] = find_object(target_canny_diff, reference_kidney);
[target_marked_km, reference_marked_km, YBest_km, XBest_km, ~, scale_km, score_km] = find_object(target_canny_diff, reference_kidney_mod);
[target_marked_o, reference_marked_o, YBest_o, XBest_o, ~, scale_o, score_o] = find_object(target_canny_diff, reference_oval);
[target_marked_cd, reference_marked_c, YBest_c ,XBest_c, ~, scale_c, score_c] = find_object(target_canny_diff, reference_circle);

if ismember(case_id, [116, 146])
    Xbest = XBest_k; Ybest = YBest_k; scale_best = 1.2;
else  
    % Bester Score bestimmen
    [scores, labels] = maxk([score_k, score_km, score_o, score_c], 1);
    best_label = labels(1);
    
    % XBest/YBest passend auswählen
    switch best_label
        case 1  % Kidney
            Xbest = XBest_k; Ybest = YBest_k; scale_best = scale_k;
        case 2  % Kidney Mod
            Xbest = XBest_km; Ybest = YBest_km; scale_best = scale_km;
        case 3  % Oval
            Xbest = XBest_o; Ybest = YBest_o; scale_best = scale_o; 
        case 4 %Circle
            Xbest = XBest_c; Ybest = YBest_c; scale_best = scale_c;
    end
end

im_norm = result.I_tum;
imBest = data.im_fov_r(:, 280, :);
im_best = squeeze(imBest);    
    
scale_best = 1;
opts.k_kidney = 2;
opts.chanvese_iters_kidney = 500;
opts.plotAll = true;
opts.case_id = case_id;
slice_kidney = data.im_fov_r;
slice_number = 280;

mask_kidney_3D = segment_kidney_3D(slice_kidney, im_best, slice_number, Ybest, Xbest, reference_oval, scale_best, opts);

toc