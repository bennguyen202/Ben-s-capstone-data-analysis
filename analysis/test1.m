% this is the version with less extra text
clear all
close all
clc

%% Loop to put all VR data in a struct
VRDATA = []; % initialize struct
f = dir('../data/*C6.json'); % get all data files relevant

for k = 1:length(f) % loop to get data files into one struct 
    fname = fullfile(f(k).folder, f(k).name); % get one file
    ch = char(f(k).name); % transform to character array to store into fields
    VRDATA.(ch(1:end-5)) = readstruct(fname); % read data file into struct
end

%% set up variables for plotting
yl = [-0.3 1.1]; % set y limit


x = [VRDATA.Q_003_UC6.list.TrialNumber]; % extract trial number and logmar score
y = [VRDATA.Q_003_UC6.list.LogMAR];

c1 = [VRDATA.Q_003_UC6.list.EyeCondition] == "Both_Eyes"; % extract eye condition
c2 = [VRDATA.Q_003_UC6.list.EyeCondition] == "Right_Eye";
c3 = [VRDATA.Q_003_UC6.list.EyeCondition] == "Left_Eye";

x1 = x(c1); % match logmar score to condition
y1 = y(c1);
yy1 = y1(end-20:end);

x2 = x(c2);
y2 = y(c2);
yy2 = y2(end-20:end);

x3 = x(c3);
y3 = y(c3);
yy3 = y3(end-20:end);

real_both = 0.96; % real logmar score
real_right = 0.95;
real_left = 0.96;

a1 = mean(y1(end-20:end)); % mean of VR logmar score (average last 20 trials)
a2 = mean(y2(end-20:end));
a3 = mean(y3(end-20:end));

ci1 = fitdist(yy1', 'normal');
ci2 = fitdist(yy2', 'normal');
ci3 = fitdist(yy3', 'normal');


fontSize = 12; 
set(groot,'defaultAxesFontSize', fontSize)
set(groot,'defaultTextFontSize', fontSize)

set(groot,'defaultAxesLineWidth',1)
set(groot,'defaultLineLineWidth',2.5)
set(groot,'defaultAxesTickDir', 'out');
set(groot,'defaultAxesTickDirMode', 'manual');

%% plot test


fig = figure;
t = tiledlayout(1,3);

ax1 = nexttile;

plot(ax1,x3,y3,'LineWidth',1) % left eyes plot
yline(real_left,'r','LineWidth',2)  % line of real score
yline(a3,'--m','LineWidth',2) % line of average VR score

ylim(yl)
title('Left eyes')

% The resolution of the Quest 2 is 20 pixels/degree
% so, 10 cycles/degree, or log10(30/cycpdeg) logMar
yline(log10(30/10),'LineWidth',1) % Quest 2
% yline(log10(30/12.5),'r','LineWidth',1) % Quest 3
yregion(ci3.mu - ci3.sigma,ci3.mu +ci3.sigma,'FaceColor','g','EdgeColor','k')



ax2 = nexttile; % both eye plot
plot(ax2,x1,y1,'LineWidth',1)
yline(real_both,'r','LineWidth',2) 
yline(a1,'--m','LineWidth',2)
yline(log10(30/10),'LineWidth',1) % Quest 2
yregion(ci1.mu - ci1.sigma,ci1.mu +ci1.sigma,'FaceColor','g','EdgeColor','k')
ylim(yl)
title('Both eyes')



ax3 = nexttile; % right eye plot
plot(ax3,x2,y2,'LineWidth',1)
yline(real_right,'r','LineWidth',2) 
yline(a2,'--m','LineWidth',2)
yline(log10(30/10),'LineWidth',1) % Quest 2
yregion(ci2.mu - ci2.sigma,ci2.mu +ci2.sigma,'FaceColor','g','EdgeColor','k')
legend('VR','eyechart', 'VR average', 'quest 2 limit', 'Location', 'northeastoutside')
ylim(yl)
title('Right eye')

Ax = gca;
ytix = Ax.YTick; % tick location
ytl = string((1./(10.^ytix))*30); % tick label
ytl = extractBefore(ytl, min(3, ytl.strlength())+1); % truncate strings
text(ones(size(ytix))*max(xlim)+0.08*diff(xlim), ytix, ytl, 'Horiz','left', 'Vert','middle', 'Fontsize', fontSize)



xlabel(t,'Trial number')
ylabel(t,'Acuity (logMAR)')

% Create a common ylabel on the right side
annotation('textbox',[1 .4 .5 .1], ...
    'String','Acuity (cyc/deg)','EdgeColor','none', 'Rotation', 90, 'FontSize', fontSize)

% Adjust the figure's position to make room for the ylabel
fig.Position(3) = fig.Position(3) + .1; % does not currently work

%% stats stuff
% input real and average vr data manually
% s.realuc = [0.82 0.86 0.94 0.9 1 0.92 0.62 0.54 0.8 0.96 0.9 0.96 0.82 0.86 0.92];
s.realall = [0.82 0.86 0.94 0 0 0.02 -0.1 0.04 0.02 0.9 1 0.92 -0.04 0.08 0.02 0.1 0 0.1 -0.1 -0.06 -0.06 -0.2 -0.14 0.24 -0.02 0.16 -0.1 0.62 0.54 0.8 0.96 0.9 0.96 0.82 0.86 0.92 -0.06 -0.02 0.06];
% s.vruc = [0.665497261918232 0.750300732266265 0.763311606785522 0.878368248556045 1.044014133751761 0.848559040157549 0.490120243926443 0.528723041978598 0.772323108065766 0.891009414178191 0.874557659847996 0.895669638661807 0.583411264571096 0.634869161284951 0.839547669133916];
s.vrall = [0.665497261918232 0.750300732266265 0.763311606785522 0.511119184059796 0.676288799375090 0.676288799375090 0.461175974933904 0.448014772056905 0.508994051604219 0.878368248556045 1.044014133751761 0.848559040157549 0.344963558816919 0.410338024033777 0.409680505491749 0.452044167722371 0.460406194148358 0.510208969938377 0.438672456198216 0.506219309296467 0.501491072476946 0.461504781057158 0.472095399703105 0.622153089897715 0.548618153749264 0.459622033169327 0.454192000057477 0.490120243926443 0.528723041978598 0.772323108065766 0.891009414178191 0.874557659847996 0.895669638661807 0.583411264571096 0.634869161284951 0.839547669133916 0.404905950477337 0.439625371447288 0.436903653647372];
Rall = corrcoef(s.realall,s.vrall); % calculate correlation between real and vr
rsq = Rall(2,1)^2

% xx = s.vrall' testing confidence interval
% xx1 = xx & xx < 0.5
% xx2 = xx(xx1)
% ci = fitdist(xx2, 'Normal');

figure % scatter real and vr results (all)
scatter(s.realall,s.vrall,'filled')
xlabel('Eyechart acuity (logMAR)')
ylabel('VR acuity (logMAR)')
xlim([-0.3 1.1])
ylim([-0.3 1.1])
line([-.3 1.1], [-.3 1.1]) % identity (perfect performance)
lsline

% The resolution of the Quest 2 is 20 pixels/degree
% so, 10 cycles/degree, or log10(30/cycpdeg) logMar
yline(log10(30/10),'LineWidth',1) % Quest 2
yline(log10(30/12.5),'r','LineWidth',1) % Quest 3
legend('data','perfect performance', 'least square line', 'quest 2 limit','quest 3 limit','Location', 'northeastoutside')



