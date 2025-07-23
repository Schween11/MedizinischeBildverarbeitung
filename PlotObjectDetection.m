case_id = 66;
data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);
target_canny_diff = result.BW_best;
% target_canny_bilat = result.BW_bilat;
% target_fuzzy_bilat = result.fuzzy_bil_thin;
% target_fuzzy_diff = result.fuzzy_diff_thin;
% reference_circle = result.circle_edge;
reference_oval = result.oval_edge;
reference_kidney = result.kidney_edge;
reference_kidney_mod = result.kidney_mod_edge;


figure;
% Form 1 Kreis nur für tumor
 [target_marked_cd, reference_marked_c,XBest_c ,YBest_c, ~, scale_c, score_c] = find_object(target_canny_diff, reference_circle);
 subplot(2,4,1); imshow(target_marked_cd); title(sprintf('Circle \nScore: %.2f, \nScale: %.2f', score_c, scale_c));
 subplot(2,4,5); imshow(reference_marked_c); title('Ref: Circle');

% Form 2 Kidney
[target_marked_cd, reference_marked_k, XBest_k, YBest_k, ~, scale_k, score_k] = find_object(target_canny_diff, reference_kidney);
subplot(2,3,1); imshow(target_marked_cd); title(sprintf('Kidney \nScore: %.2f, \nScale: %.2f', score_k, scale_k));
subplot(2,3,4); imshow(reference_marked_k); title('Ref: Kidney');

% Form 3 Kidney mod
[target_marked_cd, reference_marked_km, XBest_km, YBest_km, ~, scale_km, score_km] = find_object(target_canny_diff, reference_kidney_mod);
subplot(2,3,2); imshow(target_marked_cd); title(sprintf('Kidney Mod \nScore: %.2f, \nScale: %.2f', score_km, scale_km));
subplot(2,3,5); imshow(reference_marked_km); title('Ref: Kidney Mod');

% Form 4 Oval
[target_marked_cd, reference_marked_o, XBest_o, YBest_o, ~, scale_o, score_o] = find_object(target_canny_diff, reference_oval);
subplot(2,3,3); imshow(target_marked_cd); title(sprintf('Oval \nScore: %.2f, \nScale: %.2f', score_o, scale_o));
subplot(2,3,6); imshow(reference_marked_o); title('Ref: Oval');

% Bester Score bestimmen
[scores, labels] = maxk([score_k, score_km, score_o], 1);
best_label = labels(1);
% XBest/YBest passend auswählen
switch best_label
    case 1  % Kidney
        Xbest = XBest_k; Ybest = YBest_k; scale_best = scale_k;
    case 2  % Kidney Mod
        Xbest = XBest_km; Ybest = YBest_km; scale_best = scale_km;
    case 3  % Oval
        Xbest = XBest_o; Ybest = YBest_o; scale_best = scale_o; 
end
% Gesamt-Titel
sgtitle(sprintf('Beste Matches bei Case %d – Diffusion + Canny\nBester Score bei (%d, %d)', ...
    case_id, Xbest, Ybest), 'FontSize', 14, 'FontWeight', 'bold');
% Figur bleibt aktiv
subplot(2,3,best_label);  % Das Subplot mit dem besten Match aktivieren
hold on;
% Kreuz an (XBest, YBest)
plot(Ybest, Xbest, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
% Optional: kleiner Kreis um die Stelle
viscircles([Ybest, Xbest], 5, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
% Info als Text ins Bild schreiben
text(Ybest + 5, Xbest, sprintf('(%d,%d)', Ybest, Xbest), 'Color', 'red', 'FontWeight', 'bold'); %Y dann X von reihenfolge her
