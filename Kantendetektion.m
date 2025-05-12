%% Fuzzy-basierte Kantenerkennung (über Gradientenmagnitude)

% Gradient berechnen (auf geglättetem Bild, z.B. Median)
[Gmag, ~] = imgradient(I_bilat);

% Erzeuge Mamdani-FIS
fis = mamfis('Name','EdgeFuzzy');
fis = addInput(fis, [0 1], 'Name', 'Gradient');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.05 0], 'Name', 'low');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.05 0.3], 'Name', 'medium');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.05 0.7], 'Name', 'high');

fis = addOutput(fis, [0 1], 'Name', 'EdgeStrength');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0 0 0.3], 'Name', 'weak');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0.2 0.4 0.8], 'Name', 'medium');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0.7 1 1], 'Name', 'strong');

rules = [
    "If Gradient is low Then EdgeStrength is weak"
    "If Gradient is medium Then EdgeStrength is medium"
    "If Gradient is high Then EdgeStrength is strong"
];
fis = addRule(fis, rules);

% Fuzzy-Auswertung für jedes Pixel
edge_fuzzy = zeros(size(Gmag));
for i = 1:size(Gmag,1)
    for j = 1:size(Gmag,2)
        edge_fuzzy(i,j) = evalfis(fis, Gmag(i,j));
    end
end

%% Vergleich der Vorverarbeitungsschritte  mit Canny

% Schritt 1: Glättung (linear)
G = [1 2 1; 
     2 4 2; 
     1 2 1];
G = G / sum(G(:));  % Normieren auf Summe = 1

% Faltung mit dem Bild
I_gauss_manual = conv2(double(I_orig), G, 'same');

% Schritt 2: Glättung (nichtlinear)
I_med = medfilt2(slice_cor, [3 3]);  % Medianfilter --> besser für Kantenerhalt

% Schritt 3: Edge-preserving Smoothing (bilateral)
I_bilat = imbilatfilt(slice_cor);  % Erhält Kanten besser

% Schritt 4: Anisotrope Diffusion (Perona-Malik)
I_diff = imdiffusefilt(slice_cor, 'NumberOfIterations', 15, 'GradientThreshold', 10);

% Schritt 5: Kantenerkennung danach (z. B. Canny)
BW_orig = edge(slice_cor, 'sobel');
BW_gauss = edge(I_gauss_manual, 'prewitt');
BW_med = edge(I_med, 'Canny');
BW_bilat = edge(I_bilat, 'sobel');
BW_diff = edge(I_diff, 'Canny');
% Binär machen mit adaptivem Schwellwert
BW_fuzzy = imbinarize(edge_fuzzy, graythresh(edge_fuzzy));
threshold = graythresh(edge_fuzzy);  % Berechnet den besten Schwellenwert
disp(threshold);

% Vergleich
figure;
subplot(2,3,1); imshow(BW_orig); title('Original + sobel');
subplot(2,3,2); imshow(BW_gauss); title('Gauß + prewitt');
subplot(2,3,3); imshow(BW_med); title('Median + Canny');
subplot(2,3,4); imshow(BW_bilat); title('Bilateral + sobel');
subplot(2,3,5); imshow(BW_diff); title('Diffusion + Canny'); 
subplot(2,3,6); imshow(BW_fuzzy); title('Bilateral + Fuzzy');