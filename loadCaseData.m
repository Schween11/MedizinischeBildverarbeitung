
%% Task 1 + 2: Einlesen der Nifti Dateien und Anzeigen des Koronalschnittes mit Maske


%% 1) Excel-Tabelle einlesen und Indizes + Pixel-Dimensionen holen
function data = loadCaseData(case_id);

case_str = sprintf('%05d', case_id);
tbl     = readtable('patients_25.xlsx','VariableNamingRule','preserve'); % Übernahme der Tabelle mit Originalnamen
row     = tbl{:,1} == case_id; % erste Spalte (Case-Indizes)

Xslice   = tbl{row, 9};    % sagittaler X-Index ("Niere maximal")

%% 2) CT-Scan und Maske einlesen sowie shapes 
base_path = 'allcasesunzipped';
case_path = fullfile(base_path, ['case_' case_str]);
im_path   = fullfile(case_path,'imaging.nii.gz'); % Path zum CT-Scan
seg_path  = fullfile(case_path,'segmentation.nii.gz'); % Path zur Maske 
shapes_path = 'shapes';
kidney_path_mod = fullfile(shapes_path,'KidneyCoronal_mod.png');
kidney_path = fullfile(shapes_path,'KidneyCoronal.png');
circle_path = fullfile(shapes_path,'Circle.png');
oval_path = fullfile(shapes_path,'Oval.png');

im_vol   = niftiread(im_path);    % Einlesen des CT-Scans (nxnxn double Matrix)
seg_vol  = niftiread(seg_path) > 0;   % Binärmaske
kidney = rgb2gray(imread(kidney_path));
kidney_mod = rgb2gray(imread(kidney_path_mod));
oval = rgb2gray(imread(oval_path));
circle = rgb2gray(imread(circle_path));

midZ = round(size(im_vol, 1) / 2);  % Mitte des Volumens in Z

z_fov = tbl{row,10}:tbl{row,11};
z_fov_r = tbl{row,10}:midZ;
z_fov_l =midZ:tbl{row,11};

im_fov   = im_vol(z_fov, :, :);
seg_fov  = seg_vol(z_fov, :, :);


im_fov_r = im_vol(:, :,z_fov_r);  im_fov_l = im_vol(:, :,z_fov_l); 
seg_fov_r = seg_vol(:, :,z_fov_r);  seg_fov_l = seg_vol(:, :, z_fov_l); 

%% 3) Intensitäten normalisieren auf [0,1] und Pixelgrößen
mn    = min(im_fov,[],'all');
mx    = max(im_fov,[],'all');
ImNorm = (im_fov - mn) ./ (mx - mn);
% Maske muss nicht normalisiert werden, da es sich um eine Binärmaske
% handelt 

info = niftiinfo(im_path);
spacing = info.PixelDimensions; % [pixX, pixY, pixZ]
pixX = spacing(1); % links-rechts (Sagittal)
pixY = spacing(2); % vorne-hinten (Coronar)
pixZ = spacing(3); % oben-unten (Axial)

%% 4) 2D-Slices extrahieren (identisch für Scan und Maske)
slice_cor = squeeze(ImNorm(:, Xslice, :));      mask_cor  = squeeze(seg_fov(:, Xslice, :)); % koronaler Schnitt

% Z-Hälfte bestimmen
nz = size(slice_cor, 2);
midZ = round(nz / 2);

% Linke und rechte Hälfte extrahieren
slice_cor_l = slice_cor(:, 1:midZ);
mask_cor_l  = mask_cor(:, 1:midZ);

slice_cor_r = slice_cor(:, midZ:end);
mask_cor_r  = mask_cor(:, midZ:end);

% Daten als Struktur ausgeben
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
data.location_str = string(tbl{row,12});
data.circle = circle;
data.oval = oval;
data.kidney = kidney;
data.kidney_mod = kidney_mod;

end



