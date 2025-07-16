tic
case_id = 183;
data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);

target_canny_diff = result.BW_best;
% target_canny_bilat = result.BW_bilat;
% target_fuzzy_bilat = result.fuzzy_bil_thin;
% target_fuzzy_diff = result.fuzzy_diff_thin;

reference_circle = result.circle_edge;
reference_oval = result.oval_edge;
reference_kidney = result.kidney_edge;
reference_kidney_mod = result.kidney_mod_edge;



figure;

% Form 1
[target_marked_c, reference_marked_c, ~, ~, ~, scale_c, score_c] = find_DTobject(target_canny_diff, reference_circle);
subplot(2,4,1); imshow(target_marked_c); title(sprintf('Circle \nScore: %.2f, \nScale: %.2f', score_c, scale_c));
subplot(2,4,5); imshow(reference_marked_c); title('Ref: Circle');

% Form 2
[target_marked_k, reference_marked_k, XBest,YBest, scale_k, score_k] = find_DTobject(target_canny_diff, reference_kidney);
subplot(2,4,2); imshow(target_marked_k); title(sprintf('Kidney \nScore: %.2f, \nScale: %.2f', score_k, scale_k));
subplot(2,4,6); imshow(reference_marked_k); title('Ref: Kidney');

% Form 3 
[target_marked_km, reference_marked_km, ~, ~, ~, scale_km, score_km] = find_DTobject(target_canny_diff, reference_kidney_mod);
subplot(2,4,3); imshow(target_marked_km); title(sprintf('Kidney Mod \nScore: %.2f, \nScale: %.2f', score_km, scale_km));
subplot(2,4,7); imshow(reference_marked_km); title('Ref: Kidney Mod');

% Form 4
[target_marked_o, reference_marked_o, ~, ~, ~, scale_o, score_o] = find_object(target_canny_diff, reference_oval);
subplot(2,4,4); imshow(target_marked_o); title(sprintf('Oval \nScore: %.2f, \nScale: %.2f', score_o, scale_o));
subplot(2,4,8); imshow(reference_marked_o); title('Ref: Oval');


sgtitle(sprintf('Beste Matches bei Case  %d  – Diffusion + Canny', case_id), 'FontSize', 14, 'FontWeight', 'bold');
toc