% Zugriff auf die Nifti-Dateien

CaseID = 66; % CaseID manuell angeben
table = readtable("patients_25.xlsx"); % Laden der Excel-Datei
RowIndex = CaseID == table{:,1}; % gibt Zeilenindex des passenden Cases wider
allCases = "allcasesunzipped"; % Ordner, der die CaseFiles enthält
CaseFile = sprintf("case_%05d", CaseID);  % Name des Case-Ordners (fünf Stellen mit führenden Nullen vor CaseNumber")
PathImag = fullfile(allCases, CaseFile, "imaging.nii.gz");  % Pfad zur imaging-Datei
PathMask = fullfile(allCases, CaseFile, "segmentation.nii.gz");  % Pfad zur imaging-Datei
NiiImage = niftiread(PathImag);  % Einlesen der Imaging-Datei
NiiIMask = niftiread(PathMask);  % Einlesen der Maske

info = niftiinfo(imaging.nii.gz)

Max = max(NiiImage,[],"all"); % Maximum der gesamten Datei 
Min = min(NiiImage,[],"all"); % Minimum der gesamten Datei

Image_normal = (NiiImage - Min)./(Max - Min); % elementweise Normalisierung der Werte
dim = size(Va_normal); % Dimension des Volumens

% 2D - Visualisierung 

dimX = dim(1); % Anzahl der Voxel in x-Richtung
dimY = dim(2); % Anzahl der Voxel in y-Richtung
dimZ = dim(3); % Anzahl der Voxel in z-Richtung
midSliceX = round(dimX/2); % Mittelschnitt X 
midSliceY = round(dimY/2); % Mittelschnitt Y
midSliceZ = round(dimZ/2); % Mittelschnitt Z

sagittal = Va_normal(:,:,midSliceZ); % sagittal "links und rechts" , fixes Z
koronal = Va_normal(:,midSliceY,:);% "koronal "vorne und hinten", fixes Y
axial = Va_normal(midSliceX,:,:); % axial "oben und unten", fixes X

unten2D = squeeze(axial); 
seitlich2D = squeeze(sagittal);
frontal2D = squeeze(koronal); % Entfernen der überflüssigen Dimension um zweidimensionale Matrix zu erzeugen

%figure; %Plot

subplot(1,3,1);
imshow(frontal2D);
title('Koronal');

subplot(1,3,2);
imshow(unten2D);
title('Axial');

subplot(1,3,3);
imshow(seitlich2D);
title('Sagittal');

% 3D- Visualisierung
%volshow (Image_normal);
