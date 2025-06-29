case_id = 52;
result = EdgeDetection(case_id);

%% Vergleich anzeigen
figure;
subplot(2,3,1); imshow(result.BW_bilat); title('Bilateral + Canny');
subplot(2,3,2); imshow(result.BW_diff); title('Diffusion + Canny'); 
subplot(2,3,3); imshow(result.fuzzy_bil_thin); title('Bilateral + Fuzzy');
subplot(2,3,4); imshow(result.fuzzy_diff_thin); title('Diffusion + Fuzzy');
subplot(2,3,5); imshow(result.mask_cor_r); title('Maske rechts')
subplot(2,3,6); imshow(result.mask_cor_l); title('Maske links')


