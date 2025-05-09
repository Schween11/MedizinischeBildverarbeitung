%% Vorverarbeitungsschritte

% Original-Slice
I_orig = slice_cor;

% Gauß-Glättung
I_gauss = imgaussfilt(I_orig, 1.0);

% Medianfilter
I_med = medfilt2(I_orig, [3 3]);

% Bilateralfilter
I_bilat = imbilatfilt(I_orig);

% Anisotrope Diffusion
I_diff = imdiffusefilt(I_orig, 'NumberOfIterations', 15, 'GradientThreshold', 10);

%% Klassische Kantenerkennung (Canny)
BW_orig = edge(I_orig, 'Canny');
BW_gauss = edge(I_gauss, 'Canny');
BW_med = edge(I_med, 'Canny');
BW_bilat = edge(I_bilat, 'Canny');
BW_diff = edge(I_diff, 'Canny');

%% Fuzzy-basierte Kantenerkennung (über Gradientenmagnitude)

% Gradient berechnen (auf geglättetem Bild, z.B. Median)
[Gmag, ~] = imgradient(I_med);

% Erzeuge Mamdani-FIS
fis = mamfis('Name','EdgeFuzzy');
fis = addInput(fis, [0 1], 'Name', 'Gradient');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0], 'Name', 'low');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0.5], 'Name', 'medium');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 1], 'Name', 'high');

fis = addOutput(fis, [0 1], 'Name', 'EdgeStrength');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0 0 0.5], 'Name', 'weak');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0 0.5 1], 'Name', 'medium');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0.5 1 1], 'Name', 'strong');

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
%% Vergleich der Vorverarbeitungsschritte 

% Schritt 1: Glättung (linear)
I_gauss = imgaussfilt(slice_cor, 1.0);  % Sigma = 1.0

% Schritt 2: Glättung (nichtlinear)
I_med = medfilt2(slice_cor, [3 3]);  % Medianfilter --> besser für Kantenerhalt

% Schritt 3: Edge-preserving Smoothing (bilateral)
I_bilat = imbilatfilt(slice_cor);  % Erhält Kanten besser

% Schritt 4: Anisotrope Diffusion (Perona-Malik)
I_diff = imdiffusefilt(slice_cor, 'NumberOfIterations', 15, 'GradientThreshold', 10);

% Schritt 5: Kantenerkennung danach (z. B. Canny)
BW_orig = edge(slice_cor, 'Canny');
BW_gauss = edge(I_gauss, 'Canny');
BW_med = edge(I_med, 'Canny');
BW_bilat = edge(I_bilat, 'Canny');
BW_diff = edge(I_diff, 'Canny');

% Vergleich
figure;
subplot(2,3,1); imshow(BW_orig); title('Original + Canny');
subplot(2,3,2); imshow(BW_gauss); title('Gauß + Canny');
subplot(2,3,3); imshow(BW_med); title('Median + Canny');
subplot(2,3,4); imshow(BW_bilat); title('Bilateral + Canny');
subplot(2,3,5); imshow(BW_diff); title('Diffusion + Canny');  