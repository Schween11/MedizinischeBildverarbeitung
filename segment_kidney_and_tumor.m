% ===============================================
% segment_kidney_and_tumor.m
% ===============================================
function [mask_kidney, mask_tumor] = segment_kidney_and_tumor(im_norm, YBest, XBest, reference_oval, scale_best, doTumorSegmentation, opts)

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
[~, chosen_cluster_kidney] = min(vecnorm(C_k - C0(1,:), 2, 2));

kmeans_mask_kidney = zeros(size(im_norm));
kmeans_mask_kidney(roi_mask) = idx_k == chosen_cluster_kidney;

% --- Startmaske Niere ---
start_mask_kidney = imclose(kmeans_mask_kidney, strel('disk', 1));
start_mask_kidney = imfill(start_mask_kidney, 'holes');
start_mask_kidney = bwareaopen(start_mask_kidney, 300);

% --- Chan-Vese Niere ---
mask_kidney = activecontour(im_norm, start_mask_kidney, opts.chanvese_iters_kidney, 'Chan-Vese');
mask_kidney = bwareafilt(mask_kidney, 1);  % nur größte zusammenhängende Region behalten

% === Tumorsegmentierung (optional) ===
if doTumorSegmentation
    im_tumor = im_norm;
    im_tumor(~mask_kidney) = 0;

    [~, grad_tumor] = imgradient(im_tumor);
    vals_tumor = im_tumor(mask_kidney);
    grads_tumor = grad_tumor(mask_kidney);
    features_tumor = [double(vals_tumor(:)), grads_tumor(:)];
    
    if size(features_tumor, 1) < opts.k_tumor
        warning('Zu wenige Punkte für Tumor-KMeans (%d benötigt, %d vorhanden). Segmentierung übersprungen.', ...
            opts.k_tumor, size(features_tumor,1));
        mask_tumor = false(size(im_norm));
        return;
    end

    [idx_t, C_t] = kmeans(features_tumor, opts.k_tumor, 'Replicates', 1);
    [~, sorted_idx] = sort(C_t(:,1));  % sortiere nach Grauwert
    chosen_cluster_tumor = sorted_idx(2);  % zweitniedrigster Grauwert


    tumor_mask = zeros(size(im_norm));
    tumor_mask(mask_kidney) = idx_t == chosen_cluster_tumor;

    start_mask_tumor = imopen(tumor_mask, strel('disk', 2));
    start_mask_tumor = imfill(start_mask_tumor, 'holes');

    mask_tumor_tmp = activecontour(im_tumor, start_mask_tumor, opts.chanvese_iters_tumor, 'Chan-Vese');

    % Flächen vergleichen
    area_kidney = sum(mask_kidney(:));
    area_tumor  = sum(mask_tumor_tmp(:));
    
    if area_tumor < opts.tumor_size_ratio * area_kidney  % Tumor ist kleiner als 50% der Niere
        mask_tumor = mask_tumor_tmp;
    else
        warning('Tumormaske zu groß im Verhältnis zur Niere – verworfen.');
        mask_tumor = false(size(im_norm));
    end

    if any(mask_tumor(:))
        mask_tumor = bwareaopen(mask_tumor, 100);
    else
        mask_tumor = false(size(im_norm));
    end
    
else
    mask_tumor = false(size(im_norm));
end

% --- Plot optional ---
if isfield(opts, 'plot') && opts.plot
    plot_kidney_tumor_segmentation(im_norm, roi_mask, kmeans_mask_kidney, start_mask_kidney, mask_kidney, mask_tumor, doTumorSegmentation, opts.plotAll, opts.case_id);
end
end

% ===============================================
% plot_kidney_tumor_segmentation.m
% ===============================================
function plot_kidney_tumor_segmentation(im_norm, roi_mask, kmeans_mask, start_mask, kidney_mask, tumor_mask, doTumor, plotAll, case_id)

figure('Color','w');

if doTumor
    sgtitle(sprintf('Segmentierung Niere + Tumor - Case %d', case_id), 'FontSize', 14, 'FontWeight','bold');
else
    sgtitle(sprintf('Segmentierung Niere - Case %d', case_id), 'FontSize', 14, 'FontWeight','bold');
end

if plotAll
    subplot(2,3,1); imshow(im_norm, []); title('Originalbild');
    subplot(2,3,2); imshow(roi_mask); title('ROI (GHT-basiert)');
    subplot(2,3,3); imshow(kmeans_mask); title('KMeans-Maske (Niere)');
    subplot(2,3,4); imshow(start_mask); title('Startmaske Niere');
    subplot(2,3,5); imshow(kidney_mask); title('Segmentierte Niere');
    
    % === Overlay: Niere (rot), Tumor (grün) ===
    overlay = repmat(im2double(im_norm), [1 1 3]);  % Graubild → RGB
    
    % Niere: rot umrandet
    perim_kidney = imdilate(bwperim(kidney_mask), strel('disk',1));
    overlay(:,:,1) = max(overlay(:,:,1), perim_kidney);      % R+
    overlay(:,:,2) = overlay(:,:,2) .* ~perim_kidney;        % G–
    overlay(:,:,3) = overlay(:,:,3) .* ~perim_kidney;        % B–
    
    if doTumor
        % Tumor: grün umrandet
        perim_tumor = imdilate(bwperim(tumor_mask), strel('disk',1));
        overlay(:,:,2) = max(overlay(:,:,2), perim_tumor);   % G+
        overlay(:,:,1) = overlay(:,:,1) .* ~perim_tumor;     % R–
        overlay(:,:,3) = overlay(:,:,3) .* ~perim_tumor;     % B–
    end
    
    subplot(2,3,6); imshow(overlay);
    title('Segmentiertes Ergebnis: Niere (rot), Tumor (grün)');
    
else

    % === Overlay: Niere (rot), Tumor (grün) ===
    overlay = repmat(im2double(im_norm), [1 1 3]);  % Graubild → RGB
    
    % Niere: rot umrandet
    perim_kidney = imdilate(bwperim(kidney_mask), strel('disk',1));
    overlay(:,:,1) = max(overlay(:,:,1), perim_kidney);      % R+
    overlay(:,:,2) = overlay(:,:,2) .* ~perim_kidney;        % G–
    overlay(:,:,3) = overlay(:,:,3) .* ~perim_kidney;        % B–
    
    if doTumor
        % Tumor: grün umrandet
        perim_tumor = imdilate(bwperim(tumor_mask), strel('disk',1));
        overlay(:,:,2) = max(overlay(:,:,2), perim_tumor);   % G+
        overlay(:,:,1) = overlay(:,:,1) .* ~perim_tumor;     % R–
        overlay(:,:,3) = overlay(:,:,3) .* ~perim_tumor;     % B–
    end
    imshow(overlay)
end
end
