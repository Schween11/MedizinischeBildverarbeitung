% === Einstellungen ===
excel_path = 'patients_25.xlsx';  % <-- Excel-Datei mit Case-IDs

% === Daten aus Excel einlesen und aus caseData laden ===
patients = readtable(excel_path);
valid_rows = strcmp(patients{:,8}, 'Y');
case_ids = patients{valid_rows, 1};

% === Initialisierung ===
num_cases = length(case_ids);
ref_names = {'circle', 'oval', 'kidney', 'kidney_mod'};

best_targets = cell(num_cases, 1);
best_refs = cell(num_cases, 1);
titles = cell(num_cases, 1);

% === Hauptschleife über alle Cases ===
for idx = 1:num_cases
    case_id = case_ids(idx);

    try
        % --- Lade Bilddaten ---
        result = EdgeDetection(case_id);
        target = result.BW_diff;

        % --- Lade Referenzformen ---
        references = struct( ...
            'circle', result.circle_edge, ...
            'oval', result.oval_edge, ...
            'kidney', result.kidney_edge, ...
            'kidney_mod', result.kidney_mod_edge ...
        );

        % --- Bester Treffer bestimmen ---
        best_score = 0;
        best_target = [];
        best_ref = [];
        best_form = '';

        for r = 1:length(ref_names)
            name = ref_names{r};
            ref_img = references.(name);

            [t_marked, ~, ~, ~, ~, ~, score] = find_object(target, ref_img);

            if score > best_score
                best_score = score;
                best_target = t_marked;
                best_form = name;
            end
        end

        % --- Speichern ---
        best_targets{idx} = best_target;
        best_refs{idx} = best_ref;
        titles{idx} = sprintf('Case %d – %s (Score: %.2f)', case_id, best_form, best_score);

    catch ME
        warning('Fehler bei Case %d: %s', case_id, ME.message);
        best_targets{idx} = [];
        best_refs{idx} = [];
        titles{idx} = sprintf('Case %d – Fehler', case_id);
    end
end

% === Ergebnisse anzeigen ===
figure;
cols = 5;
rows = ceil(num_cases / cols);

for i = 1:num_cases
    if isempty(best_targets{i}), continue; end

    % Target-Bild
    subplot(rows, cols, i);
    imshow(best_targets{i});
    title(titles{i}, 'FontSize', 8);

end

sgtitle('Beste Matches je Case – target\_canny\_diff', 'FontSize', 14, 'FontWeight', 'bold');
