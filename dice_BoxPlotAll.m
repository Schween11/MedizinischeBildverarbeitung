% === Excel einlesen ===
patients = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
valid_rows = strcmp(patients{:,8}, 'Y');
case_ids = patients{valid_rows, 1};
num_cases = numel(case_ids);

% === Ergebnis-Vektor initialisieren ===
dice_side = nan(num_cases, 1);

% === Dice-Koeffizient-Funktion ===
compute_dice = @(A,B) 2 * nnz(A & B) / (nnz(A) + nnz(B));

% === Seite wählen: 'r' für rechts oder 'l' für links ===
side = 'r';  % ⇐ hier ändern für linke Seite

% === Hauptschleife über alle validen Fälle ===
for idx = 1:num_cases
    case_id = case_ids(idx);

    try
        % Segmentierung durchführen
        [mask3D, ~, ~, ~] = PlotSegmentation3D(case_id, side, false);
        data = loadCaseData_i(case_id);

        % Ground-Truth Maske laden
        if side == 'r'
            GT = permute(data.seg_vol_r, [1 3 2]);
        else
            GT = permute(data.seg_vol_l, [1 3 2]);
        end

        % Dice-Koeffizient berechnen
        dice_side(idx) = compute_dice(GT, mask3D);

    catch ME
        fprintf("⚠️ Fehler bei Case %d: %s\n", case_id, ME.message);
        continue
    end
end

% === Nur gültige Werte (ohne NaN) verwenden
valid_idx = ~isnan(dice_side);
dice_side = dice_side(valid_idx);

% === Boxplot zeichnen
figure('Color','w');
boxplot(dice_side);
ylabel('Dice-Koeffizient');

% Titel je nach Seite setzen
if side == 'r'
    title('Nierensegmentierung – Dice (rechte Niere)');
else
    title('Nierensegmentierung – Dice (linke Niere)');
end

ylim([0.4 1]);  % optionaler Bereich

% === Optional: Punkte zusätzlich einzeichnen
hold on;
scatter(ones(size(dice_side)), dice_side, 'k', 'filled', ...
    'jitter','on', 'jitterAmount', 0.1);
hold off;

% === Zusammenfassung in der Konsole
if side == 'r'
    fprintf('⦿ Rechte Niere:\n');
else
    fprintf('⦿ Linke Niere:\n');
end
fprintf('   Mittelwert = %.3f\n', mean(dice_side));
fprintf('   Standardabweichung = %.3f\n', std(dice_side));
