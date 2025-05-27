function [target_marked,reference_marked,YBest,XBest,ang,scale,score]= find_object(target, reference)
%{

DESCRIPTION:
Find reference image (edge image) in target image (edge image)
using generalized hough transform (GHT)
by rotating and scaling of the reference.

INPUT:
target: target image as binary edge image (edges = 1, rest = 0)
reference: reference image as binary edge image (edges = 1, rest = 0)

OUTPUT
target_marked: target image with the best match of the reference
reference_marked: best match of the reference (with scaling and rotation)
YBest, XBest: coordinates of the reference point of the best match
ang: angular position of the best match
score: maximum score of the best match
%}

% --- Initialization ------------------------------------------------------
lowest_score = 0; % define lowest score
score = lowest_score; % initialize score as lowest_score
YBest = 0;
XBest = 0;
       

% --- Rotate and scale reference and run GHT ------------------------------
% Rotate and scale the reference in two for loops.
% You can use "rotate_binary_edge_image.m" for rotation and the matlab
% function "imresize" for scaling.
% Which rotation angles are useful, which scaling factors are useful?
% Call GHT ("generalized_hough_transform." with the modified reference
% and compare the results to the previous results.
% You can use the score of the GHT for comparing the results.
% Save the results and settings (rotation angle and scaling factor) of the
% best match.
% You can use the following variables: YBest, XBest, ang, scale, score

for ang = 0:10:360 % rotate image
    rot_reference = rotate_binary_edge_image(reference,ang);
    for scale = 0.5:0.1:2 % scale image
        scaled_reference = imresize(rot_reference, scale);
%
        ref = int64(size(scaled_reference)/2); % define reference point as middle point of the scaled and rotated reference
        refY = ref(1);
        refX = ref(2);
        [current_score,y,x,~] = generalized_hough_transform(target, scaled_reference, refY, refX); % call GHT with the modified reference        
        if current_score > score % compare result to previuous results
              % save results and settings
              score = current_score;
              YBest = y;
              XBest = x;
              best_ang = ang;
              best_scale = scale;
        end
    end
end

ang = best_ang;
scale = best_scale;

% --- Mark the results in the original image ------------------------------
if score>lowest_score % if score of best match is good enough
    
    % rotate and scale reference according to best match
    result_ref = imresize(rotate_binary_edge_image(reference,ang), scale);
    ref = int64(size(result_ref)/2); % calculate reference point as in GHT
    refY = ref(1);
    refX = ref(2);
    
    % find all y,x cordinates (=edges)
    [yy,xx] = find(result_ref);
    
    % Mark best match on target image in Red (255) with "set2.m"
    target_marked = set2(target, [yy,xx], 255, YBest-refY, XBest-refX); 
    
    % Save reference only with rotation and scaling with "set2.m"
    reference_marked = false(size(target));
    reference_marked = set2(reference_marked, [yy,xx], 1, YBest-refY, XBest-refX);
    figure;
    subplot(1,2,1); imshow(target_marked); title('target');
    subplot(1,2,2); imshow(reference_marked); title('ref');
else % if no match
    disp('Error: No match founded');
    target_marked = target;
    reference_marked = false(size(target));
    YBest = NaN;
    XBest = NaN;
    ang = NaN;
    scale = NaN;
    score = 0;
    % TODO: Which values will be returned if no match was found?
end

end
