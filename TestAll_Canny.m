clear;

case_ids = [142
146
155
158
159

];
tbl = readtable('patients_25.xlsx', 'VariableNamingRule', 'preserve');
bilder = cell(2, 5);  % 3 Bilder pro Fall: manuell, low, high
titel = strings(2, 5);

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

    I_smooth = imdiffusefilt(slice_cor, 'NumberOfIterations', 25, 'GradientThreshold', 5);

    % Manuell gewählte Thresholds
    BW_manual = edge(I_smooth, 'Canny', 0.2, 0.4);
    BW_manual = bwareaopen(BW_manual, 120);
    bilder{1, i} = BW_manual;
    titel(1, i) = "Case " + id + " - manuell";

    % Automatische Thresholds 
    low = mean(I_smooth(:)) * 0.3;
    high = mean(I_smooth(:)) * 1.0;
    BW_auto_low = edge(I_smooth, 'Canny', low, high);
    BW_auto_low = bwareaopen(BW_auto_low, 50);
    bilder{2, i} = BW_auto_low;
    titel(2, i) = "Case " + id + " - auto";
end
figure;
for i = 1:5
    for j = 1:2
        subplot(2,5,(j-1)*5 + i);
        imshow(bilder{j,i});
        title(titel(j,i), 'FontSize', 8);
    end
end
sgtitle('Canny-Kantendetektion (manuell vs. automatisch)', 'FontWeight', 'bold');

