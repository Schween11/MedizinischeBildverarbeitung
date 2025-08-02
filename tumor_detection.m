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

x1 = max(1, x1); y1 = max(1, y1);
x2 = min(W, x2); y2 = min(H, y2);

% ROI-Maske erstellen
roi_mask = false(H, W); % Initialisierung
roi_mask(y1:y2, x1:x2) = true;

roi_tum = data.slice_tum_l(y1:y2, x1:x2); 

%% Vorverarbeitung und Kantendetektion in der ROI nach Wahl Beobachtung der Parameter 
roi_norm = mat2gray(roi_tum);
roi_cont = imadjust(roi_norm, [0.4 0.8]);
roi_glatt = imbilatfilt(roi_cont);
roi_edge = edge(roi_glatt,"Canny",[0.05 0.4]);
roi_less = bwareaopen(roi_edge, 50);
roi_closed = imclose(roi_less, strel("sphere",1));

%% Herasufiltern von länglichen Strukturen

% connected components und regionprops definieren
CC = bwconncomp(roi_less); %% struct mit allen connected components
stats_roi = regionprops(CC, 'Area', 'BoundingBox'); % Eigenschaften der CC, viele mögliche Eingaben


%% Plotten
target = roi_less;
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
