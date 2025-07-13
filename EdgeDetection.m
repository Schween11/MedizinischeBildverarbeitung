%% Funktionsdefinition mit Case-ID als Input

function result = EdgeDetection(case_id);

%% 0. Aufrufen der vorverarbeiteten Daten im Struct
data = loadCaseData_i(case_id); 

%% 1. Kantendetektion für Nierenlokalisation

% Auswahl der pathologische Seite 
location_str = string(data.tbl{data.row,12});
first_word = extractBefore(location_str, ',');

if first_word == "rechts"
    I_kid = data.slice_kid_r;
else 
    I_kid = data.slice_kid_l;
end

%% 1.1. Vorverarbeitungsschritte 

% sehr leichte Kontrastverstärkung
I_cont = adapthisteq(I_kid, 'NumTiles', [8 8], 'ClipLimit', 0.005);

% Anisotroper Diffusionsfilter (anisotrope Glättung)
I_tum_diff = imdiffusefilt(I_cont ,"GradientThreshold",5,"NumberOfIterations",5);

%% 1.2. Canny-Kantendetektion --> zur Detektion der Niere, stark vereinfachtes Kantenbild
BW_edge = edge(I_tum_diff, 'Canny',0.2,0.6);
BW_edge_less = bwareaopen(BW_edge, 150); %hilfreich bei
% Nierensegmentation, herausfiltern von kleinen Strukturen

%% 1.3. Herausfiltern von langen vertikalen Strukturen
% Nach Kantendetektion und eventuellem bwareaopen
% Ausgangsbild: BW (dein Kantenbild nach Canny + bwareaopen)
CC = bwconncomp(BW_edge_less);
stats = regionprops(CC, 'Area', 'BoundingBox');

% Parameter: was gilt als "gute" Struktur
minAR = 0.5;         % Mindest-Seitenverhältnis Höhe/Breite
maxAR = 2 ;         % Maximal-Seitenverhältnis

% Leeres Bild für die besten Strukturen
BW_best = zeros(size(BW_edge_less));

for i = 1:length(stats)
    area = stats(i).Area;
    bbox = stats(i).BoundingBox;
    width = bbox(3);
    height = bbox(4);
    aspectRatio = height / width;

    if aspectRatio >= minAR && aspectRatio <= maxAR
       BW_best(CC.PixelIdxList{i}) = true;
    end
end

 
%% Bounding-Boxes anzeigen 
% figure; imshow(BW_edge_less); hold on;
% 
% % Alle Bounding Boxes zeichnen
% for i = 1:length(stats)
%     bbox = stats(i).BoundingBox;  % [x, y, width, height]
%     rectangle('Position', bbox, 'EdgeColor', 'g', 'LineWidth', 1);
% end
% 
% title('Alle Bounding Boxes');

%% 1.4. Canny-Kantendetektion der Masken (für späteren Vergleich)
mask_edge = edge(data.mask_kid_interp, "Canny");
mask_tum_edge = edge(data.mask_kid_tumor_interp,"Canny");

%% 2. Kantendetektion für Tumorlokalisation

% Auswahl der pathologische Seite 
location_str = string(data.tbl{data.row,12});
first_word = extractBefore(location_str, ',');

if first_word == "rechts"
    I_tum = data.slice_tum_r;
else 
    I_tum = data.slice_tum_l;
end

% Adaptive Histogramm-Angleichung (Kontrastverstärkung)
I_tum_cont = adapthisteq(I_tum, 'NumTiles', [8 8], 'ClipLimit', 0.04);

% analog zu Nierenlokalisation (andere Parameter)
I_tum_diff = imdiffusefilt(I_tum_cont ,"GradientThreshold",3,"NumberOfIterations",3);
I_tum_edge = edge(I_tum_diff, 'Canny',0.3,0.7);

%% 3. Canny-Kantendetektion der Shapes (für find_object Funktion)
circle_edge = edge(data.circle, 'Canny');
oval_edge = edge(data.oval, 'Canny');
kidney_edge = edge(data.kidney, 'Canny');
kidney_mod_edge = edge(data.kidney_mod, 'Canny');

%% 4. Canny-Kantendetektion der Masken (für späteren Vergleich)
mask_edge = edge(data.mask_kid_interp, "Canny");
mask_tum_edge = edge(data.mask_kid_tumor_interp,"Canny");


%% Ausgabe als Struktur speichern
result = struct();
result.BW_edge_less = BW_edge_less;
result.BW_best = BW_best;
result.case_id = case_id;

% Niere
result.kidney_edge = kidney_edge;
result.kidney_mod_edge = kidney_mod_edge;
result.circle_edge = circle_edge;
result.oval_edge = oval_edge;
result.mask_kid_r = data.mask_kid_r;
result.mask_kid_l = data.mask_kid_l;
result.mask_edge = mask_edge;
result.mask_tum_edge = mask_tum_edge;

% Tumor

end
