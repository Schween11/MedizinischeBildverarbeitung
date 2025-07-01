case_id = 33;
data = loadCaseData_i(case_id);

subplot(2,2,1);
imshow(data.slice_cor); hold on;
redOverlay = cat(3, ones(size(data.mask_cor)), zeros(size(data.mask_cor)), zeros(size(data.mask_cor)));
greenOverlay = cat(3, zeros(size(data.mask_cor_tumor)), ones(size(data.mask_cor_tumor)), zeros(size(data.mask_cor_tumor)));
maske = imshow(redOverlay);
set(maske, 'AlphaData', 0.3 * data.mask_cor);
maske_tum = imshow(greenOverlay);
set(maske_tum, 'AlphaData', 0.3 * data.mask_cor_tumor);
title(sprintf('\\bfCoronar (X = %d)', data.Xslice));
axis off;

subplot(2,2,3);
imshow(data.slice_cor_l); hold on;
redOverlayL = cat(3, ones(size(data.mask_cor_l)), zeros(size(data.mask_cor_l)), zeros(size(data.mask_cor_l)));
%greenOverlayL = cat(3, zeros(size(data.mask_cor_tumor_l)), ones(size(data.mask_cor_tumor_l)), zeros(size(data.mask_cor_tumor_l)));
maske_links = imshow(redOverlayL);
set(maske_links, 'AlphaData', 0.3 * data.mask_cor_l);
title('\bfRechte Hälfte (Z-min bis Mitte)');
axis off;

subplot(2,2,4);
imshow(data.slice_cor_r); hold on;
redOverlayR = cat(3, ones(size(data.mask_cor_r)), zeros(size(data.mask_cor_r)), zeros(size(data.mask_cor_r)));
greenOverlayR = cat(3, zeros(size(data.mask_cor_tumor_r)), ones(size(data.mask_cor_tumor_r)), zeros(size(data.mask_cor_tumor_r)));
maske_rechts = imshow(redOverlayR);
set(maske_rechts, 'AlphaData', 0.3 * data.mask_cor_r);
title('\bfLinke Hälfte (Mitte bis Z-max)');
axis off;
