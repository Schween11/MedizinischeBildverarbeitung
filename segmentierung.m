% --- Parameter ---
w = 69; h = 104; % ROI-Größe anpassen bei Bedarf
num_clusters = 5; % Für KMeans
im_norm = data.slice_kid_r; 
% --- ROI-Maske aus GHT Position ---
x = round(Ybest - w/2);
y = round(Xbest - h/2);

[H, W] = size(im_norm);
x = max(1, min(x, W - w));
y = max(1, min(y, H - h));

roi_mask = false(size(im_norm));
roi_mask(y:(y+h), x:(x+w)) = true;

% --- Nur ROI für KMeans ---
im_roi = im_norm;
im_roi(~roi_mask) = 0;

% KMeans vorbereiten
roi_vals = im_roi(roi_mask);
roi_vals_vec = double(roi_vals(:));

% KMeans-Clustering
[idx, C] = kmeans(roi_vals_vec, num_clusters);

% Cluster-Maske rekonstruieren
kmeans_idx_full = zeros(size(im_norm));
kmeans_idx_full(roi_mask) = idx;

% Wähle Cluster mit mittlerem Intensitätswert (typisch Niere)
[~, order] = sort(C);
kidney_cluster = order(2);
kmeans_mask = kmeans_idx_full == kidney_cluster;

% --- Startmaske vorbereiten ---
start_mask = imclose(kmeans_mask, strel('disk', 3));
start_mask = imfill(start_mask, 'holes');
start_mask = bwareaopen(start_mask, 100);

% --- Chan-Vese anwenden ---
chanvese_result = activecontour(im_norm, start_mask, 500, 'Chan-Vese');

% --- Finales Ergebnisbild ---
segmented_overlay = im_norm;
segmented_overlay = imoverlay(segmented_overlay, bwperim(chanvese_result), [1 0 0]);

% --- Plot ---
figure('Color','w');
sgtitle('Segmentierung mit GHT + KMeans + Chan-Vese','FontSize',16,'FontWeight','bold');

subplot(2,3,1); imshow(im_norm); title('Normiertes Bild');
subplot(2,3,2); imshow(roi_mask); title('GHT Rechteck-Maske');
subplot(2,3,3); imshow(kmeans_mask); title('K-Means Maske');

subplot(2,3,4); imshow(start_mask); title('Startmaske');
subplot(2,3,5); imshow(chanvese_result); title('Chan-Vese Ergebnis');
subplot(2,3,6); imshow(segmented_overlay); title('Segmentiertes Ergebnis');

