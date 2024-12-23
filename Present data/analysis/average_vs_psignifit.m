%% compare values from psignifit vs average of last 20 trials
data = readtable('vr_threshold_ac.xlsx','Sheet','Sheet2');
ave = table2array(data(:,[6 7 8]));
psig = table2array(data(:,[3 4 5]));
rsq = corrcoef(ave,psig).^2;
txt = ['r-squared =', num2str(rsq(2,1))];
p = figure;
p.WindowState = 'maximized';
scatter(psig,ave,'filled');
line([.4 1.1], [.4 1.1],'Color','k', 'LineWidth', 1);
text(.5,1,txt,'Color','red','FontSize',14);
xlabel('average calculation');
ylabel('psignifit calculation');
title('average vs psignifit calculation');
exportgraphics(p, '../figures/average_vs_psignifit.pdf');