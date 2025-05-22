clear;

case_ids = [63, 66, 71, 91, 96];
tbl = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
bilder = cell(2, 5);  % 2 Bilder pro Fall: manuell (fixe Schwellen), auto (dynamisch)
titel = strings(2, 5);

sigmas = [1, 2, 3];  % Multiscale: verschiedene Glättungsstufen

for i = 1:5
    id = case_ids(i);
    case_str = sprintf('%05d', id);
    row = tbl{:,1} == id;

    Xslice = tbl{row, 9};
    zrange = tbl{row,10}:tbl{row,11};

    % Bild einlesen und normieren
    case_path = fullfile('allcasesunzipped', ['case_' case_str]);
    im = niftiread(fullfile(case_path, 'imaging.nii.gz'));
    im = im(zrange, :, :);
    im = (im - min(im(:))) / (max(im(:)) - min(im(:)));

    % Sagittaler Schnitt
    slice_cor = squeeze(im(:, Xslice, :));
    nz = size(slice_cor, 2);
    midZ = round(nz / 2);
    location = extractBefore(string(tbl{row,12}), ',');
    I = slice_cor(:, midZ+1:end);
    if location == "links"
        I = slice_cor(:, 1:midZ);
    end

    % --- Multiscale-Canny: manuell (fixe Schwellen) ---
    edges_manual = false(size(I));
    for s = sigmas
        I_blur = imgaussfilt(I, s);
        E = edge(I_blur, 'Canny', 0.2, 0.45);
        edges_manual = edges_manual | E;
    end
    edges_manual = bwareaopen(edges_manual, 100);
    bilder{1, i} = edges_manual;
    titel(1, i) = "Case " + id + " - manuell";

    % --- Multiscale-Canny: automatisch (dynamische Schwellen) ---
    edges_auto = false(size(I));
    for s = sigmas
        I_blur = imgaussfilt(I, s);
        low = mean(I_blur(:)) * 0.4;
        high = mean(I_blur(:)) * 1.2;
        E = edge(I_blur, 'Canny', low, high);
        edges_auto = edges_auto | E;
    end
    edges_auto = bwareaopen(edges_auto, 20);
    bilder{2, i} = edges_auto;
    titel(2, i) = "Case " + id + " - auto";
end

% Darstellung
figure;
for i = 1:5
    for j = 1:2
        subplot(2, 5, (j-1)*5 + i);
        imshow(bilder{j, i});
        title(titel(j, i), 'FontSize', 8);
    end
end
sgtitle('Multiscale-Canny-Kantendetektion (manuell vs. automatisch)', 'FontWeight', 'bold');
