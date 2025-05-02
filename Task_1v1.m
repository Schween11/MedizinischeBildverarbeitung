% Zugriff auf die Nifti-Dateien

CaseID = 66; % CaseID manuell angeben

allCases = "allcasesunzipped"; % Ordner, der die CaseFiles enthält
CaseFile = sprintf("case_%05d", CaseID);  % Pfad des Case-Ordners (fünf Stellen mit führenden Nullen vor CaseNumber")
PathImag = fullfile(allCases, CaseFile, "imaging.nii.gz");  % Pfad zur imaging-Datei
PathMask = fullfile(allCases, CaseFile, "segmentation.nii.gz");  % Pfad zur segmanting-Datei
NiiImage = niftiread(PathImag);  % Einlesen der Imaging-Datei
NiiIMask = niftiread(PathMask);  % Einlesen der segmanting-Datei

% Vorbereitung der Daten
table = readtable("patients_25.xlsx"); % Laden der Excel-Datei
RowIndex = CaseID == table{:,1}; % gibt Zeilenindex des passenden Cases wider

% Speichern der Daten die nur über Excel-Tabelle verfügbar sind
Xslice = table{RowIndex, 9};  % Spalte I = 9
Zslice_min = table{RowIndex, 10};  % Spalte J = 10
Zslice_max = table{RowIndex, 11};  % Spalte K = 11
% wo wird der Y-Schnitt gesetzt?
InfoImag = niftiinfo(PathImag); % Eigenschaften der Nifti-Datei
VoxelSize = InfoImag.PixelDimensions; % Voxel Dimensionen als 1x3 Vektor

Max = max(NiiImage,[],"all"); % Maximum der gesamten Datei 
Min = min(NiiImage,[],"all"); % Minimum der gesamten Datei
Image_normal = (NiiImage - Min)./(Max - Min); % elementweise Normalisierung der Werte
dim = size(Image_normal); % Dimension des Volumens

% 2D - Visualisierung 

dimX = dim(1); % Anzahl der Voxel in x-Richtung
dimY = dim(2); % Anzahl der Voxel in y-Richtung
dimZ = dim(3); % Anzahl der Voxel in z-Richtung
midSliceX = round(dimX/2); % Mittelschnitt X 
midSliceY = round(dimY/2); % Mittelschnitt Y
midSliceZ = round(dimZ/2); % Mittelschnitt Z

sagittal = Image_normal(:,:,midSliceZ); % sagittal "links und rechts" , fixes Z
koronal = Image_normal(:,midSliceY,:);% "koronal "vorne und hinten", fixes Y
axial = Image_normal(midSliceX,:,:); % axial "oben und unten", fixes X

unten2D = squeeze(axial); 
seitlich2D = squeeze(sagittal);
frontal2D = squeeze(koronal); % Entfernen der überflüssigen Dimension um zweidimensionale Matrix zu erzeugen

%figure; %Plot

subplot(1,3,1);
imshow(frontal2D);
title('Koronar');

subplot(1,3,2);
imshow(unten2D);
title('Axial');

subplot(1,3,3);
imshow(seitlich2D);
title('Sagittal');

% 3D- Visualisierung
%volshow (Image_normal);
