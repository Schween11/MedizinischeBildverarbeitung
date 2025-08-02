function PlotEdgeDetection(case_id);
%{
BESCHREIBUNG:
Führt die Kantenextraktion zur Nierenlokalisation mit der Funktion EdgeDetection aus
und visualisiert die Ergebnisse für beide Seiten mit einem Vergleich der Masken.

INPUT:
Fallnummer (case_id) als Zahl (z.B 3, 62, 141)

OUTPUT:
Erzeugt eine 2×3-Figur mit:
- rechter und linker Slice (Niere) mit extrahierten Kanten
- Kantenbild der interpolierten Nierenmaske
%}

result = EdgeDetection(case_id);

% Plot-Vergleich für beide Seiten: rechts (r) und links (l)
figure;

% Rechter Slice – Nierenkante
subplot(2,3,1);
imshow(result.BW_best_r);
title('rechts: Diffusion + Canny');

% Linker Slice – Nierenkante
subplot(2,3,2);
imshow(result.BW_best_l);
title('links: Diffusion + Canny');

% Maske Kantenbild – Vergleichsbild
subplot(2,3,4);
imshow(result.mask_edge);
title('Maske Niere');

end