%% Darstellung der drei orthogonalen Schnitte + 2. Axial-Slice
clear
%% 0) Welchen Case willst du anzeigen?
case_id  = 141;                   
case_str = sprintf('%05d', case_id);

%% 1) Excel-Tabelle einlesen und Indizes + Pixel-Dimensionen holen
tbl     = readtable('patients_25.xlsx','VariableNamingRule','preserve');
row     = tbl{:,1} == case_id;

Xslice   = tbl{row, 9};    % sagittaler X-Index ("Niere maximal")
Zslice1  = tbl{row,10};    % axialer Z-Index min
Zslice2  = tbl{row,11};    % axialer Z-Index max
Yslice   = tbl{row, 9};;  % Mittelschnitt in Y

pixZ     = tbl{row,5};     % mm in Z
pixX     = tbl{row,6};     % mm in X
pixY     = tbl{row,7};     % mm in Y

%% 2) Volumina einlesen
base_path = 'allcasesunzipped';
case_path = fullfile(base_path, ['case_' case_str]);
im_path   = fullfile(case_path,'imaging.nii.gz');
seg_path  = fullfile(case_path,'segmentation.nii.gz');

im_vol   = double(niftiread(im_path));    % CT-Volumen [X×Y×Z]
seg_vol  = niftiread(seg_path) > 0;       % Binärmaske

%% 3) Intensitäten normalisieren auf [0,1]
mn    = min(im_vol,[],'all');
mx    = max(im_vol,[],'all');
ImNorm = (im_vol - mn) ./ (mx - mn);

%% 4) 2D-Slices extrahieren
slice_cor = squeeze(ImNorm(:, Yslice, :));      mask_cor  = squeeze(seg_vol(:, Yslice, :));
slice_ax1 = squeeze(ImNorm(:, :, Zslice1));    mask_ax1 = squeeze(seg_vol(:, :, Zslice1));
slice_ax2 = squeeze(ImNorm(:, :, Zslice2));    mask_ax2 = squeeze(seg_vol(:, :, Zslice2));
slice_sag = squeeze(ImNorm(Xslice, :, :));     mask_sag = squeeze(seg_vol(Xslice, :, :));

%% 5) Maximalwerte innerhalb der Niere berechnen
max_cor = max(slice_cor(mask_cor), [], 'all');
max_ax1 = max(slice_ax1(mask_ax1), [], 'all');
max_ax2 = max(slice_ax2(mask_ax2), [], 'all');
max_sag = max(slice_sag(mask_sag), [], 'all');

fprintf('Case %s\n Coronal  Y=%d → Max=%.3f\n Axial Zmin=%d → Max=%.3f\n Axial Zmax=%d → Max=%.3f\n Sag X=%d → Max=%.3f\n', ...
    case_str, Yslice, max_cor, Zslice1, max_ax1, Zslice2, max_ax2, Xslice, max_sag);

%% 6) Darstellung mit physikalischem Seitenverhältnis
figure('Name',['Case ' case_str],'Units','normalized','Position',[.1 .2 .8 .6]);
colormap gray;

% (a) Coronal
R_cor = imref2d(size(slice_cor), pixZ, pixX);
subplot(2,2,1);
imshow(slice_cor, R_cor, [], 'InitialMagnification','fit'); hold on;
h1 = imshow(cat(3,ones(size(mask_cor)),zeros(size(mask_cor)),zeros(size(mask_cor))), R_cor);
set(h1,'AlphaData',0.3*double(mask_cor));
title(sprintf('Coronal (Y=%d)\nNiereMax=%.3f', Yslice, max_cor));
axis off;

% (b) Axial Zmin
R_ax = imref2d(size(slice_ax1), pixY, pixX);
subplot(2,2,2);
imshow(slice_ax1, R_ax, [], 'InitialMagnification','fit'); hold on;
h2 = imshow(cat(3,ones(size(mask_ax1)),zeros(size(mask_ax1)),zeros(size(mask_ax1))), R_ax);
set(h2,'AlphaData',0.3*double(mask_ax1));
title(sprintf('Axial (Z=%d)\nNiereMax=%.3f', Zslice1, max_ax1));
axis off;

% (c) Axial Zmax
subplot(2,2,3);
imshow(slice_ax2, R_ax, [], 'InitialMagnification','fit'); hold on;
h3 = imshow(cat(3,ones(size(mask_ax2)),zeros(size(mask_ax2)),zeros(size(mask_ax2))), R_ax);
set(h3,'AlphaData',0.3*double(mask_ax2));
title(sprintf('Axial (Z=%d)\nNiereMax=%.3f', Zslice2, max_ax2));
axis off;

% (d) Sagittal
R_sag = imref2d(size(slice_sag), pixZ, pixY);
subplot(2,2,4);
imshow(slice_sag, R_sag, [], 'InitialMagnification','fit'); hold on;
h4 = imshow(cat(3,ones(size(mask_sag)),zeros(size(mask_sag)),zeros(size(mask_sag))), R_sag);
set(h4,'AlphaData',0.3*double(mask_sag));
title(sprintf('Sagittal (X=%d)\nNiereMax=%.3f', Xslice, max_sag));
axis off;

hold off;
