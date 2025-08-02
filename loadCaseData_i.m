function data = loadCaseData_i(case_id) 

%% 1. Einlesen der Daten

% Formatierung der Case-ID 
case_str = sprintf('%05d', case_id);

% Excel-Tabelle einlesen
tbl = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
row = tbl{:, 1} == case_id;

% Wichtige Parameter aus Tabelle holen
x_slice_kidney = tbl{row, 9};      % Koronarer X-Schnitt (sagittal)
z_start = tbl{row, 10};            % Start-Z
z_end   = tbl{row, 11};            % End-Z
location_str = string(tbl{row, 12});

% Pfade definieren
base_path = 'allcasesunzipped';
case_path = fullfile(base_path, ['case_' case_str]);
im_path   = fullfile(case_path, 'imaging.nii.gz');
seg_path  = fullfile(case_path, 'segmentation.nii.gz');
shapes_path = 'shapes';

% Referenzformen laden
kidney      = rgb2gray(imread(fullfile(shapes_path, 'KidneyCoronal.png')));
kidney_mod  = rgb2gray(imread(fullfile(shapes_path, 'KidneyCoronal_mod.png')));
oval        = rgb2gray(imread(fullfile(shapes_path, 'Oval.png')));
circle      = rgb2gray(imread(fullfile(shapes_path, 'Circle.png')));
oval_half   = im2gray(imread(fullfile(shapes_path, 'Oval_half.png')));
circle_half   = im2gray(imread(fullfile(shapes_path, 'Circle_half.png')));

% CT-Scan und Maske einlesen (in Form von Nifti-Dateien)
im_vol  = niftiread(im_path);      % Volumen: [Z, X, Y]

seg_vol = niftiread(seg_path) == 1; % Binärmaske
seg_vol_tumor = niftiread(seg_path) == 2;

mask_vol = niftiread(seg_path); % Multilabel-Maske: 0 = Hintergrund, 1 = Niere, 2 = Tumor

% Pixelgrößen aus Nifti-Dateien holen (wichtig für spätere Interpolation)
info = niftiinfo(im_path);
spacing = info.PixelDimensions;  % [Z, X, Y]
pixZ = spacing(1);               % Schichtdicke (oben–unten)
pixX = spacing(2);               % links–rechts
pixY = spacing(3);               % vorne–hinten

%% optional: interaktive Darstellung der Slices
% seg_vol_tum = mask_vol == 1;
% imshow3D(permute(seg_vol_tum, [1 3 2]))

%% 2. Vorverarbeitung der Daten

% Koronalen Schnitt extrahieren (XSlice aus Tabelle)
slice_cor_all  = squeeze(im_vol(:, x_slice_kidney, :));
mask_cor_all  = squeeze(mask_vol(:, x_slice_kidney, :));

% Field-of-View auf Z-Achse beschränken (in Tabelle vorgegeben)
z_fov = z_start:z_end;
im_fov = slice_cor_all(z_fov, :);
mask_fov_all = mask_cor_all(z_fov, :);
im_vol_fov = im_vol(z_fov, :, :);

% Werte normalisieren auf [0,1]
mn = min(im_fov, [], 'all');
mx = max(im_fov, [], 'all');
Im_Norm = (im_fov- mn) ./ (mx - mn);
mn3 = min(im_vol_fov, [], 'all');
mx3 = max(im_vol_fov, [], 'all');
Im_Norm3 = (im_vol_fov- mn3) ./ (mx3 - mn3);

% Auf 1mm-Z-Abstand interpolieren
targetZ = 1; % 1mm Pixelabstand als Ziel
scaling = pixZ / targetZ;
newZ   = round(size(Im_Norm,1) * scaling);

slice_kid_interp = imresize(Im_Norm,[newZ size(Im_Norm,2)] );
mask_kid_interp_1 = imresize(mask_fov_all, [newZ size(mask_fov_all,2)], 'nearest');
im_vol_interp = imresize3(Im_Norm3 , [newZ, size(Im_Norm3, 2), size(Im_Norm3, 3)], 'nearest');

ny3 = size(im_vol_interp, 3);
midY3 = round(ny3 / 2);

im_vol_r = im_vol_interp(:, :, 50:midY3);
im_vol_l = im_vol_interp(:, :, midY3+1:end-50);

% Aufteilung der Maske nach Labels
mask_kid_interp = mask_kid_interp_1 == 1; % Niere
mask_kid_tumor_interp = mask_kid_interp_1 == 2; % Tumor

% Linke und rechte Bildhälfte Y-Dimension in der Mitte splitten (ungefähr Wirbelsäule)
ny = size(slice_kid_interp, 2);
midY = round(ny / 2);

slice_kid_r = slice_kid_interp(:,50:midY);
mask_kid_r = mask_kid_interp(:,50:midY);
mask_kid_tumor_r  = mask_kid_tumor_interp(:, 50:midY);

slice_kid_l = slice_kid_interp(:, midY+1:end-50);
mask_kid_l  = mask_kid_interp(:, midY+1:end-50);
mask_kid_tumor_l  = mask_kid_tumor_interp(:, midY+1:end-50);

%% 3. Selbe Vorverarbeitung für den Slice mit dem größtem Tumorquerschnitt
% evtl. in Funktion Auslagern
% Slice mit größter Tumorfläche suchen
[~, x_slice_tumor] = max(squeeze(sum(sum(mask_vol == 2, 1), 3)));

slice_tum = squeeze(im_vol(:, x_slice_tumor, :));
mask_tum = squeeze(mask_vol(:, x_slice_tumor, :));
slice_tum_fov = slice_tum(z_start:z_end, :);
mask_tum_fov = mask_tum(z_start:z_end, :);
mn_tum = min(slice_tum_fov, [], 'all');
mx_tum = max(slice_tum_fov, [], 'all');
Im_tum_norm = (slice_tum_fov - mn_tum) ./ (mx_tum - mn_tum);
newZ_tum = round(size(Im_tum_norm,1) * scaling);
slice_tum_tumor_interp = imresize(Im_tum_norm, [newZ_tum size(Im_tum_norm,2)]);
mask_tum_tumor_interp = imresize(mask_tum_fov == 2, [newZ_tum size(mask_tum_fov,2)], 'nearest');

% Aufteilung Tumorbild in links/rechts
nz_tum = size(slice_tum_tumor_interp, 2);
midZ_tum = round(nz_tum / 2);

%% 4. Daten als Struktur speichern
data = struct();
data.midZ = midZ_tum;
data.tbl = tbl;
data.row = row;
data.pixX = pixX;
data.pixY = pixY;
data.pixZ = pixZ;
data.location_str = location_str;
data.im_vol_l = im_vol_l;
data.im_vol_r = im_vol_r;

% maximaler Nierenschnitt
data.slice_kid_interp = slice_kid_interp;
data.mask_kid_interp = mask_kid_interp;
data.slice_kid_l = slice_kid_l;
data.mask_kid_l = mask_kid_l;
data.slice_kid_r = slice_kid_r;
data.mask_kid_r = mask_kid_r;
data.x_slice_kidney = x_slice_kidney;
data.mask_kid_tumor_interp = mask_kid_tumor_interp;
data.mask_kid_tumor_l = mask_kid_tumor_l;
data.mask_kid_tumor_r = mask_kid_tumor_r;

% maximaler Tumorschnitt
data.x_slice_tumor = x_slice_tumor;
data.slice_tum_tumor_interp = slice_tum_tumor_interp;
data.mask_tum_tumor_interp = mask_tum_tumor_interp;
data.slice_tum_l = slice_tum_tumor_interp(:, midZ_tum+1:end);
data.mask_tum_l = mask_tum_tumor_interp(:, midZ_tum+1:end);
data.slice_tum_r = slice_tum_tumor_interp(:, 1:midZ_tum);
data.mask_tum_r = mask_tum_tumor_interp(:, 1:midZ_tum);

% Referenzformen (für find_object Funktion)
data.circle = circle;
data.oval = oval;
data.kidney = kidney;
data.kidney_mod = kidney_mod;
data.oval_half = oval_half;
data.circle_half = circle_half;

end