case_id = 71;
tic
result = EdgeDetection(case_id);

%% Vergleich anzeigen
figure;
subplot(2,2,1); imshow(result.BW_best); title('Diffusion + Canny'); 
subplot(2,2,3); imshow(result.mask_edge); title('Kantenbild MAske ')
subplot(2,2,4); imshow(result.mask_tum_edge); title('Lantenbild Tumor')

toc