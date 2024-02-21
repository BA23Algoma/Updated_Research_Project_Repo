function intersects = doLineSegmentsIntersect(segment, wall)
    % Perform line segment intersect test
    % Return true if the segment intersects, else false
    
    x1 = segment(1);
    y1 = segment(2);
    x2 = segment(3);
    y2 = segment(4);
    x3 = wall.p1(1);
    y3 = wall.p1(2);
    x4 = wall.p2(1);
    y4 = wall.p2(2);
    
    %Calcualte the vecors for the two line segments
    u = [x2 - x1, y2 - y1];
    v = [x4 - x3, y4 - y3];
    
    %Calculate the cross prodcut
    crossProduct = u(1) * v(2) - u(2) * v(1);
    
    % Check if lines are parrallel
    if abs(crossProduct) < 1e-6
        intersects = false; % Lines are parrallel
        return;
    end
    
    % Calculate the parameters for the line segments
    t1 = ((x3 - x1) * v(2) - (y3 - y1) * v(1))/ crossProduct;
    t2 = ((x3 - x1) * u(2) - (y3 - y1) * u(1))/ crossProduct;
    
    % Check if the intersection point lies on the line segments
    if t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <=1
        intersects = true;
    else
        intersects = false;
    end

end
    
    