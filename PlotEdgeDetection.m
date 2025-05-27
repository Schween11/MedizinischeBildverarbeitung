case_id = 63;
result = EdgeDetection(case_id);

%% Vergleich anzeigen
figure;
subplot(2,2,1); imshow(result.BW_bilat); title('Bilateral + Canny');
subplot(2,2,2); imshow(result.BW_diff); title('Diffusion + Canny'); 
subplot(2,2,3); imshow(result.fuzzy_bil_thin); title('Bilateral + Fuzzy');
subplot(2,2,4); imshow(result.fuzzy_diff_thin); title('Diffusion + Fuzzy');

target = result.BW_diff;
shapes_path = 'shapes';
kidney_path = fullfile(shapes_path,'KidneyCoronal_mod.png');
reference = imread(kidney_path);       % z. B. uint8 RGB
reference = rgb2gray(reference);   % Konvertiere zu Graustufen
reference = edge(reference, 'Canny');
imshow(reference)


