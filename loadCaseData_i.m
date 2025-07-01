%% Funktionsdefiniton mit Case-ID als Input (2 bis 3 Ziffern)

function data = loadCaseData_i(case_id) 

%% Einlesen der Daten

% Formatierung der Case-ID 
case_str = sprintf('%05d', case_id);

% Excel-Tabelle einlesen
tbl = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
row = tbl{:, 1} == case_id;

% Wichtige Parameter aus Tabelle holen
Xslice = tbl{row, 9};              % Koronarer X-Schnitt (sagittal)
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


% CT-Scan und Maske einlesen (in Form von Nifti-Dateien)
im_vol  = niftiread(im_path);      % Volumen: [Z, X, Y]
seg_vol = niftiread(seg_path) > 0; % Binärmaske
seg_vol_tumor = niftiread(seg_path) > 1.5;

% Pixelgrößen aus Nifti-Dateien holen (wichtig für spätere Interpolation)
info = niftiinfo(im_path);
spacing = info.PixelDimensions;  % [Z, X, Y]
pixZ = spacing(1);               % Schichtdicke (oben–unten)
pixX = spacing(2);               % links–rechts
pixY = spacing(3);               % vorne–hinten

%% Vorverarbeitung der Daten 
% Field-of-View auf Z-Achse beschränken (in Tabelle vorgegeben)
z_fov = z_start:z_end;
im_fov = im_vol(z_fov, :, :);
seg_fov = seg_vol(z_fov, :, :);
seg_fov_tumor = seg_vol_tumor(z_fov, :, :);

% Werte normalisieren auf [0,1]
mn = min(im_fov, [], 'all');
mx = max(im_fov, [], 'all');
ImNorm = (im_fov - mn) ./ (mx - mn);

% Koronalen Schnitt extrahieren (XSlice aus Tabelle)
slice_cor = squeeze(ImNorm(:, Xslice, :));    
mask_cor  = squeeze(seg_fov(:, Xslice, :)); 
mask_cor_tumor = squeeze(seg_fov_tumor(:, Xslice, :));

% Auf 1mm-Z-Abstand interpolieren
targetZ = 1; % 1mm Pixelabstand als Ziel
scaling = pixZ / targetZ;
newZ   = round(size(slice_cor,1) * scaling);

slice_cor_interp = imresize(slice_cor,[newZ size(slice_cor,2)] );
mask_cor_interp = imresize(mask_cor, [newZ size(mask_cor,2)] ); %Interpolation mit imresize Funktion. Zeile auf mit Skalierungsfaktor skaliert. Spalte bleibt gleich groß.
mask_cor_tumor_interp = imresize(mask_cor_tumor, [newZ size(mask_cor,2)] ); 

% Linke und rechte Bildhälfte Y-Dimension in der Mitte splitten (ungefähr
% Wirbelsäule
nz = size(slice_cor, 2);
midZ = round(nz / 2);

slice_cor_l = slice_cor_interp(:, 1:midZ);
mask_cor_l  = mask_cor_interp(:, 1:midZ);
mask_cor_tumor_l  = mask_cor_tumor_interp(:, 1:midZ);

slice_cor_r = slice_cor_interp(:, midZ+1:end);
mask_cor_r  = mask_cor_interp(:, midZ+1:end);
mask_cor_tumor_r  = mask_cor_tumor_interp(:, 1:midZ);

%% Daten als Struktur speichern
data = struct();
data.tbl = tbl;
data.row = row;
data.slice_cor = slice_cor;
data.mask_cor = mask_cor;
data.slice_cor_l = slice_cor_l;
data.mask_cor_l = mask_cor_l;
data.slice_cor_r = slice_cor_r;
data.mask_cor_r = mask_cor_r;
data.Xslice = Xslice;
data.pixX = pixX;
data.pixY = pixY;
data.pixZ = pixZ;
data.location_str = location_str;
data.mask_cor_tumor = mask_cor_tumor;
data.mask_cor_tumor_l = mask_cor_tumor_l;
data.mask_cor_tumor_r = mask_cor_tumor_r;

% Referenzformen (für find_object Funktion)
data.circle = circle;
data.oval = oval;
data.kidney = kidney;
data.kidney_mod = kidney_mod;

end
