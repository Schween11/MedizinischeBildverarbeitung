function [mask_kidney, Xbest, Ybest, score_best] = PlotSegmentation(case_id, side, doPlot)

%{ 
BESCHREIBUNG: Führt vollständige Nierensegmentierung mit GHT, KMeans und Chan-Vese durch
 INPUT:
   - case_id : Fallnummer als Zahl (z
   - side    : 'l' für linke oder 'r' für rechte Niere
   - doPlot  : true/false – gibt an, ob eine Visualisierung erfolgen soll

 OUTPUT:
   - mask_kidney : finale Segmentierungsmaske der Niere
   - Xbest, Ybest: GHT-Zentrum
  - score_best  : Score des besten Matches
%}
    %% Daten laden und Kantendetektion
    data = loadCaseData_i(case_id);
    result = EdgeDetection(case_id);

    if side == 'l'
        target = result.BW_best_l;
        im_norm = data.slice_kid_l;
    else
        target = result.BW_best_r;
        im_norm = data.slice_kid_r;
    end

    reference_oval = result.oval_edge;
    reference_kidney = result.kidney_edge;
    reference_kidney_mod = result.kidney_mod_edge;
    reference_circle = result.circle_edge;

    %% GHT Matching für alle Formen
    [~, ~, YBest_k, XBest_k, ~, ~, score_k]   = find_object(target, reference_kidney);
    [~, ~, YBest_km, XBest_km, ~, ~, score_km] = find_object(target, reference_kidney_mod);
    [~, ~, YBest_o, XBest_o, ~, ~, score_o]   = find_object(target, reference_oval);
    [~, ~, YBest_c, XBest_c, ~, ~, score_c]   = find_object(target, reference_circle);

    %% Beste Detektion wählen
    if ismember(case_id, [116, 146])
        Xbest = XBest_k; Ybest = YBest_k;
        score_best = score_k;
    else
        [scores, labels] = maxk([score_k, score_km, score_o, score_c], 1);
        best_label = labels(1);
        score_best = scores(1);

        switch best_label
            case 1
                Xbest = XBest_k; Ybest = YBest_k;
            case 2
                Xbest = XBest_km; Ybest = YBest_km;
            case 3
                Xbest = XBest_o; Ybest = YBest_o;
            case 4
                Xbest = XBest_c; Ybest = YBest_c;
        end
    end

    %% Segmentierungsparameter
    scale_best = 1.15;
    opts.k_kidney = 2;
    opts.chanvese_iters_kidney = 500;
    opts.plotAll = doPlot;
    opts.case_id = case_id;

    %% Segmentierung ausführen
    mask_kidney = segment_kidney(im_norm, Ybest, Xbest, reference_oval, scale_best, opts);
end
