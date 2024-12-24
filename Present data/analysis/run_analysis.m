clear all
close all
clc

% TODO: Make sure plotting colors denote the same data across plots (i.e.
% right-red, left-blue, bino-green

%% Dependencies
%
% BlandAltman - https://www.mathworks.com/matlabcentral/fileexchange/45049-bland-altman-and-correlation-plot/
blandpath = '../Bland-Altman and Correlation Plot';
addpath(blandpath);

%% set figure defaults
fontSize = 14; 
set(groot,'defaultAxesFontSize', fontSize)
set(groot,'defaultTextFontSize', fontSize)
set(groot,'defaultLegendFontSize', fontSize)
set(groot,'defaultAxesLineWidth',1)
set(groot,'defaultLineLineWidth',2)
set(groot,'defaultAxesTickDir', 'out');
set(groot,'defaultAxesTickDirMode', 'manual');

%% Loop to put all VR data in a struct
% visual acuity data
f_ac = dir('../data/*ecc*.json'); % get relevant data files

for k = 1:length(f_ac) % loop to get data files into struct
    fname = fullfile(f_ac(k).folder, f_ac(k).name); % get one file
    VRDATA_ac{k} = readstruct(fname); % read data file into struct
    subn = f_ac(k).name(1:7);
    atte = f_ac(k).name(end-7:end-5);
    if contains(f_ac(k).name,'_uc_')
        uname = [subn, atte,'_uc'];
    else
        uname = [subn, atte];
    end
    for i = 1:120
        VRDATA_ac{k}(i).Username = uname;
    end
end

% contrast sensitivity data
f_cs = dir('../data/*_cs_*.json'); % get relevant data files

for k = 1:length(f_cs) % loop to get data files into struct
    fname = fullfile(f_cs(k).folder, f_cs(k).name); % get one file
    VRDATA_cs{k} = readstruct(fname); % read data file into struct
    subn = f_cs(k).name(1:7);
    atte = f_cs(k).name(end-7:end-5);

    uname = [subn, atte];

    for i = 1:120
        VRDATA_cs{k}(i).Username = uname;
    end
end

%% calculate average for VR
% acuity
for k = 1:length(f_ac)
    x = [VRDATA_ac{k}.TrialNumber]; % extract trial number and logmar score
    y = [VRDATA_ac{k}.LogMAR];

    c1 = [VRDATA_ac{k}.EyeCondition] == "Both"; % extract eye condition
    c2 = [VRDATA_ac{k}.EyeCondition] == "Right";
    c3 = [VRDATA_ac{k}.EyeCondition] == "Left";

    x1 = x(c1); % match logmar score to condition
    vr_raw_both = y(c1);

    x2 = x(c2);
    vr_raw_right = y(c2);

    x3 = x(c3);
    vr_raw_left = y(c3);

    subID = string(VRDATA_ac{k}(1).Username);
    % TODO: Replace with tresholds from psychometric fits
    vr_threshold_both = mean(vr_raw_both(end-20:end)); % mean of VR logmar score (average last 20 trials)
    vr_threshold_right = mean(vr_raw_right(end-20:end));
    vr_threshold_left = mean(vr_raw_left(end-20:end));
    vr_threshold_ac(k,:) = table(subID,vr_threshold_both,vr_threshold_right,vr_threshold_left);
end

% contrast
for k = 1:length(f_cs)
    x = [VRDATA_cs{k}.TrialNumber]; % extract trial number and logmar score
    y = [VRDATA_cs{k}.LogLum];

    c1 = [VRDATA_cs{k}.EyeCondition] == "Both"; % extract eye condition
    c2 = [VRDATA_cs{k}.EyeCondition] == "Right";
    c3 = [VRDATA_cs{k}.EyeCondition] == "Left";

    x1 = x(c1); % match logmar score to condition
    vr_raw_both = y(c1);

    x2 = x(c2);
    vr_raw_right = y(c2);

    x3 = x(c3);
    vr_raw_left = y(c3);

    subID = string(VRDATA_cs{k}(1).Username);
    % TODO: Replace with tresholds from psychometric fits
    vr_threshold_both = mean(vr_raw_both(end-20:end)); % mean of VR loglum score (average last 20 trials)
    vr_threshold_right = mean(vr_raw_right(end-20:end));
    vr_threshold_left = mean(vr_raw_left(end-20:end));
    vr_threshold_cs(k,:) = table(subID,vr_threshold_both,vr_threshold_right,vr_threshold_left);
end

%% crafting separate tables for each session
% contrast tables
cs_01 = endsWith(table2array(vr_threshold_cs(:,"subID")),'_01');
vr_threshold_cs_01 = vr_threshold_cs(cs_01,:);
cs_02 = endsWith(table2array(vr_threshold_cs(:,"subID")),'_02');
vr_threshold_cs_02 = vr_threshold_cs(cs_02,:);
writetable(vr_threshold_cs_01,'vr_threshold_cs.xlsx');

% acuity tables
ac_01 = contains(table2array(vr_threshold_ac(:,"subID")),'_01');
vr_threshold_ac_01 = vr_threshold_ac(ac_01,:);
ac_02 = contains(table2array(vr_threshold_ac(:,"subID")),'_02');
vr_threshold_ac_02 = vr_threshold_ac(ac_02,:);
writetable(vr_threshold_ac_01,'vr_threshold_ac.xlsx');

% set up variables for plot
ac_ses01 = table2array(vr_threshold_ac_01(:,[2 3 4]));
ac_ses02 = table2array(vr_threshold_ac_02(:,[2 3 4]));

cs_ses01 = abs(table2array(vr_threshold_cs_01(:,[2 3 4])));
cs_ses02 = abs(table2array(vr_threshold_cs_02(:,[2 3 4])));

%% Bland-Altman plots

%% Acuity - VR
leg_ac = {'binocular','right','left'};
BlandAltman(ac_ses01,ac_ses02,'VR (logMAR)','Acuity - VR',leg_ac,'markerSize',7,'axesLimits',[0 1.5],'baYLimMode',[-.5 .5]);
fig = gcf;
% fig.WindowState = "maximized";
exportgraphics(fig,'../figures/acuity_VR_reliability_average.pdf')

%% Contrast - VR
leg_cs = {'binocular','right','left'};
BlandAltman(cs_ses01,cs_ses02,'VR (-logContrast)','Contrast - VR',leg_cs,'markerSize',7,'axesLimits',[1 2],'baYLimMode',[-.3 .3]);
fig2 = gcf;
% fig2.WindowState = "maximized";
exportgraphics(fig2,'../figures/contrast_VR_reliability_average.pdf')

%%  Acuity - VR vs Chart 
acu_data = readmatrix("chart_vs_vr_acuity.xlsx");
leg_new = {'right','left','binocular'};
chart_data_ac = acu_data(:,[5 6 7]);
vr_data_ac = acu_data(:,[2 3 4]);

[rpc, fig, stats] = BlandAltman(chart_data_ac,vr_data_ac,{'Chart','VR','logMar'},'Acuity - VR vs Chart',leg_new,'markerSize',7,'axesLimits',[-.5 1.5],'baYLimMode',[-.5 1]);

% add reference lineshold on
% subplot(1,2,1);
yline(fig.Children(4), log10(30/10),'--', 'Quest 2', 'LineWidth',1,'FontSize', fontSize,'HandleVisibility','off') % Quest 2
% yline(fig.Children(4), log10(30/12.5),'--','Quest 3', 'LineWidth',1,'FontSize', fontSize,'HandleVisibility','off') % Quest 3

exportgraphics(gcf,'../figures/chart_vs_vr_acuity.pdf');

%% Contrast - VR vs Chart
cs_data = readmatrix("chart_vs_vr_contrast.xlsx");

chart_data_cs = cs_data(:,[5 6 7]);
vr_data_cs = -cs_data(:,[2 3 4]);
BlandAltman(chart_data_cs,vr_data_cs,{'Chart','VR','-logContrast'},'Contrast - VR vs Chart',leg_new,'markerSize',7,'axesLimits',[1 2],'baYLimMode',[-1 0]);
fig6 = gcf;
exportgraphics(fig6,'../figures/chart_vs_vr_contrast.pdf');