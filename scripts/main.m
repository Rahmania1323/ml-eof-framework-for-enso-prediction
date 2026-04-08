%% ==========================================================
% ENSO FORECAST SYSTEM V8
% Hybrid ML + EOF Predictors + Persistence Benchmark
% Ready for research publication
%% ==========================================================

clear; close all; clc
rng(42,'twister')

%need 3 inputs to be clicked: ENSO (nino34.long.anom excel file), SOI
%(txt), WWV (txt)exit

disp('====================================')
disp('ENSO Forecast System V8')
disp('====================================')

lags = 6;
maxLead = 24;

%% ==========================================================
% LOAD ENSO
%% ==========================================================

[file1,path1] = uigetfile('*.*','Select ENSO (Niño3.4)');
ensoT = readtable(fullfile(path1,file1),'ReadVariableNames',false);

dateENSO = datetime(ensoT.Var1,'InputFormat','yyyy-MM-dd');
enso = ensoT.Var2;

%% ==========================================================
% LOAD SOI
%% ==========================================================

[file2,path2] = uigetfile('*.*','Select SOI');
soiT = readtable(fullfile(path2,file2),'ReadVariableNames',false);

ym = soiT.Var1;
soi = soiT.Var2;

yr = floor(ym/100);
mo = mod(ym,100);
dateSOI = datetime(yr,mo,1);

%% ==========================================================
% LOAD WWV
%% ==========================================================

[file3,path3] = uigetfile('*.*','Select WWV');
wwvT = readtable(fullfile(path3,file3),'ReadVariableNames',false);

ym = wwvT.Var1;
wwv = wwvT.Var3;

yr = floor(ym/100);
mo = mod(ym,100);
dateWWV = datetime(yr,mo,1);

%% ==========================================================
% ALIGN DATA
%% ==========================================================

[date,i1,i2] = intersect(dateENSO,dateSOI);
enso = enso(i1);
soi  = soi(i2);

[date,i1,i2] = intersect(date,dateWWV);
enso = enso(i1);
soi  = soi(i1);
wwv  = wwv(i2);

good = ~(isnan(enso)|isnan(soi)|isnan(wwv));
enso = enso(good);
soi  = soi(good);
wwv  = wwv(good);
date = date(good);

%% ==========================================================
% SMOOTH
%% ==========================================================

enso = movmean(enso,3);
soi  = movmean(soi,3);
wwv  = movmean(wwv,3);

%% ==========================================================
% STANDARDIZE
%% ==========================================================

enso_mean = mean(enso);
enso_std = std(enso);

ensoN = (enso-enso_mean)/enso_std;
soi = zscore(soi);
wwv = zscore(wwv);

%% ==========================================================
% BUILD FEATURE MATRIX
%% ==========================================================

N = length(ensoN);
rows = N - lags - maxLead;
X = [];

for i=1:rows
    t = i + lags;
    ensoLag = ensoN(t-1:-1:t-lags)';
    soiLag  = soi(t-1:-1:t-lags)';
    wwvLag  = wwv(t-1:-1:t-lags)';
    recharge = wwv(t)-wwv(t-6);
    trend = ensoN(t)-ensoN(t-3);
    m = month(date(t));
    s1 = sin(2*pi*m/12);
    s2 = cos(2*pi*m/12);
    X = [X; [ensoLag soiLag wwvLag recharge trend s1 s2]];
end

%% ==========================================================
% EOF / PCA DIMENSION REDUCTION
%% ==========================================================

Xmean = mean(X);
Xc = X - Xmean;
[coeff,score,~,~,explained] = pca(Xc);
cumvar = cumsum(explained);
nModes = find(cumvar>=90,1);

disp(' ')
disp(['EOF modes retained: ',num2str(nModes)])
disp(['Variance expexitlained: ',num2str(cumvar(nModes)),'%'])

X = score(:,1:nModes);

%% ==========================================================
% TRAIN TEST SPLIT
%% ==========================================================

split = floor(0.7*rows);
Xtrain = X(1:split,:);
Xtest = X(split+1:end,:);
predStore = zeros(length(Xtest),maxLead);

corrVals = zeros(maxLead,1);
rmseVals = zeros(maxLead,1);
corrPersist = zeros(maxLead,1);
corrSE = zeros(maxLead,1);
rmseSE = zeros(maxLead,1);

disp(' ')
disp('Evaluating hindcast skill...')

%% ==========================================================
% HINDCAST LOOP
%% ==========================================================

for h=1:maxLead
    Y = ensoN(lags+h:lags+h+rows-1);
    Ytrain = Y(1:split);
    Ytest = Y(split+1:end);

    ridgeModel = fitrlinear(Xtrain,Ytrain,'Learner','leastsquares','Regularization','ridge');
    rfModel = TreeBagger(200,Xtrain,Ytrain,'Method','regression');

    predR = predict(ridgeModel,Xtest);
    predRF = predict(rfModel,Xtest);
    if iscell(predRF), predRF = str2double(predRF); end

    pred = 0.5*predR + 0.5*predRF;
    pred = pred*enso_std + enso_mean;
    obs = Ytest*enso_std + enso_mean;

    predStore(:,h) = pred;
    corrVals(h) = corr(obs,pred);
    rmseVals(h) = sqrt(mean((obs-pred).^2));
    persist = enso(split+lags:split+lags+length(obs)-1);
    corrPersist(h) = corr(obs,persist);

    Ntest = length(obs);
    corrSE(h) = sqrt((1-corrVals(h)^2)/(Ntest-2));
    rmseSE(h) = rmseVals(h)/sqrt(Ntest);
end

%% ==========================================================
% PRINT SKILL TABLE
%% ==========================================================

disp(' ')
disp('==========================================================')
disp('FORECAST SKILL: HYBRID MODEL vs PERSISTENCE')
disp('==========================================================')
disp('Lead  Corr_model±SE  Corr_persist  RMSE_model±SE')

for h=1:maxLead
    fprintf('%2d   %.3f±%.3f     %.3f        %.3f±%.3f\n',...
        h,corrVals(h),corrSE(h),corrPersist(h),rmseVals(h),rmseSE(h));
end

%% ==========================================================
% SKILL PLOTS
%% ==========================================================

figure('Position',[200 200 900 450])
subplot(2,1,1)
errorbar(1:maxLead,corrVals,corrSE,'o-','LineWidth',2)
hold on
plot(1:maxLead,corrPersist,'s--','LineWidth',2)
xlabel('Lead Time (months)')
ylabel('Correlation')
title('ENSO Forecast Skill: Hybrid vs Persistence')
legend('Hybrid Model','Persistence')
grid on

subplot(2,1,2)
errorbar(1:maxLead,rmseVals,rmseSE,'o-','LineWidth',2)
xlabel('Lead Time (months)')
ylabel('RMSE [^o C]')
title('Forecast RMSE vs Lead Time')
grid on
saveas(gcf,'ENSO_skill_comparison.png')

%% ==========================================================
% TIME SERIES VERIFICATION
%% ==========================================================

obsTest = enso(split+lags+1 : split+lags+length(Xtest));
persistTS = enso(split+lags : split+lags+length(obsTest)-1);

figure('Position',[200 200 900 450])
plot(obsTest,'ro','LineWidth',2)
hold on
plot(persistTS,'k--','LineWidth',2)
plot(predStore(:,3),'LineWidth',2)
plot(predStore(:,5),'LineWidth',2)
plot(predStore(:,7),'LineWidth',2)
plot(predStore(:,9),'LineWidth',2)
legend('Observed','Persistence','Lead3','Lead5','Lead7','Lead9')
title('ENSO Forecast Verification')
xlabel('Time index')
ylabel('Niño3.4 SSTA [^o C]')
grid on
saveas(gcf,'ENSO_timeseries_with_persistence.png')

%% ==========================================================
% OPERATIONAL FORECAST
%% ==========================================================

t = N;
stateENSO = ensoN(t:-1:t-lags+1)';
stateSOI = soi(t:-1:t-lags+1)';
stateWWV = wwv(t:-1:t-lags+1)';

forecast = zeros(maxLead,1);
ridgeModel = fitrlinear(X,Y,'Learner','leastsquares','Regularization','ridge');
rfModel = TreeBagger(200,X,Y,'Method','regression');

for h=1:maxLead
    recharge = stateWWV(1)-stateWWV(6);
    trend = stateENSO(1)-stateENSO(3);
    m = month(date(end));
    s1 = sin(2*pi*m/12);
    s2 = cos(2*pi*m/12);
    state_raw = [stateENSO stateSOI stateWWV recharge trend s1 s2];
    state = (state_raw - Xmean)*coeff(:,1:nModes);

        predR = predict(ridgeModel,state);
    predRF = predict(rfModel,state);
    if iscell(predRF), predRF = str2double(predRF); end

    nextENSO = 0.5*predR + 0.5*predRF;
    forecast(h) = nextENSO;
    stateENSO = [nextENSO stateENSO(1:end-1)];
end

forecast = forecast*enso_std + enso_mean;

disp(' ')
disp('OPERATIONAL ENSO FORECAST')
disp('Lead   Niño3.4   ±RMSE')
for h=1:maxLead
    fprintf('%2d   %.3f   ±%.3f\n',h,forecast(h),rmseVals(h));
end

%% ==========================================================
% FORECAST PLOT
%% ==========================================================

figure
errorbar(1:maxLead,forecast,rmseVals,'LineWidth',2)
xlabel('Lead Time (months)')
ylabel('Niño3.4 SSTA [^o C]')
title('Operational ENSO Forecast')
grid on
saveas(gcf,'ENSO_operational_forecast.png')

%% ==========================================================
% 9-SEASON OPERATIONAL FORECAST (IRI-style)
%% ==========================================================

% Define all possible 3-month seasons
allSeasons = {'JFM','FMA','MAM','AMJ','MJJ','JJA','JAS','ASO','SON','OND','NDJ','DJF'};

% Detect last month of ENSO data
startMonth = month(date(end));

% Map month number to starting season index
% Jan=1 → FMA, Feb=2 → MAM, ..., Dec=12 → JFM
seasonStartMap = [2,3,4,5,6,7,8,9,10,11,12,1]; 
startIdx = seasonStartMap(startMonth);

% Generate rolling 9 seasons ahead
seasonLabels = cell(1,9);
for s = 1:9
    idx = mod(startIdx+s-2,12)+1; % wrap around 12
    seasonLabels{s} = allSeasons{idx};
end

seasonForecast = zeros(9,1);
seasonError    = zeros(9,1);

for s = 1:9
    leadIdx = (s:s+2); % 3-month window
    if max(leadIdx) <= maxLead
        seasonForecast(s) = mean(forecast(leadIdx));
        seasonError(s)    = mean(rmseVals(leadIdx));
    else
        seasonForecast(s) = NaN;
        seasonError(s)    = NaN;
    end
end

% Console output
disp(' ')
disp('9-SEASON OPERATIONAL FORECAST')
disp('Season   Niño3.4   ±RMSE')
for s = 1:9
    fprintf('%s   %.3f   ±%.3f\n',seasonLabels{s},seasonForecast(s),seasonError(s));
end

% Plot
figure
errorbar(1:9,seasonForecast,seasonError,'o-','LineWidth',2)
set(gca,'XTick',1:9,'XTickLabel',seasonLabels)
xlabel('Season')
ylabel('Niño3.4 SSTA [^o C]')
title('9-Season ENSO Forecast (IRI-style)')
grid on
saveas(gcf,'ENSO_9season_forecast.png')

% Excel recap
T = table(seasonLabels',seasonForecast,seasonError,...
    'VariableNames',{'Season','Forecast','Error'});
writetable(T,'ENSO_9season_forecast.xlsx')

%% ==========================================================
% Combined Monthly + Seasonal Forecast Plot
%% ==========================================================

%figure('Position',[200 200 1000 600])
figure('Position',[200 200 1000 450])

% Subplot 1: Monthly operational forecast (up to 24 months)
subplot(2,1,1)
errorbar(1:maxLead,forecast,rmseVals,'LineWidth',2)
xlabel('Lead Time (months)')
ylabel('Niño3.4 SSTA [^o C]')
title('Operational ENSO Forecast (Monthly)')
grid on

% Subplot 2: Seasonal forecast (9 seasons ahead)
subplot(2,1,2)
errorbar(1:9,seasonForecast,seasonError,'o-','LineWidth',2)
set(gca,'XTick',1:9,'XTickLabel',seasonLabels)
xlabel('Season')
ylabel('Niño3.4 SSTA [^o C]')
title('9-Season ENSO Forecast (IRI-style)')
grid on

% Save combined figure
saveas(gcf,'ENSO_combined_forecast.png')


