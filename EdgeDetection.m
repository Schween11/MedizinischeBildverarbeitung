function result = EdgeDetection(case_id);
%{
BESCHREIBUNG:
Führt eine Kantendetektion zur Vorbereitung der GHT durch. Für beide vorverarbeiteten
Nierenhälften aus loadCaseData_i sowie für die Referenzformen und die Masken .

INPUT:
Fallnummer (case_id) als Zahl (z.B 3, 62, 141)

OUTPUT:
Ein Struct (result) mit vorbereiteten Kantenbildern:
- vereinfachte Kantenbilder der linken und rechten Niere 
- zugehörige Originalbilder
- Kantenbild der Referenzformen (Kreis, Oval, Niere, "modifizierte" Niere)
- Kantenbild der segmentierten Nieren- und Tumormasken
%}

%% 0. Aufrufen der vorverarbeiteten Daten im Struct
data = loadCaseData_i(case_id); 

%% 1. Kantendetektion für Nierenlokalisation – beide Seiten
% Bilddaten für beide Seiten
I_kid_r = data.slice_kid_r;
I_kid_l = data.slice_kid_l;

% Leere Strukturen für Ergebnisse
sides = {'r', 'l'};  % rechts, links
for s = 1:2
    side = sides{s};
    I_kid = eval(['I_kid_', side]);  % Zugriff auf das jeweilige Bild

    % 1.1. Kontrasterhöhung + Glättung
    I_cont = adapthisteq(I_kid, 'NumTiles', [8 8], 'ClipLimit', 0.005);
    %I_cont2 = imadjust(I_kid, [0.3 0.8]); % alternative Kontrasterhöhung
    I_tum_diff = imdiffusefilt(I_cont, "GradientThreshold", 3, "NumberOfIterations", 3);

    % 1.2. Canny-Kanten + kleine Objekte entfernen
    BW_edge = edge(I_tum_diff, 'Canny', 0.2, 0.6);
    BW_edge_less = bwareaopen(BW_edge, 50);
    
    % 1.3. Herausfiltern von länglichen Strukturen
    CC = bwconncomp(BW_edge_less);
    stats = regionprops(CC, 'BoundingBox');

    min_ratio = 0.5;
    max_ratio = 2;
    BW_best = zeros(size(BW_edge_less));

    for i = 1:length(stats)
        bbox = stats(i).BoundingBox;
        width = bbox(3);
        height = bbox(4);
        ratio = height / width;
        if ratio >= min_ratio && ratio <= max_ratio
            BW_best(CC.PixelIdxList{i}) = 1;
        end
    end

    % Speicherung für die jeweilige Seite
    result.(['BW_best_' side]) = BW_best; % vereinfachtes Kantenbild links und rechts
    result.(['I_kid_' side]) = I_kid; % unverarbeitetes Bild
end

 
%% optional: Bounding-Boxes anzeigen 
% figure; imshow(BW_edge_less); hold on;
% 
% % Alle Bounding Boxes zeichnen
% for i = 1:length(stats)
%     bbox = stats(i).BoundingBox;  % [x, y, width, height]
%     rectangle('Position', bbox, 'EdgeColor', 'g', 'LineWidth', 1);
% end
% 
% title('Alle Bounding Boxes');

%% 2. Kantendetektion für Tumorlokalisation
% optional hier eine Kantendetektion in der Tumor-Slice implementieren

%% 3. Canny-Kantendetektion der Shapes (für find_object Funktion)
circle_edge = edge(data.circle, 'Canny');
oval_edge = edge(data.oval, 'Canny');
kidney_edge = edge(data.kidney, 'Canny');
kidney_mod_edge = edge(data.kidney_mod, 'Canny');
circle_half_edge = edge(data.circle_half, 'Canny');
oval_half_edge = edge(data.oval_half, 'Canny');

%% 4. Canny-Kantendetektion der Masken (für späteren Vergleich)
mask_edge = edge(data.mask_kid_interp, "Canny");
mask_tum_edge = edge(data.mask_kid_tumor_interp,"Canny");


%% Ausgabe als Struktur speichern

result.kidney_edge = kidney_edge;
result.kidney_mod_edge = kidney_mod_edge;
result.circle_edge = circle_edge;
result.oval_edge = oval_edge;
result.oval_half_edge = oval_half_edge;
result.circle_half_edge = circle_half_edge;
result.mask_kid_r = data.mask_kid_r;
result.mask_kid_l = data.mask_kid_l;
result.mask_edge = mask_edge;
result.mask_tum_edge = mask_tum_edge;


end
