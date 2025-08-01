% Input: Segmentierungsmaske von PlotSegmentation

BW = mask_kidney;

%% ROI anhand der Segmentierungsmaske definieren

% Regionprops mit BoundingBox
stats = regionprops(BW, 'BoundingBox');

bb = stats(1).BoundingBox;  % [x, y, width, height]

% BoundingBox runden → nötig für Indexzugriff
x1 = round(bb(1));
y1 = round(bb(2));
x2 = round(bb(1) + bb(3)) - 1;
y2 = round(bb(2) + bb(4)) - 1;

% Bildgröße
[H, W] = size(BW);

% Indexgrenzen beschneiden (mit Bildgrenzen als Maximum und Minimum)

x1 = max(1, x1-5); y1 = max(1, y1-5);
x2 = min(W, x2+5); y2 = min(H, y2+5);

% ROI-Maske erstellen
roi_mask = false(H, W); % Initialisierung
roi_mask(y1:y2, x1:x2) = true;

roi_tum = data.slice_tum_l(y1:y2, x1:x2); 


% Drei ausgewählte imadjust-Bereiche (beste aus vorheriger Analyse)
adjust_ranges = [;
                 0.2 0.8;
                 0.4 0.9
                 0.5 0.9];

% Drei Threshold-Paare für Canny
canny_thresholds = [
                   0.05  0.2;
                    0.08  0.25
                    0.1 0.33];

% Vorbereitung zum Plotten
figure;
img_idx = 1;

for i = 1:size(adjust_ranges,1)
    low_in = adjust_ranges(i,1);
    high_in = adjust_ranges(i,2);

    % Kontrastanpassung
    adj_img = imadjust(roi_norm, [low_in, high_in]);
    adj_img = imbilatfilt(adj_img);

    for j = 1:size(canny_thresholds,1)
        % Canny-Kantendetektion
        thresh = canny_thresholds(j,:);
        edge_img = edge(adj_img, 'Canny', thresh);

        % Plot
        subplot(3,3,img_idx);
        imshow(edge_img);
        title(sprintf('adj %.2f–%.2f, Canny %.2f–%.2f', ...
            low_in, high_in, thresh(1), thresh(2)));
        img_idx = img_idx + 1;
    end
end

%% Vorverarbeitung und Kantendetektion in der ROI nach Wahl Beobachtung der Parameter 
roi_norm = mat2gray(roi_tum);
roi_cont = imadjust(roi_norm, [0.5 0.7]);
roi_glatt = imbilatfilt(roi_cont);
roi_edge = edge(roi_glatt,"Canny",[0.05 0.4]););
roi_less = bwareaopen(roi_edge, 100);
roi_closed = imclose(roi_less, strel("sphere",1));

%% Herasufiltern von länglichen Strukturen

% connected components und regionprops definieren
CC = bwconncomp(roi_less); %% struct mit allen connected components
stats_roi = regionprops(CC, 'Area', 'BoundingBox'); % Eigenschaften der CC, viele mögliche Eingaben

% Parameter: möglichst keine länglichen Strukturen
min_ratio = 0.5;         % Mindest-Seitenverhältnis Höhe/Breite
max_ratio = 2 ;         % Maximal-Seitenverhältnis

% Leeres Bild für die besten Strukturen
BW_best = zeros(size(roi_less));

for i = 1:length(stats_roi) % Schleife über alle detektierten CC´s
    area = stats_roi(i).Area;
    bbox = stats_roi(i).BoundingBox;
    width = bbox(3);
    height = bbox(4);
    ratio = height / width;

    if ratio >= min_ratio && ratio <= max_ratio
       BW_best(CC.PixelIdxList{i}) = 1; % wenn Bedingung erfüllt --> Struktur wird beibehalten
    end
end



%% Plotten
target = roi_closed;
reference_circle = edge(data.circle_half,"Canny");
reference_oval = edge(data.oval_half,"Canny");
figure;

% Form 1 Kreis nur für tumor
 [target_marked_cd, reference_marked_c,XBest_c ,YBest_c, ~, scale_c, score_c] = find_tumor(target, reference_circle);
 subplot(2,2,1); imshow(target_marked_cd); title(sprintf('Circle \nScore: %.2f, \nScale: %.2f', score_c, scale_c));
 subplot(2,2,2); imshow(reference_marked_c); title('Ref: Circle');

% Form 2 Oval
[target_marked_cd, reference_marked_k, XBest_k, YBest_k, ~, scale_k, score_k] = find_tumor(target, reference_oval);
subplot(2,2,3); imshow(target_marked_cd); title(sprintf('Kidney \nScore: %.2f, \nScale: %.2f', score_k, scale_k));
subplot(2,2,4); imshow(reference_marked_k); title('Ref: Kidney');
