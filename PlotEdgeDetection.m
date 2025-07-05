case_id = 52;
result = EdgeDetection(case_id);

%% Vergleich anzeigen
figure;
subplot(2,2,1); imshow(result.BW_bilat); title('Bilateral + Canny');
subplot(2,2,2); imshow(result.BW_diff); title('Diffusion + Canny'); 
subplot(2,2,3); imshow(result.mask_cor_r); title('Maske rechts')
subplot(2,2,4); imshow(result.mask_cor_l); title('Maske links')


