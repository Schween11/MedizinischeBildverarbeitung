function canny_edge_detection(case_id)

%% Case Auswahl mit get_case Funktion 
get_case(case_id)
tbl = readtable('patients_25.xlsx','VariableNamingRule','preserve');
row     = tbl{:,1} == case_id; % erste Spalte (Case-Indizes)


%% Auswahl der pathologische Seite 
location_str = string(tbl{row,12});
first_word = extractBefore(location_str, ',');

if first_word == "rechts"
    I_orig = slice_cor_r;
else 
    I_orig = slice_cor_l;
end

%% Vorverarbeitungsschritte 

% Parameter für Canny und Diffusionsfilter
nmb_it = 30;
grd_thr = 10;
low_thr = 0.2;
high_thr = 0.4;

I_diff = imdiffusefilt(I_orig, 'NumberOfIterations', nmb_it, 'GradientThreshold', grd_thr);

BW_diff = edge(I_diff, 'Canny',  low_thr, high_thr);
BW_diff = bwareaopen(BW_diff, 100);

imshow(BW_diff)

target = BW_diff;
shapes_path = 'shapes';
kidney_path = fullfile(shapes_path,'KidneyCoronal_mod.png');
reference = imread(kidney_path);       % z. B. uint8 RGB
reference = rgb2gray(reference);   % Konvertiere zu Graustufen
reference = edge(reference, 'Canny');
imshow(reference)
end