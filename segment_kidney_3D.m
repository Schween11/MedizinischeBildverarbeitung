function mask_kidney_3D = segment_kidney_3D(vol_kidney, im_best, slice_number, YBest, XBest, reference_oval, scale_best, opts)
% 3D-Nierensegmentierung mit Slice-Propagation, Start in ZBest-Slice

% Sicherstellen, dass Eingabe ein Volumen ist
if ndims(vol_kidney) ~= 3
    error('Input must be a 3D volume [H, W, Z]');
end

[H, W, nSlices] = size(vol_kidney);
mask_kidney_3D = false(H, W, nSlices);

% 1. Startsegmentierung
fprintf('Starte 3D-Segmentierung bei Slice %d (ZBest)\n', slice_number);
start_mask = segment_kidney(im_best, YBest, XBest, reference_oval, scale_best, opts);
mask_kidney_3D(:,:,slice_number) = start_mask;

% 2. Nach oben propagieren (z+1 bis z_max)
z_min = 240;
z_max = 326;

for z = slice_number+1:min(nSlices, z_max)
    if z > z_max, break; end
    prev_mask = mask_kidney_3D(:,:,z-1);
    if nnz(prev_mask) == 0, break; end
    im = vol_kidney(:,:,z);
    mask_new = activecontour(im, prev_mask, opts.chanvese_iters_kidney, 'Chan-Vese');
    mask_kidney_3D(:,:,z) = mask_new;
end

% 3. Nach unten propagieren (z–1 bis z_min)
for z = slice_number-1:-1:max(1, z_min)
    if z < z_min, break; end
    prev_mask = mask_kidney_3D(:,:,z+1);
    if nnz(prev_mask) == 0, break; end
    im = vol_kidney(:,:,z);
    mask_new = activecontour(im, prev_mask, opts.chanvese_iters_kidney, 'Chan-Vese');
    mask_kidney_3D(:,:,z) = mask_new;
end

% 4. Löcher füllen
for z = z_min:z_max
    mask_kidney_3D(:,:,z) = imfill(mask_kidney_3D(:,:,z), 'holes');
end

% 5. Nur größte Komponente behalten
CC = bwconncomp(mask_kidney_3D, 26);
numPixels = cellfun(@numel, CC.PixelIdxList);
[~, idx] = max(numPixels);
mask_kidney_3D(:) = false;
mask_kidney_3D(CC.PixelIdxList{idx}) = true;

% --- 6. Visualisierung (Alternative: isosurface) ---
if isfield(opts, 'plotAll') && opts.plotAll
    figure;
    % Isofläche berechnen und darstellen
    p = patch(isosurface(mask_kidney_3D, 0.5));
    isonormals(mask_kidney_3D, p);
    p.FaceColor = 'red';
    p.EdgeColor = 'none';
    daspect([1 1 1]);
    view(3); axis tight;
    camlight; lighting gouraud;
    title(sprintf('3D-Nierensegmentierung – Case %s', opts.case_id));
end
end
