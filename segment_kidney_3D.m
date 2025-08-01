function mask_kidney_3D = segment_kidney_3D(slice_kidney, im_best, slice_number, YBest, X_Best, reference_oval, scale_best, opts)
% 3D-Nierensegmentierung mit Slice-Propagation, Start in ZBest-Slice

% --- Sicherstellen: Volumen ist [H, W, Z] ---
if size(slice_kidney, 2) < size(slice_kidney, 3)
    slice_kidney = permute(slice_kidney, [1 3 2]);  % [H, Z, W] → [H, W, Z]
end

% --- Initialisierung ---
[H, W, nSlices] = size(slice_kidney);
mask_kidney_3D = false(H, W, nSlices);

% --- 1. Startsegmentierung ---
fprintf('Starte 3D-Segmentierung bei Slice %d (ZBest)\n', slice_number);
start_mask = segment_kidney(im_best, YBest, X_Best, reference_oval, scale_best, opts);
mask_kidney_3D(:,:,slice_number) = start_mask;

% --- 2. Nach oben propagieren ---
for z = slice_number+1:nSlices
    prev_mask = mask_kidney_3D(:,:,z-1);
    if nnz(prev_mask) == 0, break; end
    im = slice_kidney(:,:,z);
    mask_new = activecontour(im, prev_mask, opts.chanvese_iters_kidney, 'Chan-Vese');
    mask_kidney_3D(:,:,z) = mask_new;
end

% --- 3. Nach unten propagieren ---
for z = slice_number-1:-1:1
    prev_mask = mask_kidney_3D(:,:,z+1);
    if nnz(prev_mask) == 0, break; end
    im = slice_kidney(:,:,z);
    mask_new = activecontour(im, prev_mask, opts.chanvese_iters_kidney, 'Chan-Vese');
    mask_kidney_3D(:,:,z) = mask_new;
end

% --- 4. Löcher füllen ---
for z = 1:nSlices
    mask_kidney_3D(:,:,z) = imfill(mask_kidney_3D(:,:,z), 'holes');
end

% --- 5. Nur größte Komponente behalten ---
CC = bwconncomp(mask_kidney_3D, 26);
numPixels = cellfun(@numel, CC.PixelIdxList);
[~, idx] = max(numPixels);
mask_kidney_3D(:) = false;
mask_kidney_3D(CC.PixelIdxList{idx}) = true;

% --- 6. Visualisierung ---
if isfield(opts, 'plotAll') && opts.plotAll
    figure;
    vol3d('cdata', double(mask_kidney_3D));
    colormap([0 0 0; 1 0 0]);
    daspect([1 1 1]);
    view(3); axis tight; camlight; lighting gouraud;
    title(sprintf('3D-Nierensegmentierung – Case %s', opts.case_id));
end
end
