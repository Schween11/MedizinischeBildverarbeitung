% Ursprungsbild (Graustufen, normiert)
I = im2double(slice_cor);

% Multi-Scale Parameter
iterations = [5, 15, 30];
num_scales = length(iterations);

% Init Arrays
Gmag_diffuse = zeros([size(I), num_scales]);
Gmag_bilat = zeros([size(I), num_scales]);
canny_diffuse = false([size(I), num_scales]);
canny_bilat = false([size(I), num_scales]);

% Multi-Scale Verarbeitung
for k = 1:num_scales
    % --- Anisotrope Diffusion ---
    I_diff = imdiffusefilt(I, ...
        'NumberOfIterations', iterations(k), ...
        'GradientThreshold', 10);
    [Gdiff, ~] = imgradient(I_diff);
    Gmag_diffuse(:,:,k) = mat2gray(Gdiff);
    canny_diffuse(:,:,k) = edge(I_diff, 'Canny');

    % --- Bilateral Filter ---
    I_bilat = imbilatfilt(I, 0.1, 2);  % σR, σS ggf. anpassen
    I_bilat = imbilatfilt(I_bilat, 0.1, 2);  % zwei Stufen für Vergleichbarkeit
    [Gbilat, ~] = imgradient(I_bilat);
    Gmag_bilat(:,:,k) = mat2gray(Gbilat);
    canny_bilat(:,:,k) = edge(I_bilat, 'Canny');
end

% --- Kombination der Skalen ---
Gmag_diff_comb = max(Gmag_diffuse, [], 3);
Gmag_bilat_comb = max(Gmag_bilat, [], 3);
canny_diff_comb = any(canny_diffuse, 3);
canny_bilat_comb = any(canny_bilat, 3);

% --- Fuzzy-System auf beide Varianten ---
fuzzy_diff = reshape(evalfis(fis, Gmag_diff_comb(:)), size(Gmag_diff_comb));
fuzzy_bilat = reshape(evalfis(fis, Gmag_bilat_comb(:)), size(Gmag_bilat_comb));

% --- Nachbearbeitung ---
fuzzy_diff_bin = imbinarize(fuzzy_diff, 0.3);
fuzzy_diff_thin = bwmorph(fuzzy_diff_bin, 'thin', Inf);

fuzzy_bilat_bin = imbinarize(fuzzy_bilat, 0.3);
fuzzy_bilat_thin = bwmorph(fuzzy_bilat_bin, 'thin', Inf);

canny_diff_thin = bwmorph(canny_diff_comb, 'thin', Inf);
canny_bilat_thin = bwmorph(canny_bilat_comb, 'thin', Inf);

% --- Visualisierung ---
figure('Name', 'Fuzzy vs Canny – Diffusion & Bilateral');

subplot(2,3,1);
imshow(fuzzy_diff_thin);
title('Fuzzy (Diffusion)');

subplot(2,3,2);
imshow(canny_diff_thin);
title('Canny (Diffusion)');

subplot(2,3,3);
imshow(Gmag_diff_comb, []);
title('Gradients (Diffusion)');

subplot(2,3,4);
imshow(fuzzy_bilat_thin);
title('Fuzzy (Bilateral)');

subplot(2,3,5);
imshow(canny_bilat_thin);
title('Canny (Bilateral)');

subplot(2,3,6);
imshow(Gmag_bilat_comb, []);
title('Gradients (Bilateral)');

%branch