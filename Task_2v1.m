%% Darstellung der drei orthogonalen Schnitte + 2. Axial-Slice
clear
%% 0) Case-ID einlesen
case_id  = 141;                   
case_str = sprintf('%05d', case_id);

%% 1) Excel-Tabelle einlesen und Indizes + Pixel-Dimensionen holen
tbl     = readtable('patients_25.xlsx','VariableNamingRule','preserve'); % Übernahme der Tabelle mit Originalnamen
row     = tbl{:,1} == case_id; % erste Spalte (Case-Indizes)

Xslice   = tbl{row, 9};    % sagittaler X-Index ("Niere maximal")

pixZ     = tbl{row,5};     % mm in Z
pixX     = tbl{row,6};     % mm in X
pixY     = tbl{row,7};     % mm in Y

% auch über niftiinfo(im_path) oder niftiinfo(seg_path) möglich

%% 2) CT-Scan und Maske einlesen 
base_path = 'allcasesunzipped';
case_path = fullfile(base_path, ['case_' case_str]);
im_path   = fullfile(case_path,'imaging.nii.gz'); % Path zum CT-Scan
seg_path  = fullfile(case_path,'segmentation.nii.gz'); % Path zur Maske 

im_vol   = niftiread(im_path);    % Einlesen des CT-Scans (nxnxn double Matrix)
im_fov   = im_vol(:, :, tbl{row,10}:tbl{row,11});
seg_vol  = niftiread(seg_path) > 0;   % Binärmaske
seg_fov  = seg_vol(:, :,  tbl{row,10}:tbl{row,11});
midZ = round(size(im_vol, 3) / 2);  % Mitte des Volumens in Z
im_fov_l = im_vol(:, :,tbl{row,10}:midZ);  im_fov_r = im_vol(:, :,midZ:tbl{row,11}); 
seg_fov_l = seg_vol(:, :,tbl{row,10}:midZ);  seg_fov_r = seg_vol(:, :, midZ:tbl{row,11}); 

%% 3) Intensitäten normalisieren auf [0,1]
mn    = min(im_fov,[],'all');
mx    = max(im_fov,[],'all');
ImNorm = (im_fov - mn) ./ (mx - mn);

% Maske muss nicht normalisiert werden, da es sich um eine Binärmaske
% handelt 

%% 4) 2D-Slices extrahieren (identisch für Scan und Maske)
slice_cor = squeeze(ImNorm(:, Xslice, :));      mask_cor  = squeeze(seg_fov(:, Xslice, :)); % koronaler Schnitt

% Z-Hälfte bestimmen
nz = size(slice_cor, 2);
midZ = round(nz / 2);

% Linke und rechte Hälfte extrahieren
slice_cor_l = slice_cor(:, 1:midZ);
mask_cor_l  = mask_cor(:, 1:midZ);

slice_cor_r = slice_cor(:, midZ+1:end);
mask_cor_r  = mask_cor(:, midZ+1:end);


%% 5) Maximalwerte innerhalb der Niere berechnen
max_cor = max(slice_cor(mask_cor), [], 'all');

%% 6) Darstellung mit physikalischem Seitenverhältnis (erweitert mit links/rechts)
figure('Name', ['Case ' case_str], 'Units','normalized','Position',[0.1 0.1 0.8 0.8]);
colormap gray;

% === (a) Coronar-Schnitt ===
R_cor = imref2d(size(slice_cor), pixZ, pixY);
R_cor_l = imref2d(size(slice_cor_l), pixZ, pixX);
R_cor_r = imref2d(size(slice_cor_r), pixZ, pixX);

subplot(2,2,1);
imshow(slice_cor, R_cor, [], 'InitialMagnification', 'fit'); hold on;
redOverlay = cat(3, ones(size(mask_cor)), zeros(size(mask_cor)), zeros(size(mask_cor)));
h1 = imshow(redOverlay, R_cor);
set(h1, 'AlphaData', 0.3 * double(mask_cor));
title(sprintf('\\bfCoronar (X = %d), max = %.3f', Xslice, max_cor));
axis off;

% Darstellung
figure('Name', ['Case ' case_str ' - Koronarschnitt halbiert']);
colormap gray;

% Linke Hälfte
subplot(1,2,1);
imshow(slice_cor_l, R_cor_l, [], 'InitialMagnification','fit'); hold on;
hL = imshow(cat(3, ones(size(mask_cor_l)), zeros(size(mask_cor_l)), zeros(size(mask_cor_l))), R_cor_l);
set(hL, 'AlphaData', 0.3 * double(mask_cor_l));
title('\bfLinke Hälfte (Z-min bis Mitte)');
axis off;

% Rechte Hälfte
subplot(1,2,2);
imshow(slice_cor_r, R_cor_r, [], 'InitialMagnification','fit'); hold on;
hR = imshow(cat(3, ones(size(mask_cor_r)), zeros(size(mask_cor_r)), zeros(size(mask_cor_r))), R_cor_r);
set(hR, 'AlphaData', 0.3 * double(mask_cor_r));
title('\bfRechte Hälfte (Mitte bis Z-max)');
axis off;
