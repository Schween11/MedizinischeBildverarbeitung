function [mask_kidney_3D, Xbest, Ybest, score_best] = PlotSegmentation3D(case_id, side, doPlot)

%{

 Führt 3D-Nierensegmentierung durch auf Basis GHT + Chan-Vese + Iteration
 durch die Schichten

 INPUT:
   - case_id : Fall-ID
   - side    : 'l' oder 'r' (linke oder rechte Niere)
   - doPlot  : true/false - gibt an, ob eine Visualisierung erfolgen soll

 OUTPUT:
   - mask_kidney_3D : 3D-Nierenmaske
   - Xbest, Ybest   : GHT-Zentrum
   - score_best     : Score der besten Detektion
%}
    tic;

    % Daten laden 
    data = loadCaseData_i(case_id);
    result = EdgeDetection(case_id);

    % Seite auswählen
    switch side
        case 'l'
            target = result.BW_best_l;
            vol_kidney = permute(data.im_vol_l, [1 3 2]);  % [H,W,Z]
            slice_number = data.x_slice_kidney;
        case 'r'
            target = result.BW_best_r;
            vol_kidney = permute(data.im_vol_r, [1 3 2]);  % [H,W,Z]
            slice_number = data.x_slice_kidney;
        otherwise
            error("Ungültiger Seitenparameter: 'l' oder 'r' erwartet");
    end

    % Referenzformen
    reference_oval = result.oval_edge;
    reference_kidney = result.kidney_edge;
    reference_kidney_mod = result.kidney_mod_edge;
    reference_circle = result.circle_edge;

    % GHT mit mehreren Referenzformen
    [~, ~, YBest_k, XBest_k, ~, scale_k, score_k] = find_object(target, reference_kidney);
    [~, ~, YBest_km, XBest_km, ~, scale_km, score_km] = find_object(target, reference_kidney_mod);
    [~, ~, YBest_o, XBest_o, ~, scale_o, score_o] = find_object(target, reference_oval);
    [~, ~, YBest_c, XBest_c, ~, scale_c, score_c] = find_object(target, reference_circle);

    % Beste Detektion bestimmen
    
    [scores, labels] = maxk([score_k, score_km, score_o, score_c], 1);
    best_label = labels(1);
    score_best = scores(1);

    switch best_label
        case 1
            Xbest = XBest_k; Ybest = YBest_k; scale_best = scale_k;
        case 2
            Xbest = XBest_km; Ybest = YBest_km; scale_best = scale_km;
        case 3
            Xbest = XBest_o; Ybest = YBest_o; scale_best = scale_o;
        case 4
            Xbest = XBest_c; Ybest = YBest_c; scale_best = scale_c;
    end
   

% Startslice extrahieren
im_best = vol_kidney(:, :, slice_number);

% Optionen setzen 
opts.k_kidney = 2;
opts.chanvese_iters_kidney = 500;
opts.plotAll = doPlot;
opts.case_id = case_id;

% 2D-Startsegmentierung (nur zur BoundingBox-Prüfung)
start_mask = segment_kidney(im_best, Ybest, Xbest, reference_oval, scale_best, opts);

%BoundingBox prüfen
stats = regionprops(start_mask, 'BoundingBox');
if isempty(stats)
    error('Keine Segmentierung gefunden – leere Maske.');
end

bbox = stats(1).BoundingBox;
bbox_width = bbox(3);
bbox_height = bbox(4);
bbox_area = bbox_width * bbox_height;
max_area = 120*120;
min_area = 40*40;

if bbox_area > max_area
    error('Startmaske zu groß – Segmentierung abgebrochen.');
elseif bbox_area < min_area
    error('Startmaske zu klein – Segmentierung abgebrochen.');
end

% 3D Segmentierung ausführen 
mask_kidney_3D = segment_kidney_3D(vol_kidney, im_best, slice_number, Ybest, Xbest, reference_oval, scale_best, opts);
toc
end