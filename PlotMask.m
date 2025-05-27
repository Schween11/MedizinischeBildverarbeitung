case_id = 63;
data = loadCaseData(case_id);

R_cor    = imref2d(size(data.slice_cor),    data.pixZ, data.pixY);
R_cor_l  = imref2d(size(data.slice_cor_l),  data.pixZ, data.pixY);
R_cor_r  = imref2d(size(data.slice_cor_r),  data.pixZ, data.pixY);

subplot(2,2,1);
imshow(data.slice_cor, R_cor, [], 'InitialMagnification', 'fit'); hold on;
redOverlay = cat(3, ones(size(data.mask_cor)), zeros(size(data.mask_cor)), zeros(size(data.mask_cor)));
h1 = imshow(redOverlay, R_cor);
set(h1, 'AlphaData', 0.3 * double(data.mask_cor));
title(sprintf('\\bfCoronar (X = %d)', data.Xslice));
axis off;

subplot(2,2,3);
imshow(data.slice_cor_l, R_cor_l, [], 'InitialMagnification','fit'); hold on;
redOverlayL = cat(3, ones(size(data.mask_cor_l)), zeros(size(data.mask_cor_l)), zeros(size(data.mask_cor_l)));
hL = imshow(redOverlayL, R_cor_l);
set(hL, 'AlphaData', 0.3 * double(data.mask_cor_l));
title('\bfRechte Hälfte (Z-min bis Mitte)');
axis off;

subplot(2,2,4);
imshow(data.slice_cor_r, R_cor_r, [], 'InitialMagnification','fit'); hold on;
redOverlayR = cat(3, ones(size(data.mask_cor_r)), zeros(size(data.mask_cor_r)), zeros(size(data.mask_cor_r)));
hR = imshow(redOverlayR, R_cor_r);
set(hR, 'AlphaData', 0.3 * double(data.mask_cor_r));
title('\bfLinke Hälfte (Mitte bis Z-max)');
axis off;
