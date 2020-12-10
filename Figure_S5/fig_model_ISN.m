% one column with one excitatory population and one PV+ population, with multiple
% neurons: model figure S5
%

clear;

% time parameters
t0=0;
tmax=0.4;
tstep=0.001;
t=t0:tstep:tmax;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% network parameters
tau_ex=0.01;         % synaptic time constant (10ms)
tau_pv=0.01;         % synaptic time constant (10ms)

supra_n = 2.;        % supra non-linearity

% functions
heavisd = @(x) x>0;                 % heaviside function definition, including h(0)=0
thresh_lin= @(x) heavisd(x).*x;     % threshold linear with no saturation function definition, including h(0)=0
gaus_fun = @(x,mu,sigm) exp(-((x-mu).^2)/(2*sigm^2))/sqrt(2*pi*sigm^2);
iofunc_E = @(x) thresh_lin(x).^supra_n;
iofunc_I = @(x) thresh_lin(x).^supra_n;

% number of excitatory and inhibitory neurons
n_exc = 400;
n_inh = 100;

seed = 73;
rng(seed);

% external input to excitatory and inhibitory cells
h_exc = 2*rand(n_exc,1);
h_inh = 2*rand(n_inh,1);

% connectivity
sparsity = 0;
wexex_1 = rand(n_exc);
wpvex_1 = rand(n_inh,n_exc);
wexpv_1 = rand(n_exc,n_inh);
wpvpv_1 = rand(n_inh);
wexex_2 = .7/n_exc;
wpvex_2 = 4.6/n_exc;
wexpv_2 = -.3/n_inh;
wpvpv_2 = -1.7/n_inh;
wexex_3 = rand(n_exc);
wpvex_3 = rand(n_inh,n_exc);
wexpv_3 = rand(n_exc,n_inh);
wpvpv_3 = rand(n_inh);

wexex = wexex_2*wexex_1.*(wexex_3>sparsity);
wpvex = wpvex_2*wpvex_1.*(wpvex_3>sparsity);
wexpv = wexpv_2*wexpv_1.*(wexpv_3>sparsity);
wpvpv = wpvpv_2*wpvpv_1.*(wpvpv_3>sparsity);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
E1 = 10;    % auditory stimulus maximum magnitude

% number of stimulus frequencies
m=15;

% characteristic frequency
charact_freq = 8;

% window onset response
win_onset = [round(0.1/tstep),round(0.19/tstep)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SSFO stimulation of PV+: degree of heterogeneity (mn-a)/sqrt(3)
ssfo_min = [0 .1];
ssfo_mn = [0 1.9];
ssfo_mat = ones(n_inh,1)*ssfo_min + 2*rand(n_inh,1)*(ssfo_mn-ssfo_min);

num_exp = length(ssfo_min);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% magnitude of neural or synaptic noise
nois_fact = 0.03; % 0.01

nois_exc_mat = nois_fact*randn(n_exc,m,length(t),num_exp)/sqrt(tstep);
nois_inh_mat = nois_fact*randn(n_inh,m,length(t),num_exp)/sqrt(tstep);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simulate network
X = zeros(n_exc,m);
Y = zeros(n_inh,m);
X_PV_SSFO = zeros(n_exc,m);
Y_PV_SSFO = zeros(n_inh,m);

input_X = zeros(n_exc,m);
input_Y = zeros(n_inh,m);
input_X_PV_SSFO = zeros(n_exc,m);
input_Y_PV_SSFO = zeros(n_inh,m);

X_exc = zeros(n_exc,m);
X_inh = zeros(n_exc,m);
Y_exc = zeros(n_inh,m);
Y_inh = zeros(n_inh,m);
X_exc_PV_SSFO = zeros(n_exc,m);
X_inh_PV_SSFO = zeros(n_exc,m);
Y_exc_PV_SSFO = zeros(n_inh,m);
Y_inh_PV_SSFO = zeros(n_inh,m);

% column i has the highest thalamic input
for kk=1:1:num_exp
    for i=1:m
        x=zeros(n_exc,length(t));
        y=zeros(n_inh,length(t));
        input_x=zeros(n_exc,length(t));
        input_y=zeros(n_inh,length(t));
        x_exc=zeros(n_exc,length(t));
        x_inh=zeros(n_exc,length(t));
        y_exc=zeros(n_inh,length(t));
        y_inh=zeros(n_inh,length(t));

        burst=zeros(1,length(t));
        burst(round(0.1/tstep):round(0.2/tstep)) = gaus_fun(i,charact_freq,3)*exp(-(0:tstep:0.1)/.05);
        
        for j=2:length(t)
            nois_exc = nois_exc_mat(:,i,j,kk);
            nois_inh = nois_inh_mat(:,i,j,kk);
            input_x(:,j-1) = wexex*x(:,j-1) + wexpv*y(:,j-1) + E1*burst(j-1) + h_exc + nois_exc;
            input_y(:,j-1) = wpvex*x(:,j-1) + wpvpv*y(:,j-1) + E1*burst(j-1) + ssfo_mat(:,kk) + h_inh + nois_inh;
            x(:,j)=x(:,j-1)+tstep*(-x(:,j-1)+iofunc_E( input_x(:,j-1) ))/tau_ex;
            y(:,j)=y(:,j-1)+tstep*(-y(:,j-1)+iofunc_I( input_y(:,j-1) ))/tau_pv;
            
            x_exc(:,j-1) = wexex*x(:,j-1) + E1*burst(j-1) + thresh_lin(h_exc) + thresh_lin(nois_exc);
            x_inh(:,j-1) = wexpv*y(:,j-1) - thresh_lin(-h_exc) - thresh_lin(-nois_exc);
            y_exc(:,j-1) = wpvex*x(:,j-1) + E1*burst(j-1) + ssfo_mat(:,kk) + thresh_lin(h_inh) + thresh_lin(nois_inh);
            y_inh(:,j-1) = wpvpv*y(:,j-1) - thresh_lin(-h_inh) - thresh_lin(-nois_inh);
        end

        if kk==1
            X(:,i) = mean(x(:,win_onset(1):win_onset(2)),2);
            Y(:,i) = mean(y(:,win_onset(1):win_onset(2)),2);
            input_X(:,i) = mean(input_x(:,win_onset(1):win_onset(2)),2);
            input_Y(:,i) = mean(input_y(:,win_onset(1):win_onset(2)),2);
            X_exc(:,i) = mean(x_exc(:,win_onset(1):win_onset(2)),2);
            X_inh(:,i) = mean(x_inh(:,win_onset(1):win_onset(2)),2);
            Y_exc(:,i) = mean(y_exc(:,win_onset(1):win_onset(2)),2);
            Y_inh(:,i) = mean(y_inh(:,win_onset(1):win_onset(2)),2);
        
        elseif kk==2
            X_PV_SSFO(:,i) = mean(x(:,win_onset(1):win_onset(2)),2);
            Y_PV_SSFO(:,i) = mean(y(:,win_onset(1):win_onset(2)),2);
            input_X_PV_SSFO(:,i) = mean(input_x(:,win_onset(1):win_onset(2)),2);
            input_Y_PV_SSFO(:,i) = mean(input_y(:,win_onset(1):win_onset(2)),2);
            X_exc_PV_SSFO(:,i) = mean(x_exc(:,win_onset(1):win_onset(2)),2);
            X_inh_PV_SSFO(:,i) = mean(x_inh(:,win_onset(1):win_onset(2)),2);
            Y_exc_PV_SSFO(:,i) = mean(y_exc(:,win_onset(1):win_onset(2)),2);
            Y_inh_PV_SSFO(:,i) = mean(y_inh(:,win_onset(1):win_onset(2)),2);
        end
        
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% activity change
exc_change = zeros(1,n_exc);
for i = 1:n_exc
    tuning_off = X(i,:);
    tuning_on = X_PV_SSFO(i,:);
    [max_off,ind_max_off] = max(tuning_off);
    exc_change(i) = 100*(tuning_on(ind_max_off)-max_off)/max_off;
end

inh_change = zeros(1,n_inh);
for i = 1:n_inh
    tuning_off = Y(i,:);
    tuning_on = Y_PV_SSFO(i,:);
    [max_off,ind_max_off] = max(tuning_off);
    inh_change(i) = 100*(tuning_on(ind_max_off)-max_off)/max_off;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% slope and intercept of SSFO-on tuning vs control tuning

% excitatory neurons
slope_on = zeros(1,n_exc);
intercept_on = zeros(1,n_exc);
s_slope_on = zeros(1,n_exc);
s_intercept_on = zeros(1,n_exc);
slope_on_input = zeros(1,n_exc);
intercept_on_input = zeros(1,n_exc);
for i = 1:n_exc
    tuning_off = X(i,:);
    tuning_off_input = input_X(i,:);
    tuning_on = X_PV_SSFO(i,:);
    tuning_on_input = input_X_PV_SSFO(i,:);
    max_tuning = max(tuning_off);
    max_tuning_input = max(tuning_off_input);
       
    % normalize
    tuning_off = tuning_off/max_tuning;
    tuning_off_input = tuning_off_input/max_tuning_input;
    tuning_on = tuning_on/max_tuning;
    tuning_on_input = tuning_on_input/max_tuning_input;
    
    % exclude low activities. Note that if PV+ activation is high,
    % activities can become very low and thus many samples might be
    % eliminated, which will bias these regressions
    invalid = tuning_on < 0.05 | tuning_off < 0.05;
    invalid_input = abs(tuning_on_input) < 0.05 | abs(tuning_off_input) < 0.05;
    tuning_off(invalid) = [];
    tuning_on(invalid) = [];
    tuning_off_input(invalid_input) = [];
    tuning_on_input(invalid_input) = [];
    
    num_samples = sum(~invalid);
    num_samples_input = sum(~invalid_input);
        
    % regression for low SSFO activation magnitude
    [slope_on1,intercept_on1,~,sm1,sb1] = lsqfitma(tuning_off',tuning_on');
    slope_on(i) = slope_on1;
    intercept_on(i) = intercept_on1;
    s_slope_on(i) = sm1;
    s_intercept_on(i) = sb1;
    
    if ~isnan(slope_on1) && ~isnan(sm1) && sm1>0
        pval_slope(i) = testMaRegress(slope_on1,sm1,1,num_samples,'right');
    end

    if ~isnan(intercept_on1) && ~isnan(sb1) && sb1>0
        pval_intercept(i) = testMaRegress(intercept_on1,sb1,0,num_samples,'right');
    end
    
    
    % regression for inputs of low SSFO activation magnitude
    [slope_on1,intercept_on1,~,sm1,sb1] = lsqfitma(tuning_off_input',tuning_on_input');
    slope_on_input(i) = slope_on1;
    intercept_on_input(i) = intercept_on1;
    
    if ~isnan(slope_on1) && ~isnan(sm1) && sm1>0
        pval_slope_input(i) = testMaRegress(slope_on1,sm1,1,num_samples_input,'right');
    end

    if ~isnan(intercept_on1) && ~isnan(sb1) && sb1>0
        pval_intercept_input(i) = testMaRegress(intercept_on1,sb1,0,num_samples_input,'right');
    end
end

% inhibitory neurons
slope_on_y = zeros(1,n_inh);
intercept_on_y = zeros(1,n_inh);
s_slope_on_y = zeros(1,n_inh);
s_intercept_on_y = zeros(1,n_inh);
slope_on_y_input = zeros(1,n_inh);
intercept_on_y_input = zeros(1,n_inh);
for i = 1:n_inh
    tuning_off = Y(i,:);
    tuning_off_input = input_Y(i,:);
    tuning_on = Y_PV_SSFO(i,:);
    tuning_on_input = input_Y_PV_SSFO(i,:);
    max_tuning = max(tuning_off);
    max_tuning_input = max(tuning_off_input);
       
    % normalize
    tuning_off = tuning_off/max_tuning;
    tuning_off_input = tuning_off_input/max_tuning_input;
    tuning_on = tuning_on/max_tuning;
    tuning_on_input = tuning_on_input/max_tuning_input;
    
    % exclude low activities. Note that if PV+ activation is high,
    % activities can become very low and thus many samples might be
    % eliminated, which will bias these regressions
    invalid = tuning_on < 0.05 | tuning_off < 0.05;
    invalid_input = abs(tuning_on_input) < 0.05 | abs(tuning_off_input) < 0.05;
    tuning_off(invalid) = [];
    tuning_on(invalid) = [];
    tuning_off_input(invalid_input) = [];
    tuning_on_input(invalid_input) = [];
    
    num_samples = sum(~invalid);
    num_samples_input = sum(~invalid_input);
        
    % regression for low SSFO activation magnitude
    [slope_on1,intercept_on1,~,sm1,sb1] = lsqfitma(tuning_off',tuning_on');
    slope_on_y(i) = slope_on1;
    intercept_on_y(i) = intercept_on1;
    s_slope_on_y(i) = sm1;
    s_intercept_on_y(i) = sb1;
    
    if ~isnan(slope_on1) && ~isnan(sm1) && sm1>0
        pval_slope_y(i) = testMaRegress(slope_on1,sm1,1,num_samples,'right');
    end

    if ~isnan(intercept_on1) && ~isnan(sb1) && sb1>0
        pval_intercept_y(i) = testMaRegress(intercept_on1,sb1,0,num_samples,'right');
    end
    
    
    % regression for inputs of low SSFO activation magnitude
    [slope_on1,intercept_on1,~,sm1,sb1] = lsqfitma(tuning_off_input',tuning_on_input');
    slope_on_y_input(i) = slope_on1;
    intercept_on_y_input(i) = intercept_on1;
    
    if ~isnan(slope_on1) && ~isnan(sm1) && sm1>0
        pval_slope_y_input(i) = testMaRegress(slope_on1,sm1,1,num_samples_input,'right');
    end

    if ~isnan(intercept_on1) && ~isnan(sb1) && sb1>0
        pval_intercept_y_input(i) = testMaRegress(intercept_on1,sb1,0,num_samples_input,'right');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% divisive, subtractive, both or none
divisive_effect = @(x,y) mean(x>=0.05&y<0.05);
subtractive_effect = @(x,y) mean(x<0.05&y>=0.05);
both_effect = @(x,y) mean(x<0.05&y<0.05);
none_effect = @(x,y) mean(x>=0.05&y>=0.05);

ssfo_effect = zeros(4,1);
ssfo_effect(1) = divisive_effect(pval_intercept,pval_slope);
ssfo_effect(2) = subtractive_effect(pval_intercept,pval_slope);
ssfo_effect(3) = both_effect(pval_intercept,pval_slope);
ssfo_effect(4) = none_effect(pval_intercept,pval_slope);

ssfo_effect_input = zeros(4,1);
ssfo_effect_input(1) = divisive_effect(pval_intercept_input,pval_slope_input);
ssfo_effect_input(2) = subtractive_effect(pval_intercept_input,pval_slope_input);
ssfo_effect_input(3) = both_effect(pval_intercept_input,pval_slope_input);
ssfo_effect_input(4) = none_effect(pval_intercept_input,pval_slope_input);

ssfo_effect_y = zeros(4,1);
ssfo_effect_y(1) = divisive_effect(pval_intercept_y,pval_slope_y);
ssfo_effect_y(2) = subtractive_effect(pval_intercept_y,pval_slope_y);
ssfo_effect_y(3) = both_effect(pval_intercept_y,pval_slope_y);
ssfo_effect_y(4) = none_effect(pval_intercept_y,pval_slope_y);

ssfo_effect_y_input = zeros(4,1);
ssfo_effect_y_input(1) = divisive_effect(pval_intercept_y_input,pval_slope_y_input);
ssfo_effect_y_input(2) = subtractive_effect(pval_intercept_y_input,pval_slope_y_input);
ssfo_effect_y_input(3) = both_effect(pval_intercept_y_input,pval_slope_y_input);
ssfo_effect_y_input(4) = none_effect(pval_intercept_y_input,pval_slope_y_input);

ssfo_effect_all = (ssfo_effect*n_exc+ssfo_effect_y*n_inh)/(n_exc+n_inh);
ssfo_effect_all_input = (ssfo_effect_input*n_exc+ssfo_effect_y_input*n_inh)/(n_exc+n_inh);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% paper figure S5
clf(figure(1))

freq_mat = (1:1:m)-charact_freq;
fontsize_plt = 13;
lw_plt = 1;
markersize = 10;

col_exc = [78,196,164]/255;
col_inh = [252,130,62]/255;
col_inh_min = [255,250,248]/255;

subplot(431)
[xx,ind_xx] = sort(X,2);
yy = X_PV_SSFO;
for i=1:n_exc
    yy(i,:) = yy(i,ind_xx(i,:));
end
plot(xx',yy','.','markersize',markersize,'color',col_exc); hold on;
plot([0 max(xx(:))],[0 max(xx(:))],'--k','linewidth',1)
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel({'rate',' control [Hz]'})
ylabel({'rate',' PV-SSFO [Hz]'})
box off

subplot(432)
[~,ind_e2] = sort(ssfo_mat(:,2));
x_col = linspace(0,1,n_inh);
x_lim = [min(x_col);max(x_col)];
col2 = interp1(x_lim,[col_inh_min; col_inh],x_col);
col1 = colormap(gca,col2);
[xx,ind_xx] = sort(Y,2);
yy = Y_PV_SSFO;
for i=1:n_inh
    j = ind_e2(i);
    yy(j,:) = yy(j,ind_xx(j,:));
    plot(xx(j,:)',yy(j,:)','color',col1(i,:),'linewidth',2); hold on;
end

plot([0 max(xx(:))],[0 max(xx(:))],'--k','linewidth',1)
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel({'rate',' control [Hz]'})
ylabel({'rate',' PV-SSFO [Hz]'})
box off


subplot(433)
b11 = bar([ssfo_effect ssfo_effect_y ssfo_effect_all],'hist'); hold on;
set(b11(1),'FaceColor',col_exc,'edgecolor',[1 1 1])
set(b11(2),'FaceColor',col_inh,'edgecolor',[1 1 1])
set(b11(3),'FaceColor',[.5 .5 .5],'edgecolor',[1 1 1])
set(gca,'XTickLabel',{'Div','Sub','Both','None'})
set(gca,'tickdir','out','fontsize',10,'linewidth',lw_plt,'fontsize',fontsize_plt)
set(gca, 'XTickLabelRotation', 45)
ylabel('fraction')
box off
axis tight
legend('exc','inh','all')
legend('boxoff')


subplot(434)
[xx,ind_xx] = sort(input_X,2);
yy = input_X_PV_SSFO;
for i=1:n_exc
    yy(i,:) = yy(i,ind_xx(i,:));
end
plot(xx',yy','.','markersize',markersize,'color',col_exc); hold on;
plot([0 max(xx(:))],[0 max(xx(:))],'--k','linewidth',1)
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel({'input',' control [Hz]'})
ylabel({'input',' PV-SSFO [Hz]'})
box off

subplot(435)
[~,ind_e2] = sort(ssfo_mat(:,2));
x_col = linspace(0,1,n_inh);
x_lim = [min(x_col);max(x_col)];
col2 = interp1(x_lim,[col_inh_min; col_inh],x_col);
col1 = colormap(gca,col2);
[xx,ind_xx] = sort(input_Y,2);
yy = input_Y_PV_SSFO;
for i=1:n_inh
    j = ind_e2(i);
    yy(j,:) = yy(j,ind_xx(j,:));
    plot(xx(j,:)',yy(j,:)','color',col1(i,:),'linewidth',2); hold on;
end

plot([0 max(xx(:))],[0 max(xx(:))],'--k','linewidth',1)
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel({'input',' control [Hz]'})
ylabel({'input',' PV-SSFO [Hz]'})
box off


subplot(436)
b11 = bar([ssfo_effect_input ssfo_effect_y_input ssfo_effect_all_input],'hist'); hold on;
set(b11(1),'FaceColor',col_exc,'edgecolor',[1 1 1])
set(b11(2),'FaceColor',col_inh,'edgecolor',[1 1 1])
set(b11(3),'FaceColor',[.5 .5 .5],'edgecolor',[1 1 1])
set(gca,'XTickLabel',{'Div','Sub','Both','None'})
set(gca,'tickdir','out','fontsize',10,'linewidth',lw_plt,'fontsize',fontsize_plt)
set(gca, 'XTickLabelRotation', 45)
ylabel('fraction')
box off
axis tight
legend('exc','inh','all')
legend('boxoff')


subplot(437)
cell_num_exc = 1;
plot(freq_mat,X(cell_num_exc,:),'color',col_exc,'linewidth',2); hold on;
plot(freq_mat,X_PV_SSFO(cell_num_exc,:),'--','color',col_exc,'linewidth',2); hold on;
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel('frequency [a.u.]')
ylabel('rate [Hz]')
title('exc reduced')
box off
legend('control','PV-SSFO')
legend('boxoff')

subplot(438)
cell_num_inh = [round(.18*n_inh),round(.71*n_inh)];
plot(freq_mat,Y(ind_e2(cell_num_inh(1)),:),'color',col_inh,'linewidth',2); hold on;
plot(freq_mat,Y_PV_SSFO(ind_e2(cell_num_inh(1)),:),'--','color',col_inh,'linewidth',2); hold on;
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel('frequency [a.u.]')
ylabel('rate [Hz]')
title('inh reduced')
box off

subplot(439)
plot(freq_mat,Y(ind_e2(cell_num_inh(2)),:),'color',col_inh,'linewidth',2); hold on;
plot(freq_mat,Y_PV_SSFO(ind_e2(cell_num_inh(2)),:),'--','color',col_inh,'linewidth',2); hold on;
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel('frequency [a.u.]')
ylabel('rate [Hz]')
title('inh enhanced')
box off

subplot(4,3,10)
plot(freq_mat,X_exc(cell_num_exc,:),'color',col_exc,'linewidth',2); hold on;
plot(freq_mat,-X_inh(cell_num_exc,:),'color',col_inh,'linewidth',2); hold on;
plot(freq_mat,X_exc(cell_num_exc,:)+X_inh(cell_num_exc,:),'k','linewidth',2); hold on;
plot(freq_mat,X_exc_PV_SSFO(cell_num_exc,:),'--','color',col_exc,'linewidth',2); hold on;
plot(freq_mat,-X_inh_PV_SSFO(cell_num_exc,:),'--','color',col_inh,'linewidth',2); hold on;
plot(freq_mat,X_exc_PV_SSFO(cell_num_exc,:)+X_inh_PV_SSFO(cell_num_exc,:),'--k','linewidth',2); hold on;
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel('frequency [a.u.]')
ylabel('input [Hz]')
title('exc. reduced')
box off
legend('exc input control','inh input control','total input control','exc input PV-SSFO','inh input PV-SSFO','total input PV-SSFO')
legend('boxoff')

subplot(4,3,11)
plot(freq_mat,Y_exc(ind_e2(cell_num_inh(1)),:),'color',col_exc,'linewidth',2); hold on;
plot(freq_mat,-Y_inh(ind_e2(cell_num_inh(1)),:),'color',col_inh,'linewidth',2); hold on;
plot(freq_mat,Y_exc(ind_e2(cell_num_inh(1)),:)+Y_inh(ind_e2(cell_num_inh(1)),:),'k','linewidth',2); hold on;
plot(freq_mat,Y_exc_PV_SSFO(ind_e2(cell_num_inh(1)),:),'--','color',col_exc,'linewidth',2); hold on;
plot(freq_mat,-Y_inh_PV_SSFO(ind_e2(cell_num_inh(1)),:),'--','color',col_inh,'linewidth',2); hold on;
plot(freq_mat,Y_exc_PV_SSFO(ind_e2(cell_num_inh(1)),:)+Y_inh_PV_SSFO(ind_e2(cell_num_inh(1)),:),'--k','linewidth',2); hold on;
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel('frequency [a.u.]')
ylabel('input [Hz]')
title('inh. reduced')
box off

subplot(4,3,12)
plot(freq_mat,Y_exc(ind_e2(cell_num_inh(2)),:),'color',col_exc,'linewidth',2); hold on;
plot(freq_mat,-Y_inh(ind_e2(cell_num_inh(2)),:),'color',col_inh,'linewidth',2); hold on;
plot(freq_mat,Y_exc(ind_e2(cell_num_inh(2)),:)+Y_inh(ind_e2(cell_num_inh(2)),:),'k','linewidth',2); hold on;
plot(freq_mat,Y_exc_PV_SSFO(ind_e2(cell_num_inh(2)),:),'--','color',col_exc,'linewidth',2); hold on;
plot(freq_mat,-Y_inh_PV_SSFO(ind_e2(cell_num_inh(2)),:),'--','color',col_inh,'linewidth',2); hold on;
plot(freq_mat,Y_exc_PV_SSFO(ind_e2(cell_num_inh(2)),:)+Y_inh_PV_SSFO(ind_e2(cell_num_inh(2)),:),'--k','linewidth',2); hold on;
set(gca,'TickDir','out','linewidth',lw_plt,'fontsize',fontsize_plt);
axis tight
xlabel('frequency [a.u.]')
ylabel('input [Hz]')
title('inh. enhanced')
box off