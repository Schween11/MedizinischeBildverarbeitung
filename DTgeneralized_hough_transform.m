function [score,y,x,acc] = DTgeneralized_hough_transform(target, reference, refY, refX)
%{
DESCRIPTION:
modified from: http://mbcoder.com/generalized-hough-transform/
Find reference image (edge image) in target image (edge image)
using generalized hough transform (GHT).

INPUT:
target: target image as binary edge image (edges = 1, rest = 0)
reference: reference image as binary edge image (edges = 1, rest = 0)
refY, refX: reference point (y,x coordinates) of the reference image,
e.g. middle point of the reference or top-left corner etc.

OUTPUT
score: maximum score of the best match
y, x: coordinates of the reference point of the best match
acc: accumulator (hough space)

%}

%--- Get the reference edge points ----------------------------------------
% find all y,x cordinates equal 1 in reference image (=edges)
[y,x] = find(reference>0); 
maxPoints = size(x,1); % number of points in the reference image

if (maxPoints<1)
    disp('Error: Cannot determine shape of reference (no data points equal 1)');
    quit();
end

% --- Create gradient map of reference ------------------------------------
gradient_ref = gradient_direction(reference); % erstellt Gradientenmap mit Richtung

% --- Create R-Table ------------------------------------------------------
maxAngles = 180; % devide the angel space to maxAngles uniformed space bins (0 deg = 0, 180 deg = 180)
binCounter = zeros(maxAngles); % counter for the amount of edge points associated with each angle gradient
Rtable = zeros(maxAngles, maxPoints, 2); % R-table ordnet jedem Winkelgradienten, eine Anzahl von Punkten zu und dem Abstand zur Referenz
for k=1:1:maxPoints
    bin = round((gradient_ref(y(k),x(k))/pi)*(maxAngles-1))+1; % transform continuous gradient angles to discrete angle bins
    binCounter(bin) = binCounter(bin) + 1; % increase binCounter at that position
    Rtable(bin, binCounter(bin), 1) = y(k) - refY; % offset y directiom
    Rtable(bin, binCounter(bin), 2) = x(k) - refX; % offset x direction
end

%--- Get the target edge points--------------------------------------------
% find all y,x cordinates equal 1 in target image (=edges)
[y, x] = find(target>0);
maxPoints_tar = size(x,1);
if (maxPoints_tar<1)
    disp('Error: Cannot determine edges of target (no data points equal 1)');
    quit();
end

% --- Create gradient map of target ---------------------------------------
gradient_tar = gradient_direction(target);
size_tar = size(target);

% --- Create and populate hough space (accumulator) -----------------------
houghspace = zeros(size_tar);

for k = 1:1:maxPoints_tar
    bin = round((gradient_tar(y(k), x(k))/pi)*(maxAngles-1))+1; % transform continuous gradient angles to discrete angle bins
    for j = 1:1:binCounter(bin)
        ty = y(k) - Rtable(bin, j, 1); 
        tx = x(k) - Rtable(bin, j, 2); % Bestimmung eines möglichen Mittelpunktes der gesuchten Form
        if (ty>0) && (ty<size_tar(1)) && (tx>0) && (tx<size_tar(2)) % Bedingung: möglicher Mittelpunkt muss im Bild liegen
            houghspace(ty, tx) =  houghspace(ty, tx)+1; % increase hough space at that position
        end
    end
end
% hough space ist Matrix in der größe des targets. die meisten tx, ty werte
% die vorkommen sind wahrscheinlichste mittelpunkt und haben
% dementsprechend den größten wert der Matrix --> wie ein Wärmebild
% --- Find best match in hough space with deformation tolerance ----------

acc = houghspace;
acc = acc ./ sqrt(sum(sum(reference))); % normalize acc by reference size (to prevent bias toward large shapes)

% Define spreading window size (2*l + 1)
l = 12; % empirical value used in DTGHT paper (corresponds to 25x25 window)

% Pad accumulator to allow windowed sum near borders
acc_padded = padarray(acc, [l l]); 

% Compute local sum (vote mass) using 2D convolution with uniform window
window = ones(2*l+1, 2*l+1); 
M = conv2(acc_padded, window, 'valid'); % M has same size as original acc

% Find position with highest vote mass (clustered peak)
[score, idx] = max(M(:));
[y, x] = ind2sub(size(M), idx);

% --- Extraneous-vs-Valid-Segment-Prüfung -------------------------
angle_thresh = pi/8;
% Fenstergröße
l = 12;
[y_tar, x_tar] = find(target > 0);
mask = (x_tar > (x - l)) & (x_tar < (x + l)) & (y_tar > (y - l)) & (y_tar < (y + l));
x_tar = x_tar(mask);
y_tar = y_tar(mask);

valid = 0;
extraneous = 0;

for i = 1:length(y_tar)
    py = y_tar(i);
    px = x_tar(i);
    g = gradient_tar(py, px);

    for bin = 1:maxAngles
        for j = 1:binCounter(bin)
            dy = Rtable(bin,j,1);
            dx = Rtable(bin,j,2);
            qy = py + dy;
            qx = px + dx;
            if qy > 0 && qy <= size(target,1) && qx > 0 && qx <= size(target,2)
                % Check ob die Richtung übereinstimmt
                g_ref = gradient_ref(refY + dy, refX + dx);
                if abs(g - g_ref) < angle_thresh
                    valid = valid + 1;
                else
                    extraneous = extraneous + 1;
                end
            end
        end
    end
end

% Wenn zu viele extraneous votes → Ablehnen
if extraneous > valid
    score = 0;
    y = NaN;
    x = NaN;
end

% --- Similarity Measure Sim(S, I) nach Matching-Test ---------------------
% Vektor B enthält pro Modellpunkt, ob er im Target gefunden wurde
m = sum(binCounter); % Anzahl aller Referenzpunkte im Sketch (S)
B = false(1, m);      % Boolean-Vektor: ob ein Modellpunkt bestätigt wurde
b_idx = 1;            % Zähler über Modellpunkte

for bin = 1:maxAngles
    for j = 1:binCounter(bin)
        dy = Rtable(bin,j,1);
        dx = Rtable(bin,j,2);
        ty = y + dy;
        tx = x + dx;

        if ty < 1 || ty > size(target,1) || tx < 1 || tx > size(target,2)
            b_idx = b_idx + 1;
            continue;
        end

        % Wenn im Target ein Kantenpunkt an der erwarteten Position liegt → Treffer
        if target(ty, tx) > 0
            % zusätzlich Gradienten vergleichen
            g_tar = gradient_tar(ty, tx);
            g_ref = gradient_ref(refY + dy, refX + dx);
            if abs(g_tar - g_ref) < angle_thresh
                B(b_idx) = true;
            end
        end
        b_idx = b_idx + 1;
    end
end

% Ähnlichkeitsmaß berechnen (Anteil der bestätigten Modellpunkte)
sim_score = sum(B) / m;

% finaler Score ist jetzt sim_score statt Akkumulatorwert
score = sim_score;

end
