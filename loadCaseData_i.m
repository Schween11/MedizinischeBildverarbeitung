function data = loadCaseData_i(case_id)

% === Formatierung der Case-ID ===
case_str = sprintf('%05d', case_id);

% === Excel-Tabelle einlesen ===
tbl = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
row = tbl{:, 1} == case_id;

% === Wichtige Parameter aus Tabelle holen ===
Xslice = tbl{row, 9};              % Koronarer X-Schnitt (sagittal)
z_start = tbl{row, 10};            % Start-Z
z_end   = tbl{row, 11};            % End-Z
location_str = string(tbl{row, 12});

% === Pfade vorbereiten ===
base_path = 'allcasesunzipped';
case_path = fullfile(base_path, ['case_' case_str]);
im_path   = fullfile(case_path, 'imaging.nii.gz');
seg_path  = fullfile(case_path, 'segmentation.nii.gz');
shapes_path = 'shapes';

% === Referenzformen laden ===
kidney      = rgb2gray(imread(fullfile(shapes_path, 'KidneyCoronal.png')));
kidney_mod  = rgb2gray(imread(fullfile(shapes_path, 'KidneyCoronal_mod.png')));
oval        = rgb2gray(imread(fullfile(shapes_path, 'Oval.png')));
circle      = rgb2gray(imread(fullfile(shapes_path, 'Circle.png')));

% === CT-Scan und Maske einlesen ===
im_vol  = niftiread(im_path);      % Volumen: [Z, X, Y]
seg_vol = niftiread(seg_path) > 0; % Binärmaske

% === Pixelgrößen aus NIfTI-Header holen ===
info = niftiinfo(im_path);
spacing = info.PixelDimensions;  % [Z, X, Y]
pixZ = spacing(1);               % Schichtdicke (oben–unten)
pixX = spacing(2);               % links–rechts
pixY = spacing(3);               % vorne–hinten

% === Field-of-View auf Z-Achse beschränken ===
z_fov = z_start:z_end;
im_fov = im_vol(z_fov, :, :);
seg_fov = seg_vol(z_fov, :, :);

% === Intensitäten normalisieren auf [0,1] ===
mn = min(im_fov, [], 'all');
mx = max(im_fov, [], 'all');
ImNorm = (im_fov - mn) ./ (mx - mn);

% === Koronalen Schnitt extrahieren ===
slice_cor = squeeze(ImNorm(:, Xslice, :));     % [Z, Y]
mask_cor  = squeeze(seg_fov(:, Xslice, :));    % [Z, Y]

% === Linke und rechte Bildhälfte (Y-Dimension splitten) ===
nz = size(slice_cor, 2);
midZ = round(nz / 2);

slice_cor_l = slice_cor(:, 1:midZ);
mask_cor_l  = mask_cor(:, 1:midZ);

slice_cor_r = slice_cor(:, midZ+1:end);
mask_cor_r  = mask_cor(:, midZ+1:end);

% ===  Auf 1mm-Z-Spacing interpolieren ===
targetZ = 1.0;
if abs(pixZ - targetZ) > 0.01
    scaleFactor = pixZ / targetZ;
    slice_cor   = imresize(slice_cor, [round(size(slice_cor,1) * scaleFactor), size(slice_cor,2)], 'bicubic');
    mask_cor    = imresize(mask_cor,  [round(size(mask_cor,1)  * scaleFactor), size(mask_cor,2)], 'nearest');

    slice_cor_l = imresize(slice_cor_l, [round(size(slice_cor_l,1) * scaleFactor), size(slice_cor_l,2)], 'bicubic');
    mask_cor_l  = imresize(mask_cor_l,  [round(size(mask_cor_l,1)  * scaleFactor), size(mask_cor_l,2)], 'nearest');

    slice_cor_r = imresize(slice_cor_r, [round(size(slice_cor_r,1) * scaleFactor), size(slice_cor_r,2)], 'bicubic');
    mask_cor_r  = imresize(mask_cor_r,  [round(size(mask_cor_r,1)  * scaleFactor), size(mask_cor_r,2)], 'nearest');

    pixZ = targetZ; % Nach der Interpolation ist Z-Spaced 1 mm
end

% === Datenstruktur ausgeben ===
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

% Referenzformen
data.circle = circle;
data.oval = oval;
data.kidney = kidney;
data.kidney_mod = kidney_mod;

end
