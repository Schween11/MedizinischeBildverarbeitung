
%% Vergleich der Kantendetektionen

% Schritt 1: Glättung (linear)
I_gauss = imgaussfilt(slice_cor, 1.0);  % Sigma = 1.0

% Schritt 2: Glättung (nichtlinear)
I_med = medfilt2(slice_cor, [3 3]);  % Medianfilter

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
