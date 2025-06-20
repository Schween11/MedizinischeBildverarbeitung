function result = EdgeDetection(case_id);
data = loadCaseData(case_id);

%% Auswahl der pathologische Seite 
location_str = string(data.tbl{data.row,12});
first_word = extractBefore(location_str, ',');

if first_word == "rechts"
    I_orig = data.slice_cor_r;
else 
    I_orig = data.slice_cor_l;
end

%% Vorverarbeitungsschritte 

% Parameter für Canny und Diffusionsfilter
nmb_it = 30;
grd_thr = 10;
low_thr = 0.2;
high_thr = 0.4;


% Schritt 1: Glättung (linear, Gaußfilter)
I_gauss = imgaussfilt(I_orig, 1, "FilterSize",3);

% Schritt 2: Nichtlineare Glättung (Median)
I_med = medfilt2(I_orig, [3 3]);

% Schritt 3: Edge-preserving Smoothing (Bilateralfilter)
I_bilat = imbilatfilt(I_orig, 0.2, 4);

% Schritt 4: Anisotrope Diffusion
I_diff = imdiffusefilt(I_orig, 'NumberOfIterations', nmb_it, 'GradientThreshold', grd_thr);

%% Fuzzy-basierte Kantenerkennung

% Gradient berechnen auf geglättetem Bild

% Gradient berechnen
[Gmag_bil, ~] = imgradient(I_bilat);    
Gmag_bil = mat2gray(Gmag_bil);  % Normierung auf [0,1] sicherstellen

[Gmag_dif, ~] = imgradient(I_diff);    
Gmag_dif = mat2gray(Gmag_dif);  % Normierung auf [0,1] sicherstellen

% Sugeno-FIS aufbauen
fis = sugfis('Name','EdgeFuzzy');

% Input-MFs
fis = addInput(fis, [0 1], 'Name', 'Gradient');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.08 0.0], 'Name', 'low');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.08 0.15], 'Name', 'medium');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.08 0.4], 'Name', 'high');

% Ausgabe: Konstante (für Sugeno nötig)
fis = addOutput(fis, [0 1], 'Name', 'EdgeStrength');
fis = addMF(fis, 'EdgeStrength', 'constant', 0.1, 'Name', 'weak');
fis = addMF(fis, 'EdgeStrength', 'constant', 0.5, 'Name', 'medium');
fis = addMF(fis, 'EdgeStrength', 'constant', 0.9, 'Name', 'strong');

% Regelbasis
rules = [
    "If Gradient is low Then EdgeStrength is weak"
    "If Gradient is medium Then EdgeStrength is medium"
    "If Gradient is high Then EdgeStrength is strong"
];
fis = addRule(fis, rules);

% Fuzzy-Auswertung vektorisieren
input_vec = Gmag_bil(:);                      % 2D → 1D Vektor
output_vec = evalfis(fis, input_vec);     % fuzzy-Auswertung
edge_fuzzy_bil = reshape(output_vec, size(Gmag_bil)); % zurück in Bildform

input_vec_dif = Gmag_dif(:);                      % 2D → 1D Vektor
output_vec_dif = evalfis(fis, input_vec_dif);     % fuzzy-Auswertung
edge_fuzzy_dif = reshape(output_vec_dif, size(Gmag_dif));

% Schritt 5: Klassische Kantendetektion
BW_orig  = edge(I_orig, 'Canny');
BW_gauss = edge(I_gauss, 'Canny');
BW_med   = edge(I_med, 'Canny');
BW_bilat = edge(I_bilat, 'Canny');
circle_edge = edge(data.circle, 'Canny');
oval_edge = edge(data.oval, 'Canny');
kidney_edge = edge(data.kidney, 'Canny');
kidney_mod_edge = edge(data.kidney_mod, 'Canny');

% Schritt 6: Fuzzy binarisieren
threshold = graythresh(edge_fuzzy_bil); %T hreshold zur Binarisierung verwenden
BW_fuzzy_bil = imbinarize(edge_fuzzy_bil, threshold);
threshold_dif = graythresh(edge_fuzzy_dif);
BW_fuzzy_dif = imbinarize(edge_fuzzy_dif, threshold_dif);

% Schritt 7: Überflüssige Pixel entfernen
fuzzy_bil_thin = bwmorph(BW_fuzzy_bil, 'thin', Inf);
fuzzy_diff_thin = bwmorph(BW_fuzzy_dif, 'thin', Inf);

% Canny Thresholds angepasst an Matrix Werte
low = mean(I_diff(:)) * 0.5;
high = mean(I_diff(:)) * 1.5;
BW_diff = edge(I_diff, 'Canny',  low_thr, high_thr);
BW_diff = bwareaopen(BW_diff, 100);

% Ausgabe als Struktur
result = struct();
result.BW_bilat = BW_bilat;
result.BW_diff = BW_diff;
result.fuzzy_bil_thin = fuzzy_bil_thin;
result.fuzzy_diff_thin = fuzzy_diff_thin;
result.I_orig = I_orig;
result.case_id = case_id;
result.kidney_edge = kidney_edge;
result.kidney_mod_edge = kidney_mod_edge;
result.circle_edge = circle_edge;
result.oval_edge = oval_edge;
end
