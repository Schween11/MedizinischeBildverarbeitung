 % === Excel einlesen ===
patients = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
valid_rows = strcmp(patients{:,8}, 'Y');
case_ids = patients{valid_rows, 1};
num_cases = numel(case_ids);

% === Ergebnis-Vektor initialisieren ===
dice_side = nan(num_cases, 1);
case_id_valid = nan(num_cases, 1);
num_failed = 0;

% === Dice-Koeffizient-Funktion ===
compute_dice = @(A,B) 2 * nnz(A & B) / (nnz(A) + nnz(B));

% === Seite wählen: 'r' für rechts oder 'l' für links ===
side = 'l';  % ⇐ hier ändern für linke Seite

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
        dice = compute_dice(GT, mask3D);
        dice_side(idx) = dice;
        case_id_valid(idx) = case_id;

    catch ME
        fprintf("⚠️ Fehler bei Case %d: %s\n", case_id, ME.message);
        num_failed = num_failed + 1;
        continue
    end
end

% === Nur gültige Werte (ohne NaN) verwenden
valid_idx = ~isnan(dice_side);
dice_side = dice_side(valid_idx);
case_id_valid = case_id_valid(valid_idx);

% === Case mit schlechtem und bestem Dice identifizieren
[~, worst_idx] = find(dice_side < 0.75);
[~, best_idx] = max(dice_side);

% === Boxplot zeichnen
figure('Color','w');
boxplot(dice_side);
ylabel('Dice-Koeffizient');

% Titel je nach Seite setzen
if side == 'r'
    title(sprintf('Nierensegmentierung – Dice (rechte Niere)\nFehlgeschlagene Fälle: %d', num_failed));
else
    title(sprintf('Nierensegmentierung – Dice (linke Niere)\nFehlgeschlagene Fälle: %d', num_failed));
end

ylim([0.4 1]); 

% === Punkte zusätzlich einzeichnen
hold on;
scatter(ones(size(dice_side)), dice_side, 'k', 'filled', ...
    'jitter','on', 'jitterAmount', 0.1);

% === Fälle mit Dice < 0.75 markieren
for i = 1:numel(worst_idx)
    idx = worst_idx(i);
    text(1.05, dice_side(idx), sprintf('%d', case_id_valid(idx)), ...
        'Color', 'r', 'FontWeight', 'bold', 'FontSize', 9);
end

% === Besten Fall markieren
text(1.05, dice_side(best_idx), sprintf('%d ⬆️', case_id_valid(best_idx)), ...
    'Color', 'g', 'FontWeight', 'bold', 'FontSize', 10);

hold off;

% === Zusammenfassung in der Konsole
if side == 'r'
    fprintf('⦿ Rechte Niere:\n');
else
    fprintf('⦿ Linke Niere:\n');
end
fprintf('   Mittelwert = %.3f\n', mean(dice_side));
fprintf('   Standardabweichung = %.3f\n', std(dice_side));
fprintf('   Fehlgeschlagene Fälle = %d von %d\n', num_failed, num_cases);
