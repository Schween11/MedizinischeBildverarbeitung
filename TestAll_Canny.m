clear;

case_ids = [63
66
71
91
96


];
tbl = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
bilder = cell(1, 5);
titel = strings(1, 5);

for i = 1:5
    id = case_ids(i);
    case_str = sprintf('%05d', id);
    row = tbl{:,1} == id;

    Xslice = tbl{row, 9};
    zrange = tbl{row,10}:tbl{row,11};

    % Bild einlesen
    case_path = fullfile('allcasesunzipped', ['case_' case_str]);
    im = niftiread(fullfile(case_path, 'imaging.nii.gz'));
    im = im(zrange, :, :);
    im = (im - min(im(:))) / (max(im(:)) - min(im(:)));

    slice_cor = squeeze(im(:, Xslice, :));
    nz = size(slice_cor, 2);
    midZ = round(nz/2);
    location = extractBefore(string(tbl{row,12}), ',');
    I = slice_cor(:, midZ+1:end);
    if location == "links"
        I = slice_cor(:, 1:midZ);
    end


    I_smooth = imdiffusefilt(I, 'NumberOfIterations', 30, 'GradientThreshold', 10);

    low = mean(I_smooth(:)) * 0.5;
   high = mean(I_smooth(:)) * 1.5;
   BW = edge(I_smooth, 'Canny', low, high)

    % Nachbearbeitung
    BW_clean = bwareaopen(BW, 50); %Entfernt Pixelinseln

    bilder{i} = BW_clean;
    titel(i) = "Case " + id;
end

figure;
for k = 1:5
    subplot(1,5,k);
    imshow(bilder{k});
    title(titel(k), 'FontSize', 9);
end
sgtitle('Canny-Kantendetektion (5 Fälle)', 'FontWeight', 'bold');
