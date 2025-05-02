% Zugriff auf die Dateien
folderName = "case_00071" ;  % Name des Cases (Unterordner)
filePath = fullfile(folderName, "imaging.nii.gz");  % Pfad zur imaging-Datei
Nii = niftiread(filePath);  % NIfTI-Datei einlesen

Max = max(Nii,[],"all"); % Maximum der gesamten Datei 
Min = min(Nii,[],"all"); % Minimum der gesamten Datei

Va_normal = (Nii - Min)./(Max - Min); % elementweise Normalisierung der Werte
dim = size(Va_normal); % Dimension des Volumens

% 2D - Visualisierung 

midSliceX = round(dim(1)/2); % Mittelschnitt X 
midSliceY = round(dim(2)/2); % Mittelschnitt Y
midSliceZ = round(dim(3)/2); % Mittelschnitt Z

seitlich = Va_normal(:,:,midSliceZ); % Frontansicht, fixes Z
frontal = Va_normal(:,midSliceY,:);% "von unten", fixes Y
unten = Va_normal(midSliceX,:,:); % "von der Seite", fixes X

unten2D = squeeze(axial (unten)); 
seitlich2D = squeeze(sagittal (seitlich));
frontal2D = squeeze(koronar ());

figure;

subplot(1,3,1);
imshow(frontal2D);
title('Frontal');

subplot(1,3,2);
imshow(unten2D);
title('Unten');

subplot(1,3,3);
imshow(seitlich2D);
title('Seitlich');

%volshow (Va_a); % 3D- Visualisierung
%new
%testtest