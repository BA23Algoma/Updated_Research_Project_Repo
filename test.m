fid = fopen('GazePoint User Data\Test Subject 1\result\User 0_fixations.csv');



fgets(fid); % Skip headers
s = fgets(fid);
a = sscanf(s, '%s');
test1 = a(1);
test2 = a(2);
test3 = a(4);
test4 = a(5);

fclose(fid);