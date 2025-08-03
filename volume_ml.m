function vol_ml = volume_ml(mask3D, pixX, pixY, pixZ)
%{
Berechnet das Volumen einer 3D-Maske in ml unter Berücksichtigung von
Pixelabständen, Schichtdicken und Interpolationsschritten

INPUT:
    mask3D   – binäre Maske (Ground truth oder segmentierte Maske) 
    pixX     – Pixelgröße in X-Richtung [mm]
    pixY     – Pixelgröße in Y-Richtung [mm]
    pixZ     – Schichtdicke vor Interpolation [mm]
    scaleZ   – Interpolationsfaktor in Z 

OUTPUT:
    vol_ml   – Volumen in Millilitern [ml]
%}

    % Voxelvolumen in mm³
    voxel_volume_mm3 = pixX * pixY * pixZ;

    % Anzahl der Voxel mit Wert 1
    num_voxels = nnz(mask3D);

    % Gesamtvolumen in mm³ → umrechnen in ml (1 ml = 1000 mm³)
    vol_ml = (num_voxels * voxel_volume_mm3) / 1000;
end
