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

%% Loop to put all VR data in a struct
VRDATA = []; % initialize struct

% TODO: Read in specific subs, specified in cell array
% sub = 'AR_002_C6'; % subject id
% dataDir = '../data';
f = dir('../data/*C6.json'); % get relevant data files 
% fnames = string({f.name}); % transform to string array
for k = 1:length(f) % loop to get data files into struct 
    fname = fullfile(f(k).folder, f(k).name); % get one file
    % ch = char(f(k).name); % transform to character array to store into fields
    % VRDATA.(ch(1:end-5)) = readstruct(fname); % read data file into struct
    VRDATA{k} = readstruct(fname); % read data file into struct
end

%% set up variables for plotting

for k = 1:length(f)
x = [VRDATA{k}.list.TrialNumber]; % extract trial number and logmar score
y = [VRDATA{k}.list.LogMAR];

c1 = [VRDATA{k}.list.EyeCondition] == "Both_Eyes"; % extract eye condition
c2 = [VRDATA{k}.list.EyeCondition] == "Right_Eye";
c3 = [VRDATA{k}.list.EyeCondition] == "Left_Eye";

x1 = x(c1); % match logmar score to condition
y1 = y(c1);
% cy1 = (1./(10.^y1))*30;

x2 = x(c2);
y2 = y(c2);
% cy2 = (1./(10.^y2))*30;

x3 = x(c3);
y3 = y(c3);
% cy3 = (1./(10.^y3))*30;

% Where does this data come from? Is subject specific
real_both = -0.1; % real logmar score
real_right = 0.04;
real_left = 0.02;

a1 = mean(y1(end-20:end)); % mean of VR logmar score (average last 20 trials)
a2 = mean(y2(end-20:end));
a3 = mean(y3(end-20:end));

%% plot 
% figure
% subplot(1,3,1) % both eyes plot
% plot(x1,y1,'LineWidth',1)
% yline(real_both,'r','LineWidth',2)  % line of real score
% yline(a1,'--m','LineWidth',2) % line of average VR score
% yline(abs(a1-real_both),'-.g','LineWidth',2) % line of offset
% legend('VR LogMar score','real score', 'VR average','offset' )
% ylim(yl)
% xlabel('trial number')
% ylabel('logmar score')
% title('Both eyes VR visual acuity performance')
% 
% subplot(1,3,2) % right eye plot
% plot(x2,y2,'LineWidth',1)
% yline(real_right,'r','LineWidth',2) 
% yline(a2,'--m','LineWidth',2)
% yline(abs(a2-real_right),'-.g','LineWidth',2)
% legend('VR LogMar score','real score', 'VR average','offset' )
% ylim(yl)
% xlabel('trial number')
% ylabel('logmar score')
% title('Right eye VR visual acuity performance')
% 
% subplot(1,3,3) % left eye plot
% plot(x3,y3,'LineWidth',1)
% yline(real_left,'r','LineWidth',2) 
% yline(a3,'--m','LineWidth',2)
% yline(abs(a3-real_left),'-.g','LineWidth',2)
% legend('VR LogMar score','real score', 'VR average','offset' )
% ylim(yl)
% xlabel('trial number')
% ylabel('logmar score')
% title('Left eye VR visual acuity performance')

%% plot test

fig = figure;
yl = [-0.3 1.1]; % set y limit (logMAR)

t = tiledlayout(1,3);

ax1 = nexttile;
% yyaxis left
ph = plot(ax1,x3,y3,'LineWidth',2); % left eyes plot
% yline(real_left,'r','LineWidth',2)  % line of ETDRS score
lh = yline(a3,'LineWidth',2); % line of average VR score
lh.Color = ph.Color;
% legend('VR LogMar score','real score', 'VR average','offset' )
ylim(yl)
title('Left eye')

% The resolution of the Quest 2 is 20 pixels/degree
% so, 10 cycles/degree, or log10(30/cycpdeg) logMar
yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1, 'FontSize', fontSize) % Quest 2
% yline(log10(30/12.5),'--','Meta Q3', 'LineWidth',1, 'FontSize', fontSize) % Quest 3

% yyaxis right % add cycles per degree on the right y axis
% plot(x1,cy1,'LineWidth',1)
% ylabel('cycles per degree')
% ylim(ylc)
% set(gca, 'YDir','reverse') % flip the right y axis

ax2 = nexttile; % both eye plot
plot(ax2,x1,y1,'LineWidth',2)
% yline(real_both,'r','LineWidth',2) 
lh = yline(a1,'LineWidth',2);
lh.Color = ph.Color;
% yline(abs(a2-real_right),'-.g','LineWidth',2)
% legend('VR LogMar score','real score', 'VR average','offset' )
ylim(yl)
title('Both eyes')

yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1, 'FontSize', fontSize) % Quest 2
% yyaxis right
% plot(x2,cy2,'LineWidth',1)
% ylim(ylc)
% set(gca, 'YDir','reverse')

ax3 = nexttile; % right eye plot
plot(ax3,x2,y2,'LineWidth',2)
% yline(real_right,'r','LineWidth',2) 
lh = yline(a2,'LineWidth',2);
lh.Color = ph.Color;

% yline(abs(a3-real_left),'-.g','LineWidth',2)
% legend('VR','eyechart', 'VR average', 'Location', 'southeast')
% legend('VR', 'Average', '', 'Location', 'southeast')

ylim(yl)
title('Right eye')

yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1, 'FontSize', fontSize) % Quest 2

xlabel(t,'Trial number', 'FontSize', fontSize)
ylabel(t,'Sloan font size (logMAR)', 'FontSize', fontSize)

% Add right hand axis
% Ax = gca;
% ytix = Ax.YTick; % tick location
% ytl = string((1./(10.^ytix))*30); % tick label
% ytl = extractBefore(ytl, min(3, ytl.strlength())+1); % truncate strings
% text(ones(size(ytix))*max(xlim)+0.08*diff(xlim), ytix, ytl, 'Horiz','left', 'Vert','middle', 'Fontsize', fontSize)

% yyaxis right
% plot(x3,cy3,'LineWidth',1)
% ylim(ylc)
% set(gca, 'YDir','reverse')

% Create a common ylabel on the right side
% annotation('textbox',[1 .4 .5 .1], ...
%     'String','Acuity (cyc/deg)','EdgeColor','none', 'Rotation', 90, 'FontSize', fontSize)

% Adjust the figure's position to make room for the ylabel
% fig.Position(3) = fig.Position(3) + .1; % does not currently work

%% stats stuff
% input real and average vr data manually
% s.realuc = [0.82 0.86 0.94 0.9 1 0.92 0.62 0.54 0.8 0.96 0.9 0.96 0.82 0.86 0.92];
s.realall = [0.82 0.86 0.94 0 0 0.02 -0.1 0.04 0.02 0.9 1 0.92 -0.04 0.08 0.02 0.1 0 0.1 -0.1 -0.06 -0.06 -0.2 -0.14 0.24 -0.02 0.16 -0.1 0.62 0.54 0.8 0.96 0.9 0.96 0.82 0.86 0.92 -0.06 -0.02 0.06];
% s.vruc = [0.665497261918232 0.750300732266265 0.763311606785522 0.878368248556045 1.044014133751761 0.848559040157549 0.490120243926443 0.528723041978598 0.772323108065766 0.891009414178191 0.874557659847996 0.895669638661807 0.583411264571096 0.634869161284951 0.839547669133916];
s.vrall = [0.665497261918232 0.750300732266265 0.763311606785522 0.511119184059796 0.676288799375090 0.676288799375090 0.461175974933904 0.448014772056905 0.508994051604219 0.878368248556045 1.044014133751761 0.848559040157549 0.344963558816919 0.410338024033777 0.409680505491749 0.452044167722371 0.460406194148358 0.510208969938377 0.438672456198216 0.506219309296467 0.501491072476946 0.461504781057158 0.472095399703105 0.622153089897715 0.548618153749264 0.459622033169327 0.454192000057477 0.490120243926443 0.528723041978598 0.772323108065766 0.891009414178191 0.874557659847996 0.895669638661807 0.583411264571096 0.634869161284951 0.839547669133916 0.404905950477337 0.439625371447288 0.436903653647372];
Rall = corrcoef(s.realall,s.vrall); % calculate correlation between real and vr
% Ruc = corrcoef(s.realuc,s.vruc);

exportgraphics(fig, join(['sub-' VRDATA{k}.list(1).Username '_cond-VR_treshold.pdf'], ''))

end

%% Plot summary figure across subjects
fig2 = figure; % scatter real and vr results (all)
markerSize = 50;
sp = scatter(s.realall,s.vrall, markerSize,'filled');
xlabel('ETDRS eyechart acuity (logMAR)')
ylabel('VR acuity (logMAR)')
axis square
xlim([-0.3 1.1])
ylim([-0.3 1.1])
line([-.3 1.1], [-.3 1.1],'Color','k', 'LineWidth', 1) % identity (perfect performance)
% ls = lsline;
% ls.Color = sp.CData; % set line to same color as dots

% The resolution of the Quest 2 is 20 pixels/degree
% so, 10 cycles/degree, or log10(30/cycpdeg) logMar
yline(log10(30/(9.81/2)),'--','Rift CV1', 'LineWidth',1,'FontSize', fontSize, 'LabelHorizontalAlignment','left') 
yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize) % Quest 2
yline(log10(30/12.5),'--','Meta Q3', 'LineWidth',1,'FontSize', fontSize) % Quest 3
yline(log10(30/(34/2)),'--','Apple VP', 'LineWidth',1,'FontSize', fontSize) 
yline(log10(30/(51/2)),'--','Varjo XR4', 'LineWidth',1,'FontSize', fontSize) 

exportgraphics(fig2, 'acuity_vr_vs_chart.pdf')
% figure % scatter real and vr results (only uncorrected)
% scatter(s.realuc,s.vruc,'filled')
% xlabel('Eyechart acuity (logMAR)')
% ylabel('VR acuity (logMAR)')
% xlim([-0.3 1.1])
% ylim([-0.3 1.1])
% line([-.3 1.1], [-.3 1.1]) % identity (perfect performance)
% lsline
%%
% for k = 1:length(fnames) % loop to get data files into one struct 
%     fname = fnames(k); % get one file
%     ch = char(fnames(k)); % transform to character array to store into fields
%     s.vr.(ch(1:end-5)) = 