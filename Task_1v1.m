%% Darstellung der drei orthogonalen Schnitte + 2. Axial-Slice
clear
%% 0) Case-ID einlesen
case_id  = 63;                   
case_str = sprintf('%05d', case_id);

%% 1) Excel-Tabelle einlesen und Indizes + Pixel-Dimensionen holen
tbl     = readtable('patients_25.xlsx','VariableNamingRule','preserve'); % Übernahme der Tabelle mit Originalnamen
row     = tbl{:,1} == case_id; % erste Spalte (Case-Indizes)

Xslice   = tbl{row, 9};    % sagittaler X-Index ("Niere maximal")
Zslice1  = tbl{row,10};    % axialer Z-Index min
Zslice2  = tbl{row,11};    % axialer Z-Index max

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
seg_vol  = niftiread(seg_path) > 0;       % Binärmaske

zSums = squeeze(sum(sum(seg_vol, 1), 2));
[~, maxZ] = max(zSums);

%% 3) Intensitäten normalisieren auf [0,1]
mn    = min(im_vol,[],'all');
mx    = max(im_vol,[],'all');
ImNorm = (im_vol - mn) ./ (mx - mn);

% Maske muss nicht normalisiert werden, da es sich um eine Binärmaske
% handelt 

%% 4) 2D-Slices extrahieren (identisch für Scan und Maske)
slice_cor = squeeze(ImNorm(:, Xslice, :));      mask_cor  = squeeze(seg_vol(:, Xslice, :)); % koronaler Schnitt
sliceaxmax = squeeze(ImNorm(:, :, maxZ));    mask_axmax = squeeze(seg_vol(:, :, maxZ)); % axialer Schnitt

%% 5) Maximalwerte innerhalb der Niere berechnen
max_cor = max(slice_cor(mask_cor), [], 'all');

%% 6) Darstellung mit physikalischem Seitenverhältnis
figure('Name',['Case ' case_str],'Units','normalized','Position',[.1 .2 .8 .6]);
colormap gray;

% (a) Coronar
R_cor = imref2d(size(slice_cor), pixZ, pixX);
subplot(2,1,1);
imshow(slice_cor, R_cor, [], 'InitialMagnification','fit'); hold on;
h1 = imshow(cat(3,ones(size(mask_cor)),zeros(size(mask_cor)),zeros(size(mask_cor))), R_cor);
set(h1,'AlphaData',0.3*double(mask_cor));
title(sprintf('Coronar (X=%d)', Xslice, max_cor));
axis off;

% (b) Axial bei größter Nierenfläche
R_axmax = imref2d(size(sliceaxmax), pixY, pixX);
subplot(2,1,2);
imshow(sliceaxmax, R_axmax, [], 'InitialMagnification','fit'); hold on;
h4 = imshow(cat(3,ones(size(mask_axmax)),zeros(size(mask_axmax)),zeros(size(mask_axmax))), R_axmax);
set(h4,'AlphaData',0.3*double(mask_axmax));
title(sprintf('AxMax (Z=%d)',maxZ));
axis off;

hold off;
