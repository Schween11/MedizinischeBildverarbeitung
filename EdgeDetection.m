%% Funktionsdefinition mit Case-ID als Input

function result = EdgeDetection(case_id);

% Aufrufen der vorverarbeiteten Daten im Struct
data = loadCaseData_i(case_id); 

% Auswahl der pathologische Seite 
location_str = string(data.tbl{data.row,12});
first_word = extractBefore(location_str, ',');

if first_word == "rechts"
    I_orig = data.slice_cor_r;
else 
    I_orig = data.slice_cor_l;
end

%% Vorverarbeitungsschritte 

% Parameter für Canny und Diffusionsfilter
nmb_it = 5; % mehr Iteration --> stärkere Glättung --> weniger Details
grd_thr = 5; % Gradiententhreshold --> Threshold hoch --> weniger Details 
low_thr = 0.1; % zwischen low und high dann Kante, wenn mit anderen Kanten verbunden
high_thr = 0.25; % alles drüber sichere Kante

% Bilateralfilter
I_bilat = imbilatfilt(I_orig, 0.2, 4);

% Anisotroper Diffusionsfilter
I_diff = imdiffusefilt(I_orig, 'NumberOfIterations', nmb_it, 'GradientThreshold', grd_thr);

%% 1) Fuzzy-basierte Kantenerkennung

% Gradient berechnen auf geglättetem Bild

% Gradient manuell berechnen
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

% Ausgabe-MFs
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

% Fuzzy binarisieren
threshold = graythresh(edge_fuzzy_bil); % Threshold zur Binarisierung verwenden
BW_fuzzy_bil = imbinarize(edge_fuzzy_bil, threshold);
threshold_dif = graythresh(edge_fuzzy_dif);
BW_fuzzy_dif = imbinarize(edge_fuzzy_dif, threshold_dif);

% Überflüssige Pixel entfernen
fuzzy_bil_thin = bwmorph(BW_fuzzy_bil, 'thin', Inf);
fuzzy_diff_thin = bwmorph(BW_fuzzy_dif, 'thin', Inf);


%% 2) Canny-Kantendetektion
BW_diff = edge(I_diff, 'Canny',  low_thr, high_thr);
BW_diff = bwmorph(BW_diff,"skel");
BW_diff = bwareaopen(BW_diff, 150);

% Kantendetektion der Shapes (für find_object Funktion)
circle_edge = edge(data.circle, 'Canny');
oval_edge = edge(data.oval, 'Canny');
kidney_edge = edge(data.kidney, 'Canny');
kidney_mod_edge = edge(data.kidney_mod, 'Canny');

% Ausgabe als Struktur speichern
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
