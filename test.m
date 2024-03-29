% Description of script
% clear all
close all
clc

%% Loop to put all VR data in a struct
VRDATA = []; % initialize struct
f = dir('*C6.json'); % get all data files relevant
fnames = string({f.name}); % transform to string array
for k = 1:length(fnames) % loop to get data files into one struct 
    fname = fnames(k); % get one file
    ch = char(fnames(k)); % transform to character array to store into fields
    VRDATA.(ch(1:end-5)) = readstruct(fname); % read data file into struct

end
%% set up variables for plotting
yl = [-0.3 1.1]; % set y limit
ylc = [2.4 60];

x = [VRDATA.Ben_UC6.list.TrialNumber]; % extract trial number and logmar score
y = [VRDATA.Ben_UC6.list.LogMAR];

c1 = [VRDATA.Ben_UC6.list.EyeCondition] == "Both_Eyes"; % extract eye condition
c2 = [VRDATA.Ben_UC6.list.EyeCondition] == "Right_Eye";
c3 = [VRDATA.Ben_UC6.list.EyeCondition] == "Left_Eye";

x1 = x(c1); % match logmar score to condition
y1 = y(c1);
cy1 = (1./(10.^y1))*30;

x2 = x(c2);
y2 = y(c2);
cy2 = (1./(10.^y2))*30;

x3 = x(c3);
y3 = y(c3);
cy3 = (1./(10.^y3))*30;

real_both = -0.2; % real logmar score
real_right = 0.24;
real_left = -0.14;

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
figure
t = tiledlayout(1,3);
ax1 = nexttile;
yyaxis left
plot(ax1,x1,y1,'LineWidth',1) % both eyes plot
yline(real_both,'r','LineWidth',2)  % line of real score
yline(a1,'--m','LineWidth',2) % line of average VR score
yline(abs(a1-real_both),'-.g','LineWidth',2) % line of offset
legend('VR LogMar score','real score', 'VR average','offset' )
ylim(yl)
title('Both eyes VR visual acuity performance')
yyaxis right % add cycles per degree on the right y axis
plot(x1,cy1,'LineWidth',1)
ylabel('cycles per degree')
ylim(ylc)
set(gca, 'YDir','reverse') % flip the right y axis

ax2 = nexttile; % right eye plot
plot(ax2,x2,y2,'LineWidth',1)
yline(real_right,'r','LineWidth',2) 
yline(a2,'--m','LineWidth',2)
yline(abs(a2-real_right),'-.g','LineWidth',2)
legend('VR LogMar score','real score', 'VR average','offset' )
ylim(yl)
title('Right eye VR visual acuity performance')
yyaxis right
plot(x2,cy2,'LineWidth',1)
ylim(ylc)
set(gca, 'YDir','reverse')

ax3 = nexttile; % left eye plot
plot(ax3,x3,y3,'LineWidth',1)
yline(real_left,'r','LineWidth',2) 
yline(a3,'--m','LineWidth',2)
yline(abs(a3-real_left),'-.g','LineWidth',2)
legend('VR LogMar score','real score', 'VR average','offset' )
ylim(yl)
title('Left eye VR visual acuity performance')
yyaxis right
plot(x3,cy3,'LineWidth',1)
ylim(ylc)
set(gca, 'YDir','reverse')

xlabel(t,'trial number')
ylabel(t,'VR logmar score')

%% stats stuff
s.real = [-0.200000000000000	0.240000000000000	-0.140000000000000 0.1 0 0.1 -0.1 -0.06 -0.06 -0.04 0.08 0.02 0.62 0.54 0.8 ];
s.vr = [0.461504781057158	0.472095399703105	0.622153089897715 0.452044167722371 0.460406194148358 0.510208969938377 0.438672456198216 0.501491072476946 0.506219309296467 0.344963558816919 0.410338024033777 0.409680505491749 0.490120243926443 0.772323108065766 0.528723041978598];
R = corrcoef(s.real,s.vr)

figure
scatter(s.real,s.vr,'filled')
xlabel('real logmar score')
ylabel('VR logmar score')
xlim([-0.3 1.1])
ylim([-0.3 1.1])
lsline
%%
% for k = 1:length(fnames) % loop to get data files into one struct 
%     fname = fnames(k); % get one file
%     ch = char(fnames(k)); % transform to character array to store into fields
%     s.vr.(ch(1:end-5)) = 
