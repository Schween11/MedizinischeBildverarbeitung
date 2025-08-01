% === Daten aus Excel einlesen und aus caseData laden ===
patients = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
valid_rows = strcmp(patients{:,8}, 'Y');
case_ids = patients{valid_rows, 1};
num_cases = numel(case_ids);

% === Hauptschleife über alle Cases ===
for idx = 1:num_cases
    case_id = case_ids(idx);
    data = loadCaseData_i(case_id);
    result = EdgeDetection(case_id);
    target_canny_diff = result.BW_best_l; %links oder rechts auswählen
    reference_oval = result.oval_edge;
    reference_kidney = result.kidney_edge;
    reference_kidney_mod = result.kidney_mod_edge;
    reference_circle = result.circle_edge;

    [target_marked_k, reference_marked_k, YBest_k, XBest_k, ~, scale_k, score_k] = find_object(target_canny_diff, reference_kidney);
    [target_marked_km, reference_marked_km, YBest_km, XBest_km, ~, scale_km, score_km] = find_object(target_canny_diff, reference_kidney_mod);
    [target_marked_o, reference_marked_o, YBest_o, XBest_o, ~, scale_o, score_o] = find_object(target_canny_diff, reference_oval);
    [target_marked_cd, reference_marked_c, YBest_c ,XBest_c, ~, scale_c, score_c] = find_object(target_canny_diff, reference_circle);

    if ismember(case_id, [116, 146])
        Xbest = XBest_k; Ybest = YBest_k; scale_best = scale_k;
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
            case 4 % Circle
                Xbest = XBest_c; Ybest = YBest_c; scale_best = scale_c;
        end
    end

    if ismember(case_id, [3, 63])
        opts.k_kidney = 3;
    elseif ismember(case_id, [71, 103, 155])
        opts.k_kidney = 5;
    elseif ismember(case_id, 183)
        opts.k_kidney = 6;
    end

    scale_best = 1.1;
    opts.k_kidney = 4;
    opts.chanvese_iters_kidney = 300;
    opts.plotAll = false;
    opts.case_id = case_id;

%im_norm = data.slice_tum_r; % Auswahl Tumorschicht oder Nierenschicht, rechts/links
%im_norm = data.slice_tum_l;
%im_norm = data.slice_kid_r;
im_norm = data.slice_kid_l;

    [mask_kidney] = segment_kidney(im_norm, Ybest, Xbest, reference_oval, scale_best, opts);
end
