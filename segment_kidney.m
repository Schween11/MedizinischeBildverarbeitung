% ===============================================
% segment_kidney.m
% ===============================================
function [mask_kidney] = segment_kidney(im_norm, YBest, XBest, reference_oval, scale_best, opts)

im_norm = adapthisteq(im_norm, 'NumTiles', [8 8], 'ClipLimit', 0.01);
im_norm = imgaussfilt(im_norm, 1);

% --- ROI definieren ---
w = scale_best * size(reference_oval,2) ;
h = scale_best * size(reference_oval,1) ;
[H, W] = size(im_norm);

x1 = max(1, round(XBest - w/2));
y1 = max(1, round(YBest - h/2));
x2 = min(W, round(XBest + w/2));
y2 = min(H, round(YBest + h/2));

roi_mask = false(size(im_norm));
roi_mask(y1:y2, x1:x2) = true;
im_roi = im_norm;
im_roi(~roi_mask) = 0;

% --- Feature-Extraktion für Niere ---
roi_vals = im_roi(roi_mask);
[~, grad_mag] = imgradient(im_roi);
grad_vals = grad_mag(roi_mask);

F1 = double(roi_vals(:));
F2 = grad_vals(:);
features_kidney = [F1, F2];

K = opts.k_kidney;

% --- Adaptive Startzentren: gleichmäßig im Grauwertbereich ---
min_F1 = min(F1);
max_F1 = max(F1);
c_vals = linspace(min_F1, max_F1, K);  % gleichmäßige Verteilung über ROI-Intensitäten

C0 = [c_vals(:), linspace(0, max(F2), K)'];

% --- KMeans für Niere ---
[idx_k, C_k] = kmeans(features_kidney, opts.k_kidney, 'Start', C0, 'Replicates', 1);

% --- GHT-Seed-Zentrum (Grauwert + Grad) extrahieren ---
xg = round(XBest); yg = round(YBest);
gv_ght = double(im_roi(yg, xg));
gm_ght = grad_mag(yg, xg);
center_ght = [gv_ght, gm_ght];

% --- Fläche pro Cluster berechnen ---
cluster_counts = accumarray(idx_k, 1);

% --- Distanz zum GHT-Zentrum berechnen ---
dists = vecnorm(C_k - center_ght, 2, 2);  % euklidische Distanz

% --- Normalisieren ---
dists_norm = (dists - min(dists)) / (max(dists) - min(dists) + eps);
counts_norm = (cluster_counts - min(cluster_counts)) / (max(cluster_counts) - min(cluster_counts) + eps);

% --- Gewichtete Kombi-Metrik: Nähe GHT (0.7), Fläche (0.3) ---
score = -0.85 * (1 - dists_norm) + 0.15 * counts_norm;

% --- Cluster mit bestem Score wählen ---
[~, chosen_cluster_kidney] = max(score);

% --- Binary Maske erzeugen ---
kmeans_mask_kidney = zeros(size(im_norm));
kmeans_mask_kidney(roi_mask) = idx_k == chosen_cluster_kidney;

% --- Startmaske Niere ---
mask_tmp = imclose(kmeans_mask_kidney, strel('disk', 3));       % Lücken schließen
mask_tmp = imfill(mask_tmp, 'holes');                           % Löcher füllen
mask_tmp = bwareaopen(mask_tmp, 300);                           % kleine Objekte entfernen

% Neue Maske, nur größte zusammenhängende Fläche
mask_main = bwareafilt(mask_tmp, 1);

% Alle Löcher innerhalb dieser Struktur füllen
start_mask_kidney = imfill(mask_main, 'holes');


% --- Chan-Vese Niere ---
mask_kidney = activecontour(im_norm, start_mask_kidney, opts.chanvese_iters_kidney, 'Chan-Vese');
mask_kidney = bwareafilt(mask_kidney, 1);  % nur größte zusammenhängende Region behalten

plot_kidney_segmentation(im_norm, roi_mask, kmeans_mask_kidney, start_mask_kidney, mask_kidney, opts.plotAll, opts.case_id);

end

% ===============================================
% plot_kidney_tumor_segmentation.m
% ===============================================
function plot_kidney_segmentation(im_norm, roi_mask, kmeans_mask, start_mask, kidney_mask, plotAll, case_id)

figure('Color','w');


sgtitle(sprintf('Segmentierung Niere - Case %d', case_id), 'FontSize', 14, 'FontWeight','bold');


if plotAll
    subplot(2,3,1); imshow(im_norm, []); title('Originalbild');
    subplot(2,3,2); imshow(roi_mask); title('ROI (GHT-basiert)');
    subplot(2,3,3); imshow(kmeans_mask); title('KMeans-Maske (Niere)');
    subplot(2,3,4); imshow(start_mask); title('Startmaske Niere');
    subplot(2,3,5); imshow(kidney_mask); title('Segmentierte Niere');
    
    % === Overlay: Niere (rot)
    overlay = repmat(im2double(im_norm), [1 1 3]);  % Graubild → RGB
    
    % Niere: rot umrandet
    perim_kidney = imdilate(bwperim(kidney_mask), strel('disk',2));
    overlay(:,:,1) = max(overlay(:,:,1), perim_kidney);      % R+
    overlay(:,:,2) = overlay(:,:,2) .* ~perim_kidney;        % G–
    overlay(:,:,3) = overlay(:,:,3) .* ~perim_kidney;        % B–
    
    
    
    subplot(2,3,6); imshow(overlay);
    title('Segmentiertes Ergebnis: Niere (rot), Tumor (grün)');
    
else

    % === Overlay: Niere (rot)
    overlay = repmat(im2double(im_norm), [1 1 3]);  % Graubild → RGB
    
    % Niere: rot umrandet
    perim_kidney = imdilate(bwperim(kidney_mask), strel('disk',2));
    overlay(:,:,1) = max(overlay(:,:,1), perim_kidney);      % R+
    overlay(:,:,2) = overlay(:,:,2) .* ~perim_kidney;        % G–
    overlay(:,:,3) = overlay(:,:,3) .* ~perim_kidney;        % B–
    
   
    imshow(overlay)
end
end
