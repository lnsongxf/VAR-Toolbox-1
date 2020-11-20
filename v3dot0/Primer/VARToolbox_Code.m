%% 1. PRELIMINARIES
%-------------------------------------------------------------------------- 
delete 'SCREEN.m' 
clear all; clear session; close all; clc
warning off all
addpath(genpath('/Users/jambro/Google Drive/VAR-Toolbox/'))
addpath('codes')


%% 1. LOAD DATA
%************************************************************************** 
% The data used in this example is read from an Excel file and stored in a
% structure (DATA).
%-------------------------------------------------------------------------- 
% Load data from US macro data set
[xlsdata, xlstext] = xlsread('data/MACRO_US.xlsx','Sheet1');
dates = xlstext(3:end,1);
vnames_long = xlstext(1,2:end);
vnames = xlstext(2,2:end);
nvar = length(vnames);
data   = Num2NaN(xlsdata);
% Store variables in the structure DATA
for ii=1:length(vnames)
    DATA.(vnames{ii}) = data(:,ii);
end
% Convert the first date 1989q1 to numeric
year = str2double(xlstext{3,1}(1:4));
quarter = str2double(xlstext{3,1}(6));
% Observations
nobs = size(data,1);
% Transform selected variables
tempnames = {'cpi','gdp','i1yr'};
temptreat = {'logdiff','logdiff','diff'};
tempscale = [100,100,1];
for ii=1:length(tempnames)
    aux = {['d' tempnames{ii}]};
    DATA.(aux{1}) = tempscale(ii)*XoX(DATA.(tempnames{ii}),1,temptreat{ii});
end

%% 2. PLOT DATA
%************************************************************************** 
% Select the list of variables to plot...
Xvnames = {'gdp','cpi','unemp','vix','i1yr','ebp'};
% ... and corresponding labels to be used for plots
Xvnames_long = {'Real GDP','CPI','Unemployment','Vix Index','1-year Int. Rate','EBP'};
Xnvar        = length(Xvnames);
% Create matrices of variables to be used in the VAR
X = nan(nobs,Xnvar);
for ii=1:Xnvar
    X(:,ii) = DATA.(Xvnames{ii});
end
% Open a figure of the desired size and plot the selected series
FigSize(26,18)
for ii=1:Xnvar
    subplot(3,2,ii)
    H(ii) = plot(X(:,ii),'LineWidth',3,'Color',cmap(1));
    title(Xvnames_long(ii)); 
    DatesPlot(year+(quarter-1)/4,nobs,6,'q') % Set the x-axis label 
    grid on; 
end
% Save figure
SaveFigure('graphics/DATA_GK',1)
clf('reset')


%% 3. VAR ESTIMATION
%************************************************************************** 
% VAR estimations is achieved in two steps: (1) set the vector of endogenous 
% variables, the desired number of lags, and deterministic variables; (2)
% run the VARmdoel function.
%-------------------------------------------------------------------------- 
% Select list of endogenous variables (these will be pulled from the 
% structure DATA, where all data is stored) and their corresponding labels 
% that will be used for plots
Xvnames      = {'dgdp','i1yr'};
Xvnames_long = {'Real GDP (log change)','1-year Tbill (percent)'};
Xnvar        = length(Xvnames);
% Plot selected data
FigSize(26,6)
for ii=1:Xnvar
    subplot(1,2,ii)
    H(ii) = plot(DATA.(Xvnames{ii}),'LineWidth',3,'Color',cmap(1));
    title(Xvnames_long(ii)); 
    DatesPlot(year+(quarter-1)/4,nobs,6,'q') % Set the x-axis label 
    grid on; 
end
SaveFigure('graphics/DATA_BivariateVAR',1)
clf('reset')
% Create matrices of variables to be used in the VAR
X = nan(nobs,Xnvar);
for ii=1:Xnvar
    X(:,ii) = DATA.(Xvnames{ii});
end
% Make a common sample by removing NaNs
X = CommonSample(X);
% Set the deterministic variable in the VAR (1=constant, 2=trend)
det = 1;
% Set number of lags
nlags = 1;
% Estimate VAR by OLS
[VAR, VARopt] = VARmodel(X,nlags,det);
% Print at screen the outputs of the VARmodel function
disp(VAR)
disp(VARopt)
% Update the VARopt structure with additional details
VARopt.vnames = Xvnames_long;
% Print at screen VAR coefficients and create table 
[TABLE, beta] = VARprint(VAR,VARopt,2);
% Print at screen some results. Start with estimated coefficients
disp(VAR.F)
disp(VAR.sigma)
% Maximum eigenvalue 
disp(eig(VAR.Fcomp))


%% 4. IDENTIFICATION WITH ZERO CONTEMPORANEOUS RESTRICTIONS 
%************************************************************************** 
% Identification with zero contemporaneous restrictions is achieved in two 
% steps: (1) set the identification scheme mnemonic in the structure 
% VARopt to the desired one, in this case "ch"; (2) run the VARir or the 
% VARvd functions. For the zero contemporaneous restrictions 
% identification, consider the simple bivariate VAR estimated in the 
% previous section.
%-------------------------------------------------------------------------- 

% 4.1 Load data from Stock and Watson (2001)
%-------------------------------------------------------------------------- 
[xlsdata, xlstext] = xlsread('data/SW2001_Data.xlsx','Sheet1');
dates = xlstext(3:end,1);
vnames_long = xlstext(1,2:end);
vnames = xlstext(2,2:end);
nvar = length(vnames);
data   = Num2NaN(xlsdata);
for ii=1:length(vnames)
    DATA.(vnames{ii}) = data(:,ii);
end
year = str2double(xlstext{3,1}(1:4));
quarter = str2double(xlstext{3,1}(6));
nobs = size(data,1);

% 4.2 Plot series
%-------------------------------------------------------------------------- 
Xvnames      = {'infl','unemp','ff'};
Xvnames_long = {'Inflation (Percent)','Unemployment (Percent)','Fed Funds (Percent)'};
Xnvar        = length(Xvnames);
% Plot selected data
FigSize(26,6)
for ii=1:Xnvar
    subplot(1,3,ii)
    H(ii) = plot(DATA.(Xvnames{ii}),'LineWidth',3,'Color',cmap(1));
    title(Xvnames_long(ii)); 
    DatesPlot(year+(quarter-1)/4,nobs,6,'q') % Set the x-axis label 
    grid on; 
end
SaveFigure('graphics/SW_DATA',1)
clf('reset')
X = nan(nobs,Xnvar);
for ii=1:Xnvar
    X(:,ii) = DATA.(Xvnames{ii});
end

% 4.3 Set up and estimate VAR
%-------------------------------------------------------------------------- 
det = 1;
nlags = 4;
[VAR, VARopt] = VARmodel(X,nlags,det);
% Update the VARopt structure with additional details to be used in IR 
% calculations and plots
VARopt.vnames = Xvnames_long;
VARopt.nsteps = 24;
VARopt.quality = 1;
VARopt.FigSize = [26,12];
VARopt.firstdate = year+(quarter-1)/4;
VARopt.frequency = 'q';
VARopt.figname= 'graphics/SW_';

% 4.4 IMPULSE RESPONSES
%-------------------------------------------------------------------------- 
% For zero contemporaneous restrictions set:
VARopt.ident = 'short';
% Compute IR
[IR, VAR] = VARir(VAR,VARopt);
% Compute IR error bands
[IRinf,IRsup,IRmed,IRbar] = VARirband(VAR,VARopt);
% Plot IR
VARirplot(IRbar,VARopt,IRinf,IRsup);

% 4.5 FORECAST ERROR VARIANCE DECOMPOSITION
%-------------------------------------------------------------------------- 
% Compute VD
[VD, VAR] = VARvd(VAR,VARopt);
% Compute VD error bands
[VDinf,VDsup,VDmed,VDbar] = VARvdband(VAR,VARopt);
% Plot VD
VARvdplot(VDbar,VARopt);

% 4.6 HISTORICAL DECOMPOSITION
%-------------------------------------------------------------------------- 
% Compute HD
[HD, VAR] = VARhd(VAR,VARopt);
% Plot HD
VARhdplot(HD,VARopt);


%% 5. IDENTIFICATION WITH ZERO LONG-RUN RESTRICTIONS 
%************************************************************************** 
% As in the previous section, identification is achieved in two steps: (1) 
% set the identification scheme mnemonic in the structure VARopt to the 
% desired one, in this case "bq"; (2) run the VARir or VARvd functions. 
% For the zero long-run restrictions identification, consider the same VAR 
% as in the previous section.
%-------------------------------------------------------------------------- 

% 4.1 Load data from Stock and Watson (2001)
%-------------------------------------------------------------------------- 
[xlsdata, xlstext] = xlsread('data/BQ1989_Data.xlsx','Sheet1');
dates = xlstext(3:end,1);
vnames_long = xlstext(1,2:end);
vnames = xlstext(2,2:end);
nvar = length(vnames);
data   = Num2NaN(xlsdata);
for ii=1:length(vnames)
    DATA.(vnames{ii}) = data(:,ii);
end
year = str2double(xlstext{3,1}(1:4));
quarter = str2double(xlstext{3,1}(6));
nobs = size(data,1);

% 4.2 Plot series
%-------------------------------------------------------------------------- 
Xvnames      = {'y','u'};
Xvnames_long = {'GDP growth (Percent)','Unemployment (Percent)'};
Xnvar        = length(Xvnames);
% Plot selected data
FigSize(26,6)
for ii=1:Xnvar
    subplot(1,2,ii)
    H(ii) = plot(DATA.(Xvnames{ii}),'LineWidth',3,'Color',cmap(1));
    title(Xvnames_long(ii)); 
    DatesPlot(year+(quarter-1)/4,nobs,6,'q') % Set the x-axis label 
    grid on; 
end
SaveFigure('graphics/BQ_DATA',1)
clf('reset')

% 5.3 Set up and estimate VAR
%-------------------------------------------------------------------------- 
X = nan(nobs,Xnvar);
for ii=1:Xnvar
    X(:,ii) = DATA.(Xvnames{ii});
end
det = 1;
nlags = 8;
[VAR, VARopt] = VARmodel(X,nlags,det);
VARopt.vnames = Xvnames_long;
VARopt.nsteps = 40;
VARopt.quality = 1;
VARopt.FigSize = [26,8];
VARopt.firstdate = year+(quarter-1)/4;
VARopt.frequency = 'q';
VARopt.figname= 'graphics/BQ_';

% 5.4 IMPULSE RESPONSES
%-------------------------------------------------------------------------- 
% For zero contemporaneous restrictions set:
VARopt.ident = 'long';
% Compute IR
[IR, VAR] = VARir(VAR,VARopt);
% Compute IR error bands
[IRinf,IRsup,IRmed,IRbar] = VARirband(VAR,VARopt);
% Plot IR
VARirplot(IRbar,VARopt,IRinf,IRsup);

% 5.5 REPLICATE FIGURE 1 OF BLANCHARD & QUAH
%-------------------------------------------------------------------------- 
FigSize(26,8)
% Plot supply shock
subplot(1,2,1)
plot(cumsum(IR(:,1,1)),'LineWidth',2.5,'Color',cmap(1))
hold on
plot(IR(:,2,1),'LineWidth',2.5,'Color',cmap(2))
hold on
plot(zeros(VARopt.nsteps),'--k')
title('Supply shock')
legend({'GDP Level';'Unemployment'})
% Plot demand shock
subplot(1,2,2)
plot(cumsum(-IR(:,1,2)),'LineWidth',2.5,'Color',cmap(1))
hold on
plot(-IR(:,2,2),'LineWidth',2.5,'Color',cmap(2))
hold on
plot(zeros(VARopt.nsteps),'-k')
title('Demand shock')
legend({'GDP Level';'Unemployment'})
% Save
SaveFigure('graphics/BQ_Replication',1);
clf('reset')

%% 6. IDENTIFICATION WITH SIGN RESTRICTIONS
%************************************************************************** 
% For the sign restrictions example, consider a larger VAR  with four 
% endogenous variables. Identification with sign restrictions is achieved 
% in a slightly different way relative to zero contemporaneous or long-run 
% restrictions. Identification is achieved in two steps: (1) define a 
% matrix with the sign restrictions that the IRs have to satisfy; (2) run 
% the SR function. 
%-------------------------------------------------------------------------- 

% 6.1 Load data from Uhlig (2005)
%-------------------------------------------------------------------------- 
[xlsdata, xlstext] = xlsread('Uhlig2005_Data.xlsx','Sheet1');
dates = xlstext(3:end,1);
vnames_long = xlstext(1,2:end);
vnames = xlstext(2,2:end);
nvar = length(vnames);
data   = Num2NaN(xlsdata);
for ii=1:length(vnames)
    DATA.(vnames{ii}) = data(:,ii);
end
year = str2double(xlstext{3,1}(1:4));
month = str2double(xlstext{3,1}(6));
nobs = size(data,1);
% Transform selected variables
tempnames = {'y','pi','comm','nbres','ff'};
temptreat = {'log','log','log','log','log'};
tempscale = [100,100,100,100,100];
for ii=1:length(tempnames)
    aux = {['d' tempnames{ii}]};
    DATA.(aux{1}) = tempscale(ii)*XoX(DATA.(tempnames{ii}),1,temptreat{ii});
end

% 4.2 Plot series
%-------------------------------------------------------------------------- 
Xvnames      = vnames;
Xvnames_long = vnames_long;
Xnvar        = length(Xvnames);
% Plot selected data
FigSize(26,18)
for ii=1:Xnvar
    subplot(3,2,ii)
    H(ii) = plot(DATA.(Xvnames{ii}),'LineWidth',3,'Color',cmap(1));
    title(Xvnames_long(ii)); 
    DatesPlot(year+(month-1)/12,nobs,6,'m') % Set the x-axis label 
    grid on; 
end
SaveFigure('graphics/Uhlig_DATA',1)
clf('reset')

% 5.3 Set up and estimate VAR
%-------------------------------------------------------------------------- 
X = nan(nobs,Xnvar);
for ii=1:Xnvar
    X(:,ii) = DATA.(Xvnames{ii});
end
det = 1;
nlags = 8;
[VAR, VARopt] = VARmodel(X,nlags,det);
VARopt.vnames = Xvnames_long;
VARopt.nsteps = 60;
VARopt.ndraws = 500;
VARopt.quality = 1;
VARopt.FigSize = [26,8];
VARopt.firstdate = year+(month-1)/12;
VARopt.frequency = 'm';
VARopt.figname= 'graphics/Uhlig_';

% 5.2 IDENTIFICATION
%-------------------------------------------------------------------------- 
% Define the shock names
VARopt.snames = {'Mon. Policy Shock'};
% Define sign restrictions : positive 1, negative -1, unrestricted 0
SIGN = [ 0,0,0,0,0,0;  % Real GDP
        -1,0,0,0,0,0;  % Deflator
        -1,0,0,0,0,0;  % Commodity Price
         0,0,0,0,0,0;  % Total Reserves
        -1,0,0,0,0,0;  % NonBorr. Reserves
         1,0,0,0,0,0]; % Fed Fund
% Define the number of steps the restrictions are imposed for:
VARopt.sr_hor = 6;
% Set options the credible intervals
VARopt.pctg = 68;
% The functin SR performs the sign restrictions identification and computes
% IRs, VDs, and HDs. All the results are stored in SRout
SRout = SR(VAR,SIGN,VARopt);

%% 5.3 REPLICATE UHLIG'S FIGURE 6
%-------------------------------------------------------------------------- 
FigSize(26,12)
for ii=1:Xnvar
    subplot(2,3,ii)
    PlotSwathe(SRout.IRmed(:,ii,1),[SRout.IRinf(:,ii,1) SRout.IRsup(:,ii,1)]); hold on
    plot(zeros(VARopt.nsteps),'--k');
    title(vnames_long{ii})
    axis tight
end
SaveFigure('graphics/Uhlig_Replication',1)
clf('reset')
% 500 rot
FigSize(26,12)
for ii=1:Xnvar
    subplot(2,3,ii)
    plot(squeeze(SRout.IRall(:,ii,1,:))); hold on
    plot(zeros(VARopt.nsteps),'--k');
    title(vnames_long{ii})
    axis tight
	store(ii,:) = ylim;
end
SaveFigure('graphics/Uhlig_Replication_500rot',1)
clf('reset')
% 1 rot
FigSize(26,12)
for ii=1:Xnvar
    subplot(2,3,ii)
    plot(SRout.IRall(:,ii,1,1)); hold on
    plot(zeros(VARopt.nsteps),'--k');
    title(vnames_long{ii})
    axis tight
    ylim(store(ii,:))
end
SaveFigure('graphics/Uhlig_Replication_1rot',1)
clf('reset')
% 2 rot
FigSize(26,12)
for ii=1:Xnvar
    subplot(2,3,ii)
    plot(SRout.IRall(:,ii,1,1)); hold on
    plot(SRout.IRall(:,ii,1,3)); hold on
    plot(zeros(VARopt.nsteps),'--k');
    title(vnames_long{ii})
    axis tight
    ylim(store(ii,:))
end
SaveFigure('graphics/Uhlig_Replication_2rot',1)
clf('reset')


% %% 6. IDENTIFICATION WITH EXTERNAL INSTRUMENTS
% %************************************************************************** 
% % Identification with external instruments is achieved in three steps: (1) 
% % set the identification scheme mnemonic in the structure VARopt to the 
% % desired one, in this case "iv"; (2) update the VARopt structure with the 
% % external instrument to be used for identification; (3) run the VARir 
% % function. For the external instruments example, we consider the same VAR 
% % as in the sign restrictions example. 
% %-------------------------------------------------------------------------- 
% 
% % First update the VARopt structure with additional details to be used for
% % the IR calculations and plots
% VARopt.figname= 'graphics/IV_';
% 
% % With the usual notation, select the instrument from the DATA structure:
% IVvnames      = {'ff4_tc'};
% IVvnames_long = {'FF4 futures'};
% IVnvar        = length(IVvnames);
% 
% % Create vector of instruments to be used in the VAR
% IV = nan(nobs,IVnvar);
% for ii=1:IVnvar
%     IV(:,ii) = DATA.(IVvnames{ii});
% end
% 
% % Identification is achieved with the external instrument IV, which needs
% % to be added to the VARopt structure
% VAR.IV = IV;
% 
% % Update the options in VARopt to be used in IR calculations and plots
% VARopt.ident = 'iv';
% VARopt.method = 'wild';
% 
% % Compute IRs
% [IR, VAR] = VARir(VAR,VARopt);
% 
% % Compute error bands
% [IRinf,IRsup,IRmed,IRbar] = VARirband(VAR,VARopt);
% 
% % Can now plot the impulse responses with the usual code
% VARopt.FigSize = [26,24];
% VARirplot(IRbar,VARopt,IRinf,IRsup);
% 
% 
% %% 7. IDENTIFICATION WITH A MIX OF EXTERNAL INSTRUMENTS AND SIGN RESTRICTIONS
% %************************************************************************** 
% % Identification with external instruments is achieved in three steps: (1) 
% % set the identification scheme mnemonic in the structure VARopt to the 
% % desired one, in this case "iv"; (2) update the VARopt structure with the 
% % external instrument to be used for identification; (3) run the VARir 
% % function. For the external instruments example, we consider the same VAR 
% % as in the sign restrictions example. 
% %-------------------------------------------------------------------------- 
% 
% % First update the VARopt structure with additional details to be used for
% % the IR calculations and plots
% VARopt.figname= 'graphics/IVSR_';
% 
% % Define the shock names
% VARopt.snames = {'Monetary policy Shock','Demand Shock','Supply Shock','Unidentified'};
% 
% % But now we assume that the first shock is identified with the external 
% % instrument. In other words, the first column of the B matrix is given by:
% disp(VAR.b)
% 
% % So, we define the sign restrictions only for the aggregate demand, the 
% % aggregate supply, and the un-identified shock
% SIGN = [-1,       0,      0;        ... policy rate
%         -1,      -1,      0;        ... ip        
%         -1,       1,      0;        ... cpi
%          1,       1,      0];       ... ebp
%        % D        S       U   
% 
% % Define the number of steps the restrictions are imposed for:
% VARopt.sr_hor = 6;
% 
% % Set options the credible intervals
% VARopt.pctg = 95;
% 
% % The functin SR performs the sign restrictions identification and computes
% % IRs, VDs, and HDs. All the results are stored in SRout
% SRout = SR(VAR,SIGN,VARopt);
% 
% % Plot impulse responses
% VARopt.FigSize = [26,24];
% SRirplot(SRout.IRmed,VARopt,SRout.IRinf,SRout.IRsup);


%%
m2tex('VARToolbox_Code.m')
rmpath(genpath('C:/AMPER/VARToolbox'))

