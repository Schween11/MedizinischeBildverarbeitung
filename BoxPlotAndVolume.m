function BoxPlotAndVolume(side)

% BESCHREIBUNG: Auswertung der 3D-Nierensegmentierung
%
% Führt Segmentierung über alle gültigen Fälle durch (aus patients_25.xlsx),
% berechnet Mittelwert der Dice-Koeffizienten und Volumina (ml) mit
% Standardabweichung
% und erstellt einen Boxplot des Dice-koeffizienten.
%
% INPUT:
%   side:  'l' für linke Niere, 'r' für rechte Niere
%
% OUTPUT:
% BoxPlot aller gültigen Fälle und das Volumen

% === Excel einlesen ===
patients = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
valid_rows = strcmp(patients{:,8}, 'Y');
case_ids = patients{valid_rows, 1};
num_cases = numel(case_ids);

% === Ergebnis-Vektoren initialisieren ===
dice_side = nan(num_cases, 1);
case_id_valid = nan(num_cases, 1);
vol_GT_all = nan(num_cases, 1);      % in ml
vol_seg_all = nan(num_cases, 1);     % in ml
num_failed = 0;

% === Dice-Koeffizient-Funktion ===
compute_dice = @(A,B) 2 * nnz(A & B) / (nnz(A) + nnz(B));

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

        % Dice berechnen
        dice = compute_dice(GT, mask3D);
        dice_side(idx) = dice;
        case_id_valid(idx) = case_id;

        % Volumen berechnen mit externer Funktion
        vol_GT_all(idx)  = volume_ml(GT,     data.pixX, data.pixY, 1.0);
        vol_seg_all(idx) = volume_ml(mask3D, data.pixX, data.pixY, 1.0); % da eingangs Z auf 1.0 interpoliert

        % Volumen 
        fprintf('Case %3d | Dice: %.3f | GT: %.1f ml | Segmentiert: %.1f ml\n', ...
            case_id, dice, vol_GT_all(idx), vol_seg_all(idx));

    catch ME
        fprintf("⚠️ Fehler bei Case %d: %s\n", case_id, ME.message);
        num_failed = num_failed + 1;
        continue
    end
end

% === Gültige Fälle extrahieren
valid_idx = ~isnan(dice_side);
dice_side = dice_side(valid_idx);
case_id_valid = case_id_valid(valid_idx);
vol_GT_all = vol_GT_all(valid_idx);
vol_seg_all = vol_seg_all(valid_idx);

% === Ausreißer und bester Fall
worst_idx = find(dice_side < 0.75);
[~, best_idx] = max(dice_side);

% === Boxplot erzeugen
figure('Color','w');
boxplot(dice_side);
ylabel('Dice-Koeffizient');

if side == 'r'
    title(sprintf('Nierensegmentierung – Dice (rechte Niere)\nFehlgeschlagene Fälle: %d', num_failed));
else
    title(sprintf('Nierensegmentierung – Dice (linke Niere)\nFehlgeschlagene Fälle: %d', num_failed));
end
ylim([0.4 1]);

% Punkte hinzufügen
hold on;
scatter(ones(size(dice_side)), dice_side, 'k', 'filled', ...
    'jitter','on', 'jitterAmount', 0.1);

% Ausreißer beschriften
for i = 1:numel(worst_idx)
    idx = worst_idx(i);
    text(1.05, dice_side(idx), sprintf('%d', case_id_valid(idx)), ...
        'Color', 'r', 'FontWeight', 'bold', 'FontSize', 9);
end

% Besten Fall markieren
text(1.05, dice_side(best_idx), sprintf('%d ⬆️', case_id_valid(best_idx)), ...
    'Color', 'g', 'FontWeight', 'bold', 'FontSize', 10);

hold off;

% Zusammenfassung
fprintf('\n=== Zusammenfassung (%s) ===\n', side);
fprintf('⦿ Mittelwert Dice:     %.3f\n', mean(dice_side));
fprintf('⦿ Standardabweichung:  %.3f\n', std(dice_side));
fprintf('⦿ Fehlgeschlagene Fälle: %d von %d\n', num_failed, num_cases);

% === Volumen-Statistiken ausgeben ===
vol_diff = abs(vol_GT_all - vol_seg_all);

fprintf('\n=== Volumenstatistik (in ml) ===\n');
fprintf('⦿ GT Volumen:     Mittelwert = %.2f ml, Std = %.2f ml\n', mean(vol_GT_all), std(vol_GT_all));
fprintf('⦿ Segmentierung:  Mittelwert = %.2f ml, Std = %.2f ml\n', mean(vol_seg_all), std(vol_seg_all));
fprintf('⦿ Abweichung:     Mittelwert = %.2f ml, Std = %.2f ml\n', mean(vol_diff), std(vol_diff));

end
