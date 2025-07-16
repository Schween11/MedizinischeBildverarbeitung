function [target_marked,reference_marked,YBest,XBest,ang,scale,score,acc]= find_tumor(target, reference);

% adaptierte Funktion für Tumorerkennung

% --- Initialization ------------------------------------------------------
lowest_score = 0; % define lowest score
score = lowest_score; % initialize score as lowest_score
YBest = 0;
XBest = 0;
       
for ang = 0:30:360 % rotate image
        rot_reference = rotate_binary_edge_image(reference,ang);
        for scale = 1:0.1:1.5 % scale image
            scaled_reference = imresize(rot_reference, scale);
            
            ref = int64(size(scaled_reference)/2); % define reference point as middle point of the scaled and rotated reference
            refY = ref(1);
            refX = ref(2);
            [current_score,y,x,acc] = DTgeneralized_hough_transform(target, scaled_reference, refY, refX); % call GHT with the modified reference        
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
    
else % if no match
    disp('Error: No match founded');
    target_marked = target;
    reference_marked = false(size(target));
    YBest = NaN;
    XBest = NaN;
    ang = NaN;
    scale = NaN;
    score = 0;
end

end