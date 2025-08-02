function data = loadCaseData_i(case_id)
%{

BESCHREIBUNG:
Lädt Daten und Segmentierungen und vorverarbeitet diese für eine gegebene Fallnummer

INPUT: 
Fallnummer (case_id) als Zahl (z.B 3, 62, 141)

OUTPUT:
Ein Struct (data) mit vorverarbeiteten Scan und Maskendaten für die
angegebene Fallnummer. Enthält:
%    - Segmentierungen (Niere, Tumor)
%    - interpolierte 2D- und 3D- FOV Bildhälften (links/rechts)
%    - Referenzformen für die GHT
%    - relevante Parameter aus der Patiententabelle und dem Nifti Header
%}

%% 1. Vorbereitung der Daten

case_str = sprintf('%05d', case_id);
tbl = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
row = tbl{:, 1} == case_id;

% Werte aus Tabelle
x_slice_kidney = tbl{row, 9};      % Sagittaler X-Schnitt (für koronale Ansicht)
z_start = tbl{row, 10};            % Start-Z (Slice-Begrenzung unten)
z_end   = tbl{row, 11};            % End-Z (Slice-Begrenzung oben)
location_str = string(tbl{row, 12});

% Pfade definieren
base_path = 'allcasesunzipped';
case_path = fullfile(base_path, ['case_' case_str]);
im_path   = fullfile(case_path, 'imaging.nii.gz');
seg_path  = fullfile(case_path, 'segmentation.nii.gz');
shapes_path = 'shapes';

% Referenzformen laden

% Referenzen für Nierenlokalisation
kidney      = rgb2gray(imread(fullfile(shapes_path, 'KidneyCoronal.png')));
kidney_mod  = rgb2gray(imread(fullfile(shapes_path, 'KidneyCoronal_mod.png')));
oval        = rgb2gray(imread(fullfile(shapes_path, 'Oval.png')));
circle      = rgb2gray(imread(fullfile(shapes_path, 'Circle.png')));

% Referenzen für Tumorlokalisation
oval_half   = im2gray(imread(fullfile(shapes_path, 'Oval_half.png')));
circle_half   = im2gray(imread(fullfile(shapes_path, 'Circle_half.png')));

%% 2. FOV-Extrahierung nur im koronalen Slice

% CT & Segmentierung laden
im_vol = niftiread(im_path);
mask_vol = niftiread(seg_path);

% Nieren-/ Tumormasken
mask_kidney = mask_vol == 1;
mask_tumor  = mask_vol == 2;

% Voxelgröße
info = niftiinfo(im_path);
pixZ = info.PixelDimensions(1);
pixX = info.PixelDimensions(2);
pixY = info.PixelDimensions(3);

% Field-of-View im koronalen X-Slice extrahieren
slice_cor = squeeze(im_vol(:, x_slice_kidney, :));        
mask_cor  = squeeze(mask_vol(:, x_slice_kidney, :));       
z_fov = z_start:z_end;
im_fov = slice_cor(z_fov, :);
mask_fov = mask_cor(z_fov, :);

% Normalisierung
Im_Norm = rescale(im_fov);  % Werte auf [0,1]
scaling = pixZ / 1;         % Ziel: 1 mm Abstand
newZ = round(size(Im_Norm,1) * scaling);

% Interpolation
slice_kid_interp = imresize(Im_Norm, [newZ, size(Im_Norm,2)]);
mask_interp = imresize(mask_fov, [newZ, size(mask_fov,2)], 'nearest');
mask_kid_interp = mask_interp == 1;
mask_tum_interp = mask_interp == 2;

% Rechte und linke Hälften
ny = size(slice_kid_interp, 2);
midY = round(ny / 2);
pad = 50;
slice_kid_r = slice_kid_interp(:, pad:midY);
slice_kid_l = slice_kid_interp(:, midY+1:end-pad);
mask_kid_r  = mask_kid_interp(:, pad:midY);
mask_kid_l  = mask_kid_interp(:, midY+1:end-pad);
mask_tum_r  = mask_tum_interp(:, pad:midY);
mask_tum_l  = mask_tum_interp(:, midY+1:end-pad);

%% 3. Interpolation und FOV des gesamten Volumen für 3D Segmentierung

% FOV in 3D extrahieren
im_vol_fov = im_vol(z_fov, :, :);
mask_kid_3D = mask_kidney(z_fov,:,:);
mask_kid_interp_3D = imresize3(rescale(im_vol_fov), [newZ, size(im_vol_fov, 2), size(im_vol_fov, 3)]);
mask_kid_3D_interp = imresize3(mask_kid_3D, size(mask_kid_interp_3D), 'nearest');

% Rechte/linke Seite (Y-Achse splitten)
ny3 = size(mask_kid_interp_3D, 3);
midY3 = round(ny3 / 2);

%% 4. Tumorschnitt mit größtem Querschnitt interpolieren

[~, x_slice_tumor] = max(squeeze(sum(sum(mask_tumor, 1), 3)));
slice_tum = squeeze(im_vol(:, x_slice_tumor, :));
mask_tum  = squeeze(mask_vol(:, x_slice_tumor, :) == 2);
slice_tum_fov = slice_tum(z_fov, :);
mask_tum_fov = mask_tum(z_fov, :);

% Normalisieren & interpolieren
Im_tum_norm = rescale(slice_tum_fov);
slice_tum_tumor_interp = imresize(Im_tum_norm, [newZ, size(Im_tum_norm,2)]);
mask_tum_tumor_interp  = imresize(mask_tum_fov, [newZ, size(mask_tum_fov,2)], 'nearest');
nz_tum = size(slice_tum_tumor_interp, 2);
midZ_tum = round(nz_tum / 2);

%% 5. Speichern in Datenstruktur

data.tbl = tbl;
data.row = row;
data.pixX = pixX;
data.pixY = pixY;
data.pixZ = pixZ;
data.location_str = location_str;
data.x_slice_kidney = x_slice_kidney;
data.x_slice_tumor = x_slice_tumor;
data.midZ = midZ_tum;

% Referenzformen: 
data.circle = circle;
data.oval = oval;
data.kidney = kidney;
data.kidney_mod = kidney_mod;
data.oval_half = oval_half;
data.circle_half = circle_half;

% FOV - Maximaler Nierenschnitt
data.slice_kid_interp = slice_kid_interp;
data.mask_kid_interp = mask_kid_interp;
data.slice_kid_l = slice_kid_l;
data.slice_kid_r = slice_kid_r;
data.mask_kid_l = mask_kid_l;
data.mask_kid_r = mask_kid_r;
data.mask_kid_tumor_interp = mask_tum_interp;
data.mask_kid_tumor_l = mask_tum_l;
data.mask_kid_tumor_r = mask_tum_r;

% FOV - alle X-Schichten 
data.im_vol_r = mask_kid_interp_3D(:, :, 50:midY3);
data.im_vol_l = mask_kid_interp_3D(:, :, midY3+1:end-50);
data.seg_vol_r = mask_kid_3D_interp(:, :, 50:midY3);
data.seg_vol_l = mask_kid_3D_interp(:, :, midY3+1:end-50);

% Tumorschnitt (links/rechts)
data.slice_tum_tumor_interp = slice_tum_tumor_interp;
data.mask_tum_tumor_interp = mask_tum_tumor_interp;
data.slice_tum_l = slice_tum_tumor_interp(:, midZ_tum+1:end);
data.slice_tum_r = slice_tum_tumor_interp(:, 1:midZ_tum);
data.mask_tum_l = mask_tum_tumor_interp(:, midZ_tum+1:end);
data.mask_tum_r = mask_tum_tumor_interp(:, 1:midZ_tum);


end
