case_id = 63;
data = loadCaseData(case_id);
result = EdgeDetection(case_id);

target_canny_diff = result.BW_diff;
target_canny_bilat = result.BW_bilat;
target_fuzzy_bilat = result.fuzzy_bil_thin;
target_fuzzy_diff = result.fuzzy_diff_thin;

reference_circle = result.circle_edge;
reference_oval = result.oval_edge;
reference_kidney = result.kidney_edge;
reference_kidney_mod = result.kidney_mod_edge;



figure;

% 1 – Bilateral + Canny
[target_marked_cb, reference_marked_c, ~, ~, ~, ~, ~] = find_object(target_canny_bilat, reference_circle);
subplot(2,4,1); imshow(target_marked_cb); title('Target: Bilateral + Canny');
subplot(2,4,5); imshow(reference_marked_c); title('Ref: Circle');

% 2 – Diffusion + Canny
[target_marked_cd, reference_marked_k, ~, ~, ~, ~, ~] = find_object(target_canny_diff, reference_kidney);
subplot(2,4,2); imshow(target_marked_cd); title('Target: Diffusion + Canny');
subplot(2,4,6); imshow(reference_marked_k); title('Ref: Kidney');

% 3 – Bilateral + Fuzzy
[target_marked_fb, reference_marked_km, ~, ~, ~, ~, ~] = find_object(target_fuzzy_bilat, reference_kidney_mod);
subplot(2,4,3); imshow(target_marked_fb); title('Target: Bilateral + Fuzzy');
subplot(2,4,7); imshow(reference_marked_km); title('Ref: Kidney Mod');

% 4 – Diffusion + Fuzzy
[target_marked_fd, reference_marked_o, ~, ~, ~, ~, ~] = find_object(target_fuzzy_diff, reference_oval);
subplot(2,4,4); imshow(target_marked_fd); title('Target: Diffusion + Fuzzy');
subplot(2,4,8); imshow(reference_marked_o); title('Ref: Oval');
