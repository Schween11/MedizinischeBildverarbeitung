case_id = 33;
data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);

reference_circle = result.circle_edge;
target_kid = result.BW_best;
[target_marked_cd, reference_marked_c, YBest, XBest, ang, scale_c, score_c] = find_object(target_kid, reference_circle);

target_tum = data.slice_tum_r; 

[y_size, x_size] = size(target);
y_half = 80;
x_half = 60; % halbe Pixelgröße der ROI

x_min = max(XBest - x_half, 1);
x_max = min(XBest + x_half, x_size);

y_min = max(YBest - y_half, 1);
y_max = min(YBest + y_half, y_size);

roi = target_tum(y_min:y_max,x_min:x_max);

roi_norm = mat2gray(roi);
imshow(roi_norm)
%I_cont = adapthisteq(roi_norm, 'NumTiles', [8 8], 'ClipLimit', 0.005);
%imshow(I_cont);


roi_diff = imdiffusefilt(roi_norm ,"GradientThreshold",5,"NumberOfIterations",5);
roi_edge = edge(roi_diff,"Canny",0.4,0.8);




% Originalbild (z. B. ROI oder I_cont) vorausgesetzt
I = roi;

% Canny-Parameterpaare: [low high]
canny_params = [
    0.1 0.2;
    0.2 0.4;
    0.3 0.6;
    0.4 0.8;
    0.5 0.9
];

% Diffusionsparameter
gradient_thresholds = [2, 4, 6];

figure;
plot_idx = 1;

% 1) Nur Canny (ohne Diffusion)
for i = 1:size(canny_params,1)
    low = canny_params(i,1);
    high = canny_params(i,2);
    roi_edge = edge(I, "Canny", [low high]);
    
    subplot(4,5,plot_idx);
    imshow(roi_edge);
    title(sprintf("Canny only\n[%.1f %.1f]", low, high));
    plot_idx = plot_idx + 1;
end

% 2) Canny nach imdiffusefilt mit 3 verschiedenen Thresholds
for g = 1:length(gradient_thresholds)
    grad_thresh = gradient_thresholds(g);
    roi_diff = imdiffusefilt(I, "GradientThreshold", grad_thresh, "NumberOfIterations", 5);

    for i = 1:size(canny_params,1)
        low = canny_params(i,1);
        high = canny_params(i,2);
        roi_edge = edge(roi_diff, "Canny", [low high]);

        subplot(4,5,plot_idx);
        imshow(roi_edge);
        title(sprintf("Diff %.0f + Canny\n[%.1f %.1f]", grad_thresh, low, high));
        plot_idx = plot_idx + 1;
    end
end

sgtitle('Kombination Canny + Diffusion');
