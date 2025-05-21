%% Vorverarbeitungsschritte 
I_orig = slice_cor;

%% Vorverarbeitungsschritte 

% Schritt 1: Glättung (linear, Gaußfilter)
I_gauss = imgaussfilt(I_orig, 1, "FilterSize",3);

% Schritt 2: Nichtlineare Glättung (Median)
I_med = medfilt2(slice_cor, [3 3]);

% Schritt 3: Edge-preserving Smoothing (Bilateralfilter)
I_bilat = imbilatfilt(slice_cor, 0.2, 4);

% Schritt 4: Anisotrope Diffusion
I_diff = imdiffusefilt(slice_cor, 'NumberOfIterations', 30, 'GradientThreshold', 10);
I_diff_l = imdiffusefilt(slice_cor_l, 'NumberOfIterations', 30, 'GradientThreshold', 10);
I_diff_r = imdiffusefilt(slice_cor_r, 'NumberOfIterations', 30, 'GradientThreshold', 10);

%% Fuzzy-basierte Kantenerkennung

% Gradient berechnen auf geglättetem Bild

% Gradient berechnen
[Gmag, ~] = imgradient(I_bilat);    
Gmag = mat2gray(Gmag);  % Normierung auf [0,1] sicherstellen

% Mamdani-FIS aufbauen
fis = sugfis('Name','EdgeFuzzy');

% Input-MFs
fis = addInput(fis, [0 1], 'Name', 'Gradient');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0], 'Name', 'low');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0.3], 'Name', 'medium');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0.7], 'Name', 'high');

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
input_vec = Gmag(:);                      % 2D → 1D Vektor
output_vec = evalfis(fis, input_vec);     % fuzzy-Auswertung
edge_fuzzy = reshape(output_vec, size(Gmag));  % zurück in Bildform


% Schritt 5: Klassische Kantendetektion
BW_orig  = edge(slice_cor, 'Canny');
BW_gauss = edge(I_gauss, 'Canny');
BW_med   = edge(I_med, 'Canny');
BW_bilat = edge(I_bilat, 'Canny');
BW_diff  = edge(I_diff, 'Canny');

BW_diff_l  = edge(I_diff_l, 'Canny');
BW_diff_r  = edge(I_diff_r, 'Canny');


% Schritt 6: Fuzzy binarisieren
threshold = graythresh(edge_fuzzy);
BW_fuzzy = imbinarize(edge_fuzzy, threshold);
% Vergleich anzeigen
figure;
subplot(1,3,1); imshow(BW_diff_l); title('links: Diffusion + Canny');
subplot(1,3,2); imshow(BW_diff_r); title('rechts: Diffusion + Canny'); 
subplot(1,3,3); imshow(BW_fuzzy); title('Bilateral + Fuzzy');

target = BW_diff_r;
shapes_path = 'shapes';
kidney_path = fullfile(shapes_path,'KidneyCoronal.png');
reference = imread(kidney_path);       % z. B. uint8 RGB
reference = rgb2gray(reference);   % Konvertiere zu Graustufen
reference = imbinarize(reference);     % Jetzt 2D logical

imshow(reference)