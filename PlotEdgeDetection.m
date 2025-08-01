case_id = 158;
result = EdgeDetection(case_id);

% Plot-Vergleich für beide Seiten: rechts (r) und links (l)
figure;

% Rechter Slice – Nierenkante
subplot(2,3,1);
imshow(result.BW_best_r);
title('rechts: Diffusion + Canny');

% Linker Slice – Nierenkante
subplot(2,3,2);
imshow(result.BW_best_l);
title('links: Diffusion + Canny');

% Maske Kantenbild – Vergleichsbild
subplot(2,3,4);
imshow(result.mask_edge);
title('Maske Niere');

