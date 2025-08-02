function PlotObjectDetection(case_id)

%{
BESCHREIBUNG:
Visualisiert die Ergebnisse der Kantendetektion mithilfe der GHT für beide Nierenhälften eines
gegebenen Falls. Es werden jeweils drei Referenzformen (Kidney, Kidney Mod,
Oval) mit den Kantenbildern verglichen.

INPUT:
Fallnummer (case_id) als Zahl (z.B 3, 62, 141)

OUTPUT:
Zeigt eine Abbildung mit 12 Subplots:
   - obere Reihe: Kantenbilder mit Overlay der Nierenlokalisation mit GHT
   mit score und scaling
    - untere Reihe: zugehörige Kantenbilder der Referenzen
    - Markierung des besten Treffers mit einem roten Kreuz und einem Kreis
%}

%% Einlesen der nötigen Daten
data = loadCaseData_i(case_id);
result = EdgeDetection(case_id);

% Zielkantenbilder (Target)
target_edges = {result.BW_best_l, result.BW_best_r};
target_labels = {'links', 'rechts'};

% Referenzen
references = {
    result.kidney_edge, 'Kidney';
    result.kidney_mod_edge, 'Kidney Mod';
    result.oval_edge, "Oval"};

% Ergebnisse speichern
Xbest_all = zeros(1,2);
Ybest_all = zeros(1,2);
best_label_all = zeros(1,2);
scale_best_all = zeros(1,2);
score_best_all = zeros(1,2);

figure;

for side = 1:2  % 1 = links, 2 = rechts
    target = target_edges{side};
    
    scores = zeros(1,3);
    scales = zeros(1,3);
    Xbests = zeros(1,3);
    Ybests = zeros(1,3);
    target_marked_all = cell(1,3);
    reference_marked_all = cell(1,3);

    % Vergleiche alle Referenzen
    for i = 1:3
        ref = references{i,1};
        [t_marked, r_marked, X, Y, ~, scale, score] = find_object(target, ref);

        scores(i) = score;
        scales(i) = scale;
        Xbests(i) = X;
        Ybests(i) = Y;
        target_marked_all{i} = t_marked;
        reference_marked_all{i} = r_marked;

        % Subplots: Zeile 1 = Target, Zeile 2 = Reference
        subplot(2, 6, i + (side-1)*3);
        imshow(t_marked);
        title(sprintf('%s: %s\nScore: %.2f, Scale: %.2f', ...
            target_labels{side}, references{i,2}, score, scale));

        subplot(2, 6, i + 6 + (side-1)*3);
        imshow(r_marked);
        title(sprintf('Ref: %s', references{i,2}));
    end

    % Bester Treffer ermitteln
    [~, best_label] = max(scores);
    best_label_all(side) = best_label;
    Xbest_all(side) = Xbests(best_label);
    Ybest_all(side) = Ybests(best_label);
    scale_best_all(side) = scales(best_label);
    score_best_all(side) = scores(best_label);

    % Markierung im besten Target-Bild
    subplot(2, 6, best_label + (side-1)*3);
    hold on;
    plot(Ybests(best_label), Xbests(best_label), 'rx', 'MarkerSize', 12, 'LineWidth', 2);
    viscircles([Ybests(best_label), Xbests(best_label)], 5, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
    text(Ybests(best_label)+5, Xbests(best_label), ...
        sprintf('(%d,%d)', Ybests(best_label), Xbests(best_label)), ...
        'Color', 'red', 'FontWeight', 'bold');
end

% Gesamttitel
sgtitle(sprintf('Case %d: GHT-basierter Vergleich für links und rechts', case_id), ...
    'FontSize', 14, 'FontWeight', 'bold');

end