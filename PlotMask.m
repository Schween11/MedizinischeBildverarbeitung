function PlotMask(case_id);
%{

BESCHREIBUNG:
Darstellung des koronalen Schnitts des Slices NiereMax aus der
Patiententabelle. Überlagert mit einer semitransparenten Maske der Niere in
Rot und des Tumors in grün.
Zusätzlich eine Darstellung des koronalen Schnitts mit dem maximalen
Tumorquerschnitts und Überlagerung der Tumormaske in grün.

INPUT: 
Fallnummer (case_id) als Zahl (z.B 3, 62, 141)

OUTPUT:
%  - Interpolierter koronaler Schnitt im Slice NiereMax,
%  - mit Nierenmaske (rot) und Tumormaske (grün).
%  - Linke Bildhälfte desselben Schnitts mit zugehörigen Masken.
%  - Rechte Bildhälfte desselben Schnitts mit zugehörigen Masken.
%  - Separater Schnitt mit maximalem Tumorquerschnitt, ebenfalls mit der Tumormaske überlagert.
%}

%% Aufrufen der vorverarbeiteten Daten im Struct
data = loadCaseData_i(case_id); 

%% Plot
% Nierenschnitt (aus Tabelle)
subplot(2,2,1);
imshow(data.slice_kid_interp); hold on;
redOverlay = cat(3, ones(size(data.mask_kid_interp)), zeros(size(data.mask_kid_interp)), zeros(size(data.mask_kid_interp)));
greenOverlay = cat(3, zeros(size(data.mask_kid_tumor_interp)), ones(size(data.mask_kid_tumor_interp)), zeros(size(data.mask_kid_tumor_interp)));
maske = imshow(redOverlay);
set(maske, 'AlphaData', 0.3 * data.mask_kid_interp);
maske_tum = imshow(greenOverlay);
set(maske_tum, 'AlphaData', 0.3 * data.mask_kid_tumor_interp);
title(sprintf('\\bfNiereMax (X = %d)', data.x_slice_kidney));
axis off;

% Rechte Hälfte (Niere)
subplot(2,2,2);
imshow(data.slice_kid_l); hold on;
redOverlayL = cat(3, ones(size(data.mask_kid_l)), zeros(size(data.mask_kid_l)), zeros(size(data.mask_kid_l)));
greenOverlayL = cat(3, zeros(size(data.mask_kid_tumor_l)), ones(size(data.mask_kid_tumor_l)), zeros(size(data.mask_kid_tumor_l)));
maske_links = imshow(redOverlayL);
set(maske_links, 'AlphaData', 0.3 * data.mask_kid_l);
maske_tum_links = imshow(greenOverlayL);
set(maske_tum_links, 'AlphaData', 0.3 * data.mask_kid_tumor_l);
title('FOV Niere links');
axis off;

% Linke Hälfte (Niere)
subplot(2,2,3);
imshow(data.slice_kid_r); hold on;
redOverlayR = cat(3, ones(size(data.mask_kid_r)), zeros(size(data.mask_kid_r)), zeros(size(data.mask_kid_r)));
greenOverlayR = cat(3, zeros(size(data.mask_kid_tumor_r)), ones(size(data.mask_kid_tumor_r)), zeros(size(data.mask_kid_tumor_r)));
maske_rechts = imshow(redOverlayR);
set(maske_rechts, 'AlphaData', 0.3 * data.mask_kid_r);
maske_tum_rechts = imshow(greenOverlayR);
set(maske_tum_rechts, 'AlphaData', 0.3 * data.mask_kid_tumor_r);
title('\bf FOV Niere rechts');
axis off;

% Tumor-Schnitt separat darstellen
subplot(2,2,4);
imshow(data.slice_tum_tumor_interp); hold on;
greenOverlay = cat(3, zeros(size(data.mask_tum_tumor_interp)), ones(size(data.mask_tum_tumor_interp)), zeros(size(data.mask_tum_tumor_interp)));
tum_overlay = imshow(greenOverlay);
set(tum_overlay, 'AlphaData', 0.3 * data.mask_tum_tumor_interp);
title(sprintf('\\bfTumorMax (X = %d)', data.x_slice_tumor));
axis off;

end