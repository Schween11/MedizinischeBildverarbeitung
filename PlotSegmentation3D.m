tic

% === Daten aus Excel einlesen und aus caseData laden ===
case_id = 33;
data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);

target_canny_diff = result.BW_best_r;
reference_oval = result.oval_edge;
reference_kidney = result.kidney_edge;
reference_kidney_mod = result.kidney_mod_edge;
reference_circle = result.circle_edge;

% Form 2 Kidney
[target_marked_k, reference_marked_k, YBest_k, XBest_k, ~, scale_k, score_k] = find_object(target_canny_diff, reference_kidney);
[target_marked_km, reference_marked_km, YBest_km, XBest_km, ~, scale_km, score_km] = find_object(target_canny_diff, reference_kidney_mod);
[target_marked_o, reference_marked_o, YBest_o, XBest_o, ~, scale_o, score_o] = find_object(target_canny_diff, reference_oval);
[target_marked_cd, reference_marked_c, YBest_c ,XBest_c, ~, scale_c, score_c] = find_object(target_canny_diff, reference_circle);

% Bester Score bestimmen
if ismember(case_id, [116, 146])
    Xbest = XBest_k;
    Ybest = YBest_k;
    scale_best = 1.2;
else  
    [scores, labels] = maxk([score_k, score_km, score_o, score_c], 1);
    best_label = labels(1);

    switch best_label
        case 1  % Kidney
            Xbest = XBest_k; Ybest = YBest_k; scale_best = scale_k;
        case 2  % Kidney Mod
            Xbest = XBest_km; Ybest = YBest_km; scale_best = scale_km;
        case 3  % Oval
            Xbest = XBest_o; Ybest = YBest_o; scale_best = scale_o; 
        case 4  % Circle
            Xbest = XBest_c; Ybest = YBest_c; scale_best = scale_c;
    end
end

% Bildvolumen [H, Z, W] → umwandeln zu [H, W, Z]
vol_kidney = permute(data.im_vol_r, [1 3 2]);  % [H, W, Z]
slice_number = 280;

% Das Startbild direkt aus dem permutierten Volumen entnehmen
im_best = vol_kidney(:, :, slice_number);

% Optionen für Segmentierung
opts.k_kidney = 2;
opts.chanvese_iters_kidney = 500;
opts.plotAll = true;
opts.case_id = case_id;

% Aufruf der 3D-Segmentierung
mask_kidney_3D = segment_kidney_3D(vol_kidney, im_best, slice_number, Ybest, Xbest, reference_oval, scale_best, opts);

toc
