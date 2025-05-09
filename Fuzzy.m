
[Gmag, ~] = imgradient(slice_cor);  % Gradientmagnitude als Kantenkriterium

% Erstelle einfaches Mamdani-FIS
fis = mamfis('Name','EdgeFuzzy');

% Eingabe: Gradient
fis = addInput(fis, [0 1], 'Name', 'Gradient');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0], 'Name', 'low');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 0.5], 'Name', 'medium');
fis = addMF(fis, 'Gradient', 'gaussmf', [0.1 1], 'Name', 'high');

% Ausgabe: Kantenstärke
fis = addOutput(fis, [0 1], 'Name', 'EdgeStrength');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0 0 0.5], 'Name', 'weak');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0 0.5 1], 'Name', 'medium');
fis = addMF(fis, 'EdgeStrength', 'trimf', [0.5 1 1], 'Name', 'strong');

% Regelbasis
rules = [
    "If Gradient is low Then EdgeStrength is weak"
    "If Gradient is medium Then EdgeStrength is medium"
    "If Gradient is high Then EdgeStrength is strong"
];
fis = addRule(fis, rules);

% Auswertung für jeden Pixel
edge_fuzzy = zeros(size(slice_cor));
for i = 1:size(slice_cor,1)
    for j = 1:size(slice_cor,2)
        edge_fuzzy(i,j) = evalfis(fis, Gmag(i,j));
    end
end

imshow(edge_fuzzy, []);
title('Fuzzy-Kantenkarte');
