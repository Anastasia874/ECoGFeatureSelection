function electrode_matrix = electrode_template(n)


electrode_matrix = zeros(15, 7);
electrode_matrix(1, 3) = 2;
electrode_matrix(1, 5) = 1;
electrode_matrix(3, 3) = 4;
electrode_matrix(3, 5) = 3;
electrode_matrix(5, 3) = 7;
electrode_matrix(5, 5) = 6;
electrode_matrix(5, 7) = 5;
electrode_matrix(6, 6) = 8;
electrode_matrix(7, 3) = 11;
electrode_matrix(7, 5) = 10;
electrode_matrix(7, 7) = 9;
electrode_matrix(8, 2) = 14;
electrode_matrix(8, 4) = 13;
electrode_matrix(8, 6) = 12;
electrode_matrix(9, 1) = 18;
electrode_matrix(9, 3) = 17;
electrode_matrix(9, 5) = 16;
electrode_matrix(9, 7) = 15;
electrode_matrix(10, 2) = 21;
electrode_matrix(10, 4) = 20;
electrode_matrix(10, 6) = 19;
electrode_matrix(11, 1) = 24;
electrode_matrix(11, 3) = 23;
electrode_matrix(11, 5) = 22;
electrode_matrix(12, 2) = 27;
electrode_matrix(12, 4) = 26;
electrode_matrix(12, 6) = 25;
electrode_matrix(13, 1) = 30;
electrode_matrix(13, 3) = 29;
electrode_matrix(13, 5) = 28;
electrode_matrix(15, 1) = 32;
electrode_matrix(15, 3) = 31;

end