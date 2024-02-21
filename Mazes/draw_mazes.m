tiledlayout(4,5)

for i = 1:9
    
    mazeFile = strcat('maze#0', num2str(i), '.rev.txt');
    mazeTitle = strcat('Maze #0', num2str(i));
    
    mazeLayout = Maze(mazeFile);
    
    nexttile;
    title(mazeTitle);
    Draw(mazeLayout);
    axis off;
end

for i = 10:20
    
    mazeFile = strcat('maze#', num2str(i), '.rev.txt');
    mazeTitle = strcat('Maze #', num2str(i));
    
    mazeLayout = Maze(mazeFile);
    
    nexttile;
    title(mazeTitle);
    Draw(mazeLayout);
    axis off;
end
