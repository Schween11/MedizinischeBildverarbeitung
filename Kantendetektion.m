%% Vorverarbeitungsschritte 
I_orig = slice_cor;

%% Vorverarbeitungsschritte 

% Schritt 1: Glättung (linear, Gaußfilter)
G = [1 2 1; 
     2 4 2; 
     1 2 1];
G = G / sum(G(:));  % Normieren
I_gauss_manual = conv2(double(I_orig), G, 'same');

% Schritt 2: Nichtlineare Glättung (Median)
I_med = medfilt2(slice_cor, [3 3]);

% Schritt 3: Edge-preserving Smoothing (Bilateralfilter)
I_bilat = imbilatfilt(slice_cor);

% Schritt 4: Anisotrope Diffusion
I_diff = imdiffusefilt(slice_cor, 'NumberOfIterations', 15, 'GradientThreshold', 10);

%% Fuzzy-basierte Kantenerkennung

% Gradient berechnen auf geglättetem Bild
[Gmag, ~] = imgradient(I_bilat);  
Gmag = mat2gray(Gmag);  % Normierung auf [0,1] sicherstellen

% Mamdani-FIS aufbauen
fis = mamfis('Name','EdgeFuzzy');

% Input-MFs
fis = addInput(fis, [0 1], 'Name', 'Gradient');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0], 'Name', 'low');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0.3], 'Name', 'medium');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0.7], 'Name', 'high');

% Output-MFs
fis = addOutput(fis, [0 1], 'Name', 'EdgeStrength');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0 0 0.3], 'Name', 'weak');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0.2 0.4 0.8], 'Name', 'medium');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0.7 1 1], 'Name', 'strong');

% Regelbasis
rules = [
    "If Gradient is low Then EdgeStrength is weak"
    "If Gradient is medium Then EdgeStrength is medium"
    "If Gradient is high Then EdgeStrength is strong"
];
fis = addRule(fis, rules);

% Fuzzy-Auswertung pro Pixel
edge_fuzzy = zeros(size(Gmag));
for i = 1:size(Gmag,1)
    for j = 1:size(Gmag,2)
        edge_fuzzy(i,j) = evalfis(fis, Gmag(i,j));
    end
end

% Schritt 5: Klassische Kantendetektion
BW_orig  = edge(slice_cor, 'sobel');
BW_gauss = edge(I_gauss_manual, 'prewitt');
BW_med   = edge(I_med, 'Canny');
BW_bilat = edge(I_bilat, 'sobel');
BW_diff  = edge(I_diff, 'Canny');

% Schritt 6: Fuzzy binarisieren
threshold = graythresh(edge_fuzzy);
disp(['Otsu Threshold für fuzzy: ', num2str(threshold)]);
BW_fuzzy = edge_fuzzy;
% Vergleich anzeigen
figure;
subplot(2,3,1); imshow(BW_orig); title('Original + Sobel');
subplot(2,3,2); imshow(BW_gauss); title('Gauß + Prewitt');
subplot(2,3,3); imshow(BW_med); title('Median + Canny');
subplot(2,3,4); imshow(BW_bilat); title('Bilateral + Sobel');
subplot(2,3,5); imshow(BW_diff); title('Diffusion + Canny'); 
subplot(2,3,6); imshow(BW_fuzzy); title('Bilateral + Fuzzy');
