
% ===== Multiscale-Canny mit höheren Thresholds =====
scales = [0.1 0.3; 0.2 0.4; 0.3 0.6];  % Erfasst größere Kanten
BW_combined = false(size(I_diff));

for i = 1:size(scales, 1)
    th = scales(i, :);
    BW = edge(I_diff, 'Canny', th);
    BW = bwareaopen(BW, 100);  % Kleine Kanten (Rauschen) entfernen
    BW_combined = BW_combined | BW;
end

% ===== Morphologische Operationen (optional) =====
BW_closed = imclose(BW_combined, strel('disk', 5));  % Lücken schließen

% ===== Anzeige =====
figure;
subplot(1,2,1); imshow(BW_combined); title('Multiscale-Canny kombiniert');
subplot(1,2,2); imshow(BW_closed); title('Nach Morphologie');
