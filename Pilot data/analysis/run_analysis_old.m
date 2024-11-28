% Description of script
clear all
close all
clc

%% set figure defaults
fontSize = 14; 
set(groot,'defaultAxesFontSize', fontSize)
set(groot,'defaultTextFontSize', fontSize)
set(groot,'defaultLegendFontSize', fontSize)
set(groot,'defaultAxesLineWidth',1)
set(groot,'defaultLineLineWidth',2)
set(groot,'defaultAxesTickDir', 'out');
set(groot,'defaultAxesTickDirMode', 'manual');
% set(0,'DefaultFigureVisible','off'); % figure off
%% Loop to put all VR data in a struct
VRDATA = []; % initialize struct

% TODO: Read in specific subs, specified in cell array
% sub = 'AR_002_C6'; % subject id
% dataDir = '../data';
f = dir('../data/*C6.json'); % get relevant data files 

for k = 1:length(f) % loop to get data files into struct 
    fname = fullfile(f(k).folder, f(k).name); % get one file
    VRDATA{k} = readstruct(fname); % read data file into struct
end

figfol = '../figures'; % specify figure folder
snellen_raw = readtable('SubIDs.xlsx'); % raw and new table with proper column label
snellen_data = renamevars(snellen_raw,["Var1","Var2","Right","Var4","Var5","Left","Var7","Var8","Binocular","Var10","Var11"],["subID","IPD","right(c)","right(u4)","right(u2)","left(c)","left(u4)","left(u2)","binocular(c)","binocular(u4)","binocular(u2)"]);
snellen_data(1,:) = [];
%% set up variables for plotting

for k = 1:length(f)
x = [VRDATA{k}.list.TrialNumber]; % extract trial number and logmar score
y = [VRDATA{k}.list.LogMAR];

c1 = [VRDATA{k}.list.EyeCondition] == "Both_Eyes"; % extract eye condition
c2 = [VRDATA{k}.list.EyeCondition] == "Right_Eye";
c3 = [VRDATA{k}.list.EyeCondition] == "Left_Eye";

x1 = x(c1); % match logmar score to condition
vr_raw_both = y(c1);


x2 = x(c2);
vr_raw_right = y(c2);


x3 = x(c3);
vr_raw_left = y(c3);


vr_threshold_both = mean(vr_raw_both(end-20:end)); % mean of VR logmar score (average last 20 trials)
vr_threshold_right = mean(vr_raw_right(end-20:end));
vr_threshold_left = mean(vr_raw_left(end-20:end));

pat = digitsPattern(3); % pattern for subID
username = VRDATA{k}.list.Username; % set up table for vr threshold value
subname = unique(username);
subID = str2double(extract(subname,pat)); % get subID from username
vr_threshold(k,:) = table(subID,subname,vr_threshold_both,vr_threshold_right,vr_threshold_left);

indi = table2array(snellen_data(:,1)==subID); % extract row containing current participant data from snellen table
data_indi = snellen_data(indi,:);
cor_con = endsWith(subname,"_C6"); % check if corrected or uncorrected


if cor_con == 1
    snellen_both = table2array(data_indi(1,"binocular(c)"));
    snellen_left = table2array(data_indi(1,"left(c)"));
    snellen_right = table2array(data_indi(1,"right(c)"));
else
    snellen_both = table2array(data_indi(1,"binocular(u4)"));
    snellen_left = table2array(data_indi(1,"left(u4)"));
    snellen_right = table2array(data_indi(1,"right(u4)"));
end
% end

%% plot test

fig = figure;
fig.WindowState = 'maximized';
yl = [-0.3 1.1]; % set y limit (logMAR)

t = tiledlayout(1,3);

ax1 = nexttile;

ph = plot(ax1,x3,vr_raw_left,'LineWidth',2); % left eyes plot
yline(snellen_left,'r','LineWidth',2)  % line of ETDRS score
lh = yline(vr_threshold_left,':','LineWidth',2); % line of average VR score
lh.Color = ph.Color;
% legend('VR LogMar score','real score', 'VR average','offset' )
ylim(yl)
title('Left eye')

% The resolution of the Quest 2 is 20 pixels/degree
% so, 10 cycles/degree, or log10(30/cycpdeg) logMar
yline(log10(30/10),'--', 'LineWidth',1, 'FontSize', fontSize) % Quest 2
% yline(log10(30/12.5),'--','Meta Q3', 'LineWidth',1, 'FontSize', fontSize) % Quest 3


ax2 = nexttile; % both eye plot
plot(ax2,x1,vr_raw_both,'LineWidth',2)
yline(snellen_both,'r','LineWidth',2) 
lh = yline(vr_threshold_both,':','LineWidth',2);
lh.Color = ph.Color;
% legend('VR LogMar score','real score', 'VR average','offset' )
ylim(yl)
title('Both eyes')

yline(log10(30/10),'--', 'LineWidth',1, 'FontSize', fontSize) % Quest 2


ax3 = nexttile; % right eye plot
plot(ax3,x2,vr_raw_right,'LineWidth',2)
yline(snellen_right,'r','LineWidth',2) 
lh = yline(vr_threshold_right,':','LineWidth',2);
lh.Color = ph.Color;

% legend('VR','eyechart', 'VR average', 'Location', 'southeast')
% legend('VR', 'Average', '', 'Location', 'southeast')

ylim(yl)
title('Right eye')

yline(log10(30/10),'--', 'LineWidth',1, 'FontSize', fontSize) % Quest 2

xlabel(t,'Trial number', 'FontSize', fontSize)
ylabel(t,'Sloan font size (logMAR)', 'FontSize', fontSize)

legend('raw VR','snellen','VR average','meta Q2','Location','northeastoutside');
% Add right hand axis
Ax = gca;
ytix = Ax.YTick; % tick location
ytl = string((1./(10.^ytix))*30); % tick label
ytl = extractBefore(ytl, min(3, ytl.strlength())+1); % truncate strings
text(ones(size(ytix))*max(xlim)+0.08*diff(xlim), ytix, ytl, 'Horiz','left', 'Vert','middle', 'Fontsize', fontSize)



% Create a common ylabel on the right side
annotation('textbox',[1 .4 .5 .1], ...
    'String','Acuity (cyc/deg)','EdgeColor','none', 'Rotation', 90, 'FontSize', fontSize)

% Adjust the figure's position to make room for the ylabel
% fig.Position(3) = fig.Position(3) + .1; % does not currently work

%% stats stuff

figname = join(['sub-' VRDATA{k}.list(1).Username '_cond-VR_treshold.pdf'], ''); % make figure name for individual plot
filename = fullfile(figfol,figname); 
exportgraphics(fig, filename);

end

vr_snellen = join(vr_threshold,snellen_data); % table with both vr and real snellen threshold
writetable(vr_snellen, '../data/vr_threshold.xlsx');
sub_ext = table2array(vr_snellen(:,"subname"));
cor_data_con = endsWith(sub_ext,"_C6"); % separate above table into corrected and uncorrected for plotting
uncor_data_con = endsWith(sub_ext,"_UC6");
vr_snellen_cor = vr_snellen(cor_data_con,:);
vr_snellen_uncor = vr_snellen(uncor_data_con,:);
rsq_c = corrcoef(vr_snellen_cor{:,["binocular(c)","right(c)","left(c)"]},vr_snellen_cor{:,["vr_threshold_both","vr_threshold_right","vr_threshold_left"]}).^2;
rsq_uc = corrcoef(vr_snellen_uncor{:,["binocular(u4)","right(u4)","left(u4)"]},vr_snellen_uncor{:,["vr_threshold_both","vr_threshold_right","vr_threshold_left"]}).^2;
txt_c = ['r-squared corrected = ' num2str(rsq_c(2,1))];
txt_uc = ['r-squared uncorrected = ' num2str(rsq_uc(2,1))];
%% Plot summary figure across subjects
fig2 = figure; % scatter snellen and vr results
fig2.WindowState = 'maximized';
% markerSize = 50;
sp = scatter(vr_snellen_cor,["binocular(c)","right(c)","left(c)"],["vr_threshold_both","vr_threshold_right","vr_threshold_left"],"filled"); % corrected
hold on
sp2 = scatter(vr_snellen_uncor,["binocular(u4)","right(u4)","left(u4)"],["vr_threshold_both","vr_threshold_right","vr_threshold_left"]); % uncorrected
hold off
text(-0.2,1,txt_c,'Color','red','FontSize',14);
text(-0.2,0.92,txt_uc,'Color','red','FontSize',14);
xlabel('ETDRS eyechart acuity (logMAR)')
ylabel('VR acuity (logMAR)')
axis square
xlim([-0.3 1.1])
ylim([-0.3 1.1])
line([-.3 1.1], [-.3 1.1],'Color','k', 'LineWidth', 1) % identity (perfect performance)
legend("binocular(c)","right(c)","left(c)","binocular(u4)","right(u4)","left(u4)",'Location','northeastoutside');
% ls = lsline;
% ls.Color = sp.CData; % set line to same color as dots
Ax = gca;
hs = findobj(gca, 'Type','scatter');
NrPoints = numel(hs(1).XData) + numel(hs(2).XData) + numel(hs(3).XData) + numel(hs(4).XData) + numel(hs(5).XData) + numel(hs(6).XData);
txt_n = ['n = ' num2str(NrPoints)];
text(-0.2,1.07,txt_n,'Color','red','FontSize',14);
% The resolution of the Quest 2 is 20 pixels/degree
% so, 10 cycles/degree, or log10(30/cycpdeg) logMar
yline(log10(30/(9.81/2)),'--','Rift CV1', 'LineWidth',1,'FontSize', fontSize, 'LabelHorizontalAlignment','left','HandleVisibility','off') 
yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize,'HandleVisibility','off') % Quest 2
yline(log10(30/12.5),'--','Meta Q3', 'LineWidth',1,'FontSize', fontSize,'HandleVisibility','off') % Quest 3
yline(log10(30/(34/2)),'--','Apple VP', 'LineWidth',1,'FontSize', fontSize,'HandleVisibility','off') 
yline(log10(30/(51/2)),'--','Varjo XR4', 'LineWidth',1,'FontSize', fontSize,'HandleVisibility','off') 

exportgraphics(fig2, '../figures/acuity_vr_vs_chart.pdf')

% close all
