%% Funktionsdefinition mit Case-ID als Input

function result = EdgeDetection(case_id);

% Aufrufen der vorverarbeiteten Daten im Struct
data = loadCaseData_i(case_id); 

% Auswahl der pathologische Seite 
location_str = string(data.tbl{data.row,12});
first_word = extractBefore(location_str, ',');

if first_word == "rechts"
    I_orig = data.slice_cor_r;
else 
    I_orig = data.slice_cor_l;
end

%% Vorverarbeitungsschritte 

% Parameter für Canny und Diffusionsfilter 
nmb_it = 5; % mehr Iteration --> stärkere Glättung --> weniger Details
grd_thr = 10; % Gradiententhreshold --> Threshold hoch --> weniger Details 
low_thr = 0.1; % zwischen low und high dann Kante, wenn mit anderen Kanten verbunden
high_thr = 0.4; % alles drüber sichere Kante
min_pix = 160; % minimale Anzahl der zusammenhängenden Pixel um nicht herausgefiltert zu werden


% Bilateralfilter
I_bilat = imbilatfilt(I_orig, 0.2, 4);

% Anisotroper Diffusionsfilter
I_diff = imdiffusefilt(I_orig, 'NumberOfIterations', nmb_it, 'GradientThreshold', grd_thr);

%% 1) Canny-Kantendetektion
BW_diff = edge(I_diff, 'Canny', low_thr, high_thr);
BW_diff = bwareaopen(BW_diff, min_pix);
BW_bilat = edge(I_bilat, 'Canny',  low_thr, high_thr);
BW_bilat = bwareaopen(BW_bilat, min_pix); % Filtern zusammenhängender Pixel mit 8er Konnektivität (Diagonale)

%% 2) Herausfiltern von langen vertikalen Strukturen
tic
% Verbundene Komponenten finden
% bwconncomp (BlackAndWhiteConnectedComponents) erstellt struct mit: Konnektiviät, Bildgröße, Anzahl
% gefundener Objekte und Pixelliste zusammenhängender Komponenten -->
% findet zusammenhängenden Strukturen/Pixel und listet sie auf 

CC = bwconncomp(BW_diff);

% BoundingBox berechnen
% --> kleinst mögliches Rechteck, welches alle Pixel vollständig umhüllt 
stats = regionprops(CC, 'BoundingBox'); % [x, y, Breite, Höhe]

% Bildhöhe als Referenz
img_height = size(BW_diff, 1);

% Schleife, die durch alle detektierten Komponenten der bwconncomp Funktion
% iteriert: i = NumObject

for i = 1:length(stats)
    bbox = stats(i).BoundingBox; 
    height = bbox(4); % vierte Komponente ist Höhe
    width = bbox(3);
    % Falls Komponente fast die gesamte Höhe einnimmt --> entfernen
    if height > 0.9 * img_height % ≥ 90% der Bildhöhe
        BW_diff(CC.PixelIdxList{i}) = 0; % alle Pixel des betroffenen Objekts auf 0 setzen
    end
end

% regionprops und bwconncomp, sehr mächtig 
% -->hier wäre es noch möglich nach anderen Objekteigenschaften zu filtern:
% Area, Breite der BoundingBox, etc...

toc
% Canny-Kantendetektion der Shapes (für find_object Funktion)
circle_edge = edge(data.circle, 'Canny');
oval_edge = edge(data.oval, 'Canny');
kidney_edge = edge(data.kidney, 'Canny');
kidney_mod_edge = edge(data.kidney_mod, 'Canny');

% Ausgabe als Struktur speichern
result = struct();
result.BW_bilat = BW_bilat;
result.BW_diff = BW_diff;
result.I_orig = I_orig;
result.case_id = case_id;
result.kidney_edge = kidney_edge;
result.kidney_mod_edge = kidney_mod_edge;
result.circle_edge = circle_edge;
result.oval_edge = oval_edge;
result.mask_cor_r = data.mask_cor_r;
result.mask_cor_l = data.mask_cor_l;

end
