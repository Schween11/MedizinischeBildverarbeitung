function mask_kidney_3D = segment_kidney_3D(vol_kidney, im_best, slice_number, YBest, XBest, reference_oval, scale_best, opts)
%{
BESCHREIBUNG: Führt eine 3D-Segmentierung der Niere durch, ausgehend vom Slice
mit größtem Querschnitt. Die Startmaske wird über Chan-Vese auf benachbarte
Slices übertragen. Die ROI darf anfangs wachsen, wird später beschränkt, um
Störstrukturen einzuschränken.
Nur größte 3D-Komponente bleibt erhalten. 
Optional kann die segmentierte Maske visualisiert werden

INPUT:
   - vol_kidney:    3D-Graubild (CT-Scan mit angepasster FOV)
   - im_best:       Start-Slice zur Segmentierung (NiereMax Slice aus Tabelle)
   - slice_number:  Z-Index des Start-Slices (aus Tabelle)
   - YBest, XBest:  Zentrum der Niere mit GHT 
   - reference_oval: Referenzform zur ROI-Berechnung 
   - scale_best:    Skalierung der Referenzform
   - opts:          Struktur mit Parametern für kMeans und Chan Vese

OUTPUT:
   - mask_kidney_3D: Segmentierte 3D-Maske der Niere (mit angepasster FOV)
%}

if ndims(vol_kidney) ~= 3
    error('Input must be a 3D volume [H, W, Z]');
end

[H, W, nSlices] = size(vol_kidney);
mask_kidney_3D = false(H, W, nSlices);

% 1. Startsegmentierung
fprintf('Starte 3D-Segmentierung bei Slice %d (XSlice größter Nierenquerschnitt)\n', slice_number);
start_mask = segment_kidney(im_best, YBest, XBest, reference_oval, scale_best, opts);
mask_kidney_3D(:,:,slice_number) = start_mask;

% Referenzfläche für Flächenprüfung
area_ref = nnz(start_mask);
max_area = 1.5 * area_ref;
min_area = 0.05 * area_ref;

% Initiale ROI aus start_mask
stats = regionprops(start_mask, 'BoundingBox');
bb = stats(1).BoundingBox;
x1_roi = max(1, round(bb(1)) - 10);
y1_roi = max(1, round(bb(2)) - 10);
x2_roi = min(W, round(bb(1) + bb(3)) + 10);
y2_roi = min(H, round(bb(2) + bb(4)) + 10);

% Slice-Range: manuelle Grenzen
z_min = slice_number - 100;
z_max = slice_number + 100;

% Anzahl Slices mit erlaubtem Wachstum: wichtig um ROI später einzugrenzen
N_free_growth = 10;



% Nach oben propagieren

for z = slice_number+1:min(nSlices, z_max)
    prev_mask = mask_kidney_3D(:,:,z-1);
    if nnz(prev_mask) == 0, break; end

    im = vol_kidney(:,:,z);
    mask_new = activecontour(im, prev_mask, opts.chanvese_iters_kidney, 'Chan-Vese');

    % Dynamische ROI 
    stats = regionprops(prev_mask, 'BoundingBox');
    if isempty(stats), break; end
    bb_new = stats(1).BoundingBox;
    x1_new = max(1, round(bb_new(1)) - 10);
    y1_new = max(1, round(bb_new(2)) - 10);
    x2_new = min(W, round(bb_new(1) + bb_new(3)) + 10);
    y2_new = min(H, round(bb_new(2) + bb_new(4)) + 10);

    if z - slice_number <= N_free_growth
        x1_roi = x1_new; y1_roi = y1_new;
        x2_roi = x2_new; y2_roi = y2_new;
    else
        % nach 10 Iterationen nur noch schrumpfende ROI erlaubt: -->
        % Störstrukturen v.a. nach unten unterdrücken
        if x1_new >= x1_roi && y1_new >= y1_roi && x2_new <= x2_roi && y2_new <= y2_roi
            x1_roi = x1_new; y1_roi = y1_new;
            x2_roi = x2_new; y2_roi = y2_new;
        end
    end

    roi_mask = false(H, W);
    roi_mask(y1_roi:y2_roi, x1_roi:x2_roi) = true;
    mask_new(~roi_mask) = false;

    % Beenden bei zu kleiner/ großer Fläche
    area = nnz(mask_new);
    if area < min_area || area > max_area
        fprintf('Beendet bei Slice %d (oben): Maskengröße %d außerhalb von [%d, %d]\n', ...
            z, area, round(min_area), round(max_area));
        break;
    end

    mask_kidney_3D(:,:,z) = mask_new;
end


% Nach unten propagieren --> wie oben

% Reset ROI
x1_roi = max(1, round(bb(1)) - 10);
y1_roi = max(1, round(bb(2)) - 10);
x2_roi = min(W, round(bb(1) + bb(3)) + 10);
y2_roi = min(H, round(bb(2) + bb(4)) + 10);

for z = slice_number-1:-1:max(1, z_min)
    prev_mask = mask_kidney_3D(:,:,z+1);
    if nnz(prev_mask) == 0, break; end

    im = vol_kidney(:,:,z);
    mask_new = activecontour(im, prev_mask, opts.chanvese_iters_kidney, 'Chan-Vese');

    stats = regionprops(prev_mask, 'BoundingBox');
    if isempty(stats), break; end
    bb_new = stats(1).BoundingBox;
    x1_new = max(1, round(bb_new(1)) - 10);
    y1_new = max(1, round(bb_new(2)) - 10);
    x2_new = min(W, round(bb_new(1) + bb_new(3)) + 10);
    y2_new = min(H, round(bb_new(2) + bb_new(4)) + 10);

    if slice_number - z <= N_free_growth
        x1_roi = x1_new; y1_roi = y1_new;
        x2_roi = x2_new; y2_roi = y2_new;
    else
        if x1_new >= x1_roi && y1_new >= y1_roi && x2_new <= x2_roi && y2_new <= y2_roi
            x1_roi = x1_new; y1_roi = y1_new;
            x2_roi = x2_new; y2_roi = y2_new;
        end
    end

    roi_mask = false(H, W);
    roi_mask(y1_roi:y2_roi, x1_roi:x2_roi) = true;
    mask_new(~roi_mask) = false;

    area = nnz(mask_new);
    if area < min_area || area > max_area
        fprintf('Abbruch bei Slice %d (unten): Maskengröße %d außerhalb von [%d, %d]\n', ...
            z, area, round(min_area), round(max_area));
        break;
    end

    mask_kidney_3D(:,:,z) = mask_new;
end

% 4. Löcher füllen
for z = max(1, z_min):min(nSlices, z_max)
    mask_kidney_3D(:,:,z) = imfill(mask_kidney_3D(:,:,z), 'holes');
end

% 5. Nur größte Komponente behalten
CC = bwconncomp(mask_kidney_3D, 26);
numPixels = cellfun(@numel, CC.PixelIdxList);
[~, idx] = max(numPixels);
mask_kidney_3D(:) = false;
mask_kidney_3D(CC.PixelIdxList{idx}) = true;

% 6. Visualisierung
if isfield(opts, 'plotAll') && opts.plotAll
    figure;
    p = patch(isosurface(mask_kidney_3D, 0.5));
    isonormals(mask_kidney_3D, p);
    p.FaceColor = 'red';
    p.EdgeColor = 'none';
    daspect([1 1 1]);
    view(3); axis tight;
    camlight; lighting gouraud;
    title(sprintf('3D-Nierensegmentierung – Case %r', opts.case_id));
end
end
