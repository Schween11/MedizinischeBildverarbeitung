function [mat]=rotate_binary_edge_image(I,Ang)
%{
DESCRIPTION:
Rotate binary edge image (I) by (Ang) degrees .
The rotated output image will also also be a binary edge image.
The connectivity/topology of all edges/curves in the input image (I) will
be maintained and the line thickness of the curves in the output
image (mat) will remain 1 pixel.
The center of rotation is the center of the image.
The dimensions of the output image (mat) will be different from the 
input image (I) and will be set such that the rotated image is fully
within the image frame.

INPUT:
I: Binary  edge image (logical type) consist of lines and curves with 
thickness of one pixel
Ang: Rotation angle of the image in Degrees
 
OUTPUT:
mat: Rotated version of the input image (I)

rotated coordinates:
x' = x*cos(theta) - y*sin (theta)
y' = x*sin(theta) + y*cos (theta)
%}

% --- Initialization: Get information of original image ------------------
[Height,Width] = size(I);
CntX = (Width+1)/2;
CntY = (Height+1)/2;
theta = Ang/180*pi; % convert angle from degree  to radians

%--- find size of new image -----------------------------------------------
% Rotation matrix
Rot = [ cos(theta) -sin(theta);
        sin(theta)  cos(theta)];
% Corners of the old image center at origin (0,0)
Corners = [ 1-CntY      1-CntX;
            1-CntY      Width-CntX;
            Height-CntY 1-CntX;
            Height-CntY Width-CntX]; 
% New corners
NewCorn = Corners*Rot; 
NMaxX = max(NewCorn(:,2));
NMinX = min(NewCorn(:,2));
NMaxY = max(NewCorn(:,1));
NMinY = min(NewCorn(:,1));

% New size of image and translation of image
NSizeY=NMaxY-NMinY;
NSizeX=NMaxX-NMinX;
Dx=-NMinX;      
Dy=-NMinY; 

% create canvas for rotated image
mat = false(round(NSizeY+1),round(NSizeX+1));

%--- rotate image ---------------------------------------------------------
[y,x]=find(I);
[n,~]=size(x);
for f=1:n %scan all points on image
    p1=[y(f)-CntY x(f)-CntX]*Rot+[Dy+1 Dx+1];
    mat(round(p1(1)),round(p1(2)))=1;% mark rotated point
    
    if x(f)>1 && I(y(f),x(f)-1)==1 % connect horizontal neighbour 
           Nx=x(f)-1; Ny=y(f);
           p1=[y(f)-CntY, x(f)-CntX]*Rot+[Dy+1 Dx+1];
           p2=[Ny-CntY, Nx-CntX]*Rot+[Dy+1 Dx+1];
           mat=ConnectPoints(mat,round(p1(2)),round(p1(1)),round(p2(2)),round(p2(1)));
    end
    if y(f)>1 && I(y(f)-1,x(f))==1 % connect vertical neighbour
            Nx=x(f); Ny=y(f)-1;  
            p1=[y(f)-CntY, x(f)-CntX]*Rot+[Dy+1 Dx+1];
            p2=[Ny-CntY, Nx-CntX]*Rot+[Dy+1 Dx+1];
            mat=ConnectPoints(mat,round(p1(2)),round(p1(1)),round(p2(2)),round(p2(1)));
    end
    if y(f)>1  && x(f)>1 &&  I(y(f)-1,x(f))==0 && I(y(f),x(f)-1)==0 && I(y(f)-1,x(f)-1)==1 % connect diagonal neighbor
            Nx=x(f)-1; Ny=y(f)-1;  
            p1=[y(f)-CntY, x(f)-CntX]*Rot+[Dy+1 Dx+1];
            p2=[Ny-CntY, Nx-CntX]*Rot+[Dy+1 Dx+1];
            mat=ConnectPoints(mat,round(p1(2)),round(p1(1)),round(p2(2)),round(p2(1)));
    end
    if y(f)>1  && x(f)<Width &&  I(y(f)-1,x(f))==0 && I(y(f),x(f)+1)==0 && I(y(f)-1,x(f)+1)==1 % connect second diagonal neighbor
            Nx=x(f)+1; Ny=y(f)-1;  
            p1=[y(f)-CntY, x(f)-CntX]*Rot+[Dy+1 Dx+1];
            p2=[Ny-CntY, Nx-CntX]*Rot+[Dy+1 Dx+1];
            mat=ConnectPoints(mat,round(p1(2)),round(p1(1)),round(p2(2)),round(p2(1)));
    end
end

end


%--- Helper function ------------------------------------------------------
function [mat]=ConnectPoints(mat,x1,y1,x2,y2)
% draw line between x1,y1 to x2,y2 on binary image mat
% make sure cordinates are inside image mat
SizeMat=size(mat);
x1=max(x1,1);x2=max(x2,1);y1=max(y1,1);y2=max(y2,1);
y1=min(y1,SizeMat(1));y2=min(y2,SizeMat(1));x1=min(x1,SizeMat(2));x2=min(x2,SizeMat(2));

if x1==x2 % for horizontal line
    y=linspace(y1,y2,abs(y1-y2)*5);
      x = ones(size(y))*x1;
else % for none horizontal line
   x = linspace(x1,x2,abs(x1-x2)*5+abs(y1-y2)*5);   
   y = y1+(x-x1)*(y2-y1)/(x2-x1);                     
end
round(y);
index = sub2ind(size(mat),round(y),round(x));  
mat(index) = 1;   
end