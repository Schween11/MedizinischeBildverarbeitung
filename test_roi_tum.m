%% Laden der Daten

case_id = 33;
data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);
reference_circle = result.circle_edge;
target_kid = result.BW_best;

% Anwendung von find object um ROI für Nierenbereich zu erstellen
[target_marked_cd, reference_marked_c, YBest, XBest, ang, scale_c, score_c] = find_object(target_kid, reference_circle);

location_str = string(data.tbl{data.row,12});
first_word = extractBefore(location_str, ',');

% Auswahl der pathologischen Seite
if first_word == "rechts"
    target_tum = data.slice_tum_r;
else 
    target_tum = data.slice_tum_l;
end

%% Berechnung der ROI

[y_size, x_size] = size(target_tum);
y_half = 80;
x_half = 80; % halbe Pixelgröße der ROI --> auch angepasst an Nierengröße möglich
x_min = max(XBest - x_half, 1);
x_max = min(XBest + x_half, x_size);
y_min = max(YBest - y_half, 1);
y_max = min(YBest + y_half, y_size);

roi = target_tum(y_min:y_max,x_min:x_max); % verkleinerte ROI
roi_tum_mask = data.mask_tum_l(y_min:y_max,x_min:x_max);

%% Weiterverarbeitung und Kantendetektion ähnlich zur EdgeDetection

roi_norm = mat2gray(roi); % erneute Normierung für besseren Kontrast
roi_cont = adapthisteq(roi_norm,"NumTiles",[8 8],"ClipLimit",0.01);

% Otsu threshold
level = graythresh(roi_cont);
% Set Canny threshold based on Otsu threshold
cannythreshold = 0.9.*[level/2 level];

%% unbearbeitet
roi_norm_edge = edge(roi_norm,"Canny",cannythreshold); % Canny Kantenerkennung
roi_norm_less = bwareaopen(roi_norm_edge,80);
se = strel('disk', 1);  
norm_closed_edges = imclose(roi_norm_edge, se); % Schließen der Strukturen
roi_norm_thin = bwmorph(norm_closed_edges, 'thin', Inf);

%% imbilat
roi_smooth = imbilatfilt(roi_cont, 0.15, 15);  % Edge-preserving smoothing
roi_edge = edge(roi_smooth,"Canny",cannythreshold); % Canny Kantenerkennung
roi_less = bwareaopen(roi_edge,80);
closed_edges = imclose(roi_less, se); % Schließen der Strukturen
roi_thin = bwmorph(closed_edges, 'thin', Inf);

%% imdiffuse
roi_smooth2 = imdiffusefilt(roi_cont,"GradientThreshold",4,"NumberOfIterations",10);
roi_cont_edge = edge(roi_smooth2,"Canny",cannythreshold); % Canny Kantenerkennung
roi_cont_less = bwareaopen(roi_cont_edge,80); 
cont_closed_edges = imclose(roi_cont_less, se); % Schließen der Strukturen
roi_cont_thin = bwmorph(cont_closed_edges, 'thin', Inf);

%% Gaussian Blur
roi_gauss = imgaussfilt(roi_cont, 1.5); % Gaussian smoothing
roi_gauss_edge = edge(roi_gauss,"Canny",cannythreshold);
roi_gauss_less = bwareaopen(roi_gauss_edge,80);
roi_gauss_closed = imclose(roi_gauss_less, se);
roi_gauss_thin = bwmorph(roi_gauss_closed, 'thin', Inf);


%% Anzeige
subplot(5,4,1)
imshow(roi_norm); title("unbearbeitet")
subplot(5,4,2)
imshow(roi_norm_edge); title("Canny edge")
subplot(5,4,3)
imshow(roi_norm_less); title("bwareamorph")
subplot(5,4,4)
imshow(roi_norm_thin); title("closed edges and thinned")

subplot(5,4,5)
imshow(roi_smooth2); title("imdiffuse")
subplot(5,4,6)
imshow(roi_cont_edge); title("Canny edge")
subplot(5,4,7)
imshow(roi_cont_less); title("bwareamorph")
subplot(5,4,8)
imshow(roi_cont_thin); title("closed edges and thinned")

subplot(5,4,9)
imshow(roi_smooth); title("imbilat")
subplot(5,4,10)
imshow(roi_edge); title("Canny edge")
subplot(5,4,11)
imshow(roi_less); title("bwareamorph")
subplot(5,4,12)
imshow(roi_thin); title("closed edges and thinned")

subplot(5,4,13)
imshow(roi_gauss); title("Gaussian")
subplot(5,4,14)
imshow(roi_gauss_edge); title("Canny edge")
subplot(5,4,15)
imshow(roi_gauss_less); title("bwareamorph")
subplot(5,4,16)
imshow(roi_gauss_thin); title("closed edges and thinned")



% morphologischer Filter um kleine Strukturen herauszufiltern
% evtl. weitere Verarbeitung mit bwconncomp
% CC = bwconncomp(closed_edges);
% stats = regionprops(CC, 'Area', 'Eccentricity');
