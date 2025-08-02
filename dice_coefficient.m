function dice = dice_coefficient(A, B, showVis)
%{
BESCHREIBUNG: 
Kann erst nach Durchführung von PlotSegmentation durchgeführt werden
Berechnet den Dice-Koeffizienten zweier 3D-Masken und visualisiert die Schnittflächen
 
INPUT: 
- Ground Truth Maske (A) - data.seg_vol_r bzw. data.seg_vol_l, 
- Segmentierungsmaske (B)- mask_kidney_3D (Output der PlotSegmentation3D Funktion, 
- true/false für Visualisierung

OUTPUT: 
- dice: dice coeffizient von A und B
- dreidimensionale Visualisierung der beiden Masken und deren
Schnittflächen.

%}
  
% Permutation der Ground Truth Maske 
   A = permute(A, [1 3 2]); 
   

% Dice_Koeffizient berechnen
   intersection = nnz(A & B);
   dice = 2 * intersection / (nnz(A) + nnz(B));
   fprintf("Der Dice Koeffizient beträgt: %d", dice)

 
% showVis = true --> Farbanzeige des Overlaps.
% showVis = false --> nur Dice-Koeffizient

    if showVis
       visualize3D(A, B);
    end 
end
        
   

function visualize3D(A, B)
    figure; hold on;
    view(3); axis tight; daspect([1 1 1]); camlight; lighting gouraud;

    % Ground Truth – grün
    p1 = patch(isosurface(A, 0.5));
    set(p1, 'FaceColor', [0.1 0.8 0.1], 'EdgeColor', 'none', 'FaceAlpha', 0.5);

    % segmentierte Maske – blau
    p2 = patch(isosurface(B, 0.5));
    set(p2, 'FaceColor', [0.2 0.4 1], 'EdgeColor', 'none', 'FaceAlpha', 0.5);

    % Overlap – orange
    overlap = A & B;
    p3 = patch(isosurface(overlap, 0.5));
    set(p3, 'FaceColor', [1 0.7 0.1], 'EdgeColor', 'none', 'FaceAlpha', 0.9);

    title('3D Overlap: Grün = Ground Truth, Blau = Segmentierung, Orange = Schnittmenge');
end
