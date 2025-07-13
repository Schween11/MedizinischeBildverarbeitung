case_id = 66;
% Lädt einen Case, führt imdiffusefilt mit 4 Parametern aus
% und für jedes Bild 3 Canny-Threshold-Kombinationen

%% Daten laden
data = loadCaseData_i(case_id);
I = data.slice_cor_interp;

%% Parameter vorbereiten
diff_iters = [2, 5, 10, 15];  % weniger Glättung
canny_params = [              % empfindlichere Kanten
    0.01 0.05;
    0.02 0.08;
    0.03 0.1
];


figure('Name', 'Kantenbilder mit imdiffusefilt + Canny', 'Color', 'w');

plot_idx = 1;

for d = 1:length(diff_iters)
    numIter = diff_iters(d);
    
    % Anwenden von imdiffusefilt
    I_diff = imdiffusefilt(I, 'NumberOfIterations', numIter);
    
    for c = 1:size(canny_params, 1)
        thr = canny_params(c, :);
        BW = edge(I_diff, 'Canny', thr);
        
        subplot(length(diff_iters), size(canny_params,1), plot_idx);
        imshow(BW);
        title(sprintf('iter=%d | [%.2f %.2f]', numIter, thr(1), thr(2)), 'FontSize', 8);
        plot_idx = plot_idx + 1;
    end
end

sgtitle(sprintf('\\bfCase %d – imdiffusefilt + Canny Grid', case_id), 'FontSize', 14);
