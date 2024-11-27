clear all
close all
clc

%% Dependencies
%
% BlandAltman - https://www.mathworks.com/matlabcentral/fileexchange/45049-bland-altman-and-correlation-plot/
blandpath = '../Bland-Altman and Correlation Plot';
addpath(blandpath);
%% read excel sheet of chart data
chart_1 = readtable('SubIDs_new.xlsx','Sheet','session 1');
chart_1(1,:) = [];
chart_1 = renamevars(chart_1,["Var1","Var2","Right","Var4","Left","Var6","Binocular","Var8","Right_1","Left_1","Binocular_1"],["subID","IPD","right(c)","right(u4)","left(c)","left(u4)","binocular(c)","binocular(u4)","right_cs","left_cs","binocular_cs"]);
chart_2 = readtable('SubIDs_new.xlsx','Sheet','session 2');
chart_2(1,:) = [];
chart_2 = renamevars(chart_2,["Var1","Var2","Right","Var4","Left","Var6","Binocular","Var8","Right_1","Left_1","Binocular_1"],["subID","IPD","right(c)","right(u4)","left(c)","left(u4)","binocular(c)","binocular(u4)","right_cs","left_cs","binocular_cs"]);

%% acuity data
binocular_c1 = table2array(chart_1(:,"binocular(c)"));
binocular_c2 = table2array(chart_2(:,"binocular(c)"));
binocular_uc1 = table2array(chart_1(:,"binocular(u4)"));
binocular_uc2 = table2array(chart_2(:,"binocular(u4)"));
left_c1 = table2array(chart_1(:,"left(c)"));
left_c2 = table2array(chart_2(:,"left(c)"));
left_uc1 = table2array(chart_1(:,"left(u4)"));
left_uc2 = table2array(chart_2(:,"left(u4)"));
right_c1 = table2array(chart_1(:,"right(c)"));
right_c2 = table2array(chart_2(:,"right(c)"));
right_uc1 = table2array(chart_1(:,"right(u4)"));
right_uc2 = table2array(chart_2(:,"right(u4)"));

acu_1 = [binocular_c1,binocular_uc1,left_c1,left_uc1,right_c1,right_uc1];
acu_2 = [binocular_c2,binocular_uc2,left_c2,left_uc2,right_c2,right_uc2];
rsq_acu = corrcoef(acu_1,acu_2).^2;
txt_acu = ['r-squared =', num2str(rsq_acu(2,1))];

%% contrast sensitivity data
binocular_cs1 = table2array(chart_1(:,"binocular_cs"));
binocular_cs2 = table2array(chart_2(:,"binocular_cs"));

left_cs1 = table2array(chart_1(:,"left_cs"));
left_cs2 = table2array(chart_2(:,"left_cs"));

right_cs1 = table2array(chart_1(:,"right_cs"));
right_cs2 = table2array(chart_2(:,"right_cs"));

cs1 = [binocular_cs1,left_cs1,right_cs1];
cs2 = [binocular_cs2,left_cs2,right_cs2];
rsq_cs = corrcoef(cs1,cs2).^2;
txt_cs = ['r-squared =', num2str(rsq_cs(2,1))];
%% bland altman plot acuity
leg_acu = {'binocular(c)', 'binocular(u)','left(c)','Left(u)','right(c)','right(u)'};
BlandAltman(acu_1,acu_2,'chart acuity','bland-altman plot (acuity)',leg_acu,'markerSize',7);
fig = gcf;
fig.WindowState = "maximized";
exportgraphics(fig,'../figures/acuity_chart_reliability.pdf');

%% bland altman plot contrast sensitivity
leg_cs = {'binocular','left','right'};
BlandAltman(cs1,cs2,'chart contrast sensitivity','bland-altman plot (cs)',leg_cs,'markerSize',7);
fig2 = gcf;
fig2.WindowState = "maximized";
exportgraphics(fig2,'../figures/contrast_chart_reliability.pdf')
%% scatter plot of reliability of visual acuity between 2 sessions
% fig = figure
% fig.WindowState = 'maximized';
% scatter(acu_1,acu_2,"filled");
% xlim([-0.3 1.1]);
% ylim([-0.3 1.1]);
% line([-.3 1.1], [-.3 1.1],'Color','k', 'LineWidth', 1);
% text(-0.2,1,txt_acu,'Color','red','FontSize',14);
% xlabel('session 1 (logMAR)');
% ylabel('session 2 (logMAR)');
% title('reliability of Snellen chart');
% legend('binocular(c)', 'binocular(u)','left(c)','Left(u)','right(c)','right(u)','Location','northeastoutside');
% exportgraphics(fig, '../figures/acuity_chart_reliability.pdf');

%% scatter plot of reliability of contrast sensitivity between 2 sessions
% fig2 = figure
% fig2.WindowState = 'maximized';
% scatter(cs1,cs2,"filled");
% xlim([0 2.25]);
% ylim([0 2.25]);
% line([0 2.25], [0 2.25],'Color','k', 'LineWidth', 1);
% text(0.5,2.1,txt_cs,'Color','red','FontSize',14);
% xlabel('session 1 (log CS)');
% ylabel('session 2 (log CS)');
% title('reliability of Pelli-Robson chart');
% legend('binocular','left','right','Location','northeastoutside');
% exportgraphics(fig2, '../figures/sensitivity_chart_reliability.pdf');

%% vr acuity psignifit reliability
vr_ac_1 = readmatrix('thresholds_acuity.xlsx','Sheet','session 1');
vr_ac_2 = readmatrix('thresholds_acuity.xlsx','Sheet','session 2');
vr_psig1_ac = vr_ac_1(:,[ 3 4 5]);
vr_psig2_ac = vr_ac_2(:,[ 3 4 5]);
leg = {'right','left','binocular'};
BlandAltman(vr_psig1_ac,vr_psig2_ac,'vr acuity','bland-altman plot (acuity)',leg,'markerSize',7);
fig3 = gcf;
fig3.WindowState = "maximized";
exportgraphics(fig3,'../figures/acuity_vr_reliability_psignifit.pdf');
%% vr contrast psignifit reliability
vr_cs_1 = readmatrix('thresholds_contrast.xlsx','Sheet','session 1');
vr_cs_2 = readmatrix('thresholds_contrast.xlsx','Sheet','session 2');
vr_psig1_cs = vr_cs_1(:,[ 3 4 5]);
vr_psig2_cs = vr_cs_2(:,[ 3 4 5]);
leg = {'right','left','binocular'};
BlandAltman(vr_psig1_cs,vr_psig2_cs,'vr contrast sensitivity','bland-altman plot (contrast)',leg,'markerSize',7);
fig4 = gcf;
fig4.WindowState = "maximized";
exportgraphics(fig4,'../figures/contrast_vr_reliability_psignifit.pdf');