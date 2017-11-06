function [H,G]=cyclehisto(D, figh, P);
% dataset/cyclehisto - plot cycle histogram of a dataset
%    cyclehisto(D) displays a cycle histogram of the spike times in dataset D.
%
%    cyclehisto(D,figh) uses figure handle figh for plotting
%    (default = [] -> gcf). 
%
%    cyclehisto(D, figh, P) uses parameters P for displaying the dotraster.
%    P is typically a dataviewparam object or a valid 2nd input argument to
%    the dataviewparam constructor method, such as a parameter filename.
%
%    Cyclehisto is a standard "dataviewer", meaning that it may serve as
%    viewer for online data analysis during data collection. In addition,
%    the plot generated by all dataviewers allow an interactive change of
%    analysis parameter view the Params|Edit pullodwn menu (Ctr-Q).
%    For details on dataviewers, see dataviewparam.
%
%    See also dataviewparam, dataset/enableparamedit.

% handle the special case of parameter queries. Do this immediately to 
% avoid endless recursion with dataviewparam.
if isvoid(D) && isequal('params', figh),
    [H,G] = local_ParamGUI;
    return;
end

% open a new figure or use existing one?
if nargin<2 || isempty(figh),
    open_new = isempty(get(0,'CurrentFigure'));
    figh=gcf; 
else,
    open_new = ~isSingleHandle(figh);
end

% parameters
if nargin<3, P = []; end
if isempty(P), % use default paremeter set for this dataviewer
    P = dataviewparam(mfilename); 
end

% delegate the real work to local fcn
[okay, H] = local_cyclehisto(D, figh, open_new, P);

if ~okay, return; end;

% enable parameter editing when viewing offline
if isSingleHandle(figh, 'figure'), enableparamedit(D, P, figh); end;



%=====================================================
%=====================================================

function [okay, data_struct] = local_cyclehisto(D, figh, open_new, P);

okay = 0;
% the real work generating the cycle hist 
if isSingleHandle(figh, 'figure')
    figure(figh); clf; ah = gca;
    if open_new, placefig(figh, mfilename, D.Stim.GUIname); end % restore previous size 
else
    ah = axes('parent', figh);
end

Pres = D.Stim.Presentation;
P = struct(P); P = P.Param; 
        
% %-- by Abel: test cyclohist for RC/RCM menu (Y param is fake)
%  if ~isempty(Pres.Y)
%      isFakeY = all(Pres.Y.PlotVal(1) == Pres.Y.PlotVal); %Check if second var is varied of constant (=fake var)
%      
%     if isSingleHandle(figh, 'figure') % offline
%         errordlg('Cycle histogram for datasets with 2 independent parameters not yet implemented.','Not implemented'); 
%         close(figh);
%         return;
% %    else  % online
%     elseif ~isFakeY  % online
%         warning('Cycle histogram for datasets with 2 independent parameters not yet implemented.','Not implemented');
%         return;
%     end
%     
% end % XXXXXX
%--        
plottedCond = 1:Pres.Ncond; % conditions in order of presentation
Xval = Pres.X.PlotVal;
fmt = Pres.X.FormatString;

% Executing spiketimes(D) 
SPT = spiketimes(D);            

% prepare plot
[axh, Lh, Bh] = plotpanes(Pres.Ncond+1, 0, figh);
AW = P.Anwin;

% Determine which binning frequency to use
EXP = struct(D.Stim.Experiment);
ipsi_contra = [1 2];
IpsiIsLeft = isequal('Left', EXP.Recording.General.Side);
if ~IpsiIsLeft, ipsi_contra = fliplr(ipsi_contra); end;
switch P.Fcycle
    case 'fcar ipsi'
        try fcycle = D.Stim.Fcar(:,ipsi_contra(1)); 
        catch, error('Error in cyclehisto.m: Binning frquency = fcar ipsi, but none present.'); end;
    case 'fcar contra'
        try fcycle = D.Stim.Fcar(:,ipsi_contra(2));
        catch, error('Error in cyclehisto.m: Binning frquency = fcar contra, but none present.'); end;
    case 'fmod ipsi'
        try fcycle = D.Stim.Fmod(:,ipsi_contra(1));
        catch, error('Error in cyclehisto.m: Binning frquency = fmod ipsi, but none present.'); end;
    case 'fmod contra'
        try fcycle = D.Stim.Fmod(:,ipsi_contra(2));
        catch, error('Error in cyclehisto.m: Binning frquency = fmod contra, but none present.'); end;
    case 'manual'
        fcycle = eval(P.Fmancycle);
            if numel(fcycle)==1, fcycle = repmat(fcycle, Pres.Ncond, 1); end;
        if (length(fcycle) ~= Pres.Ncond)
        error('Error in cyclehisto.m: Number of binning frequencies differs from number of conditions for this stimulus.')
        end
    case 'auto'
        % Default option: look if mod is applicable, if not, take car.
        fcycle = D.Stim.Fmod(:,1);
        if any(fcycle==0), fcycle = D.Stim.Fcar(:,1); end;
end
if any(fcycle==0), error('Error in cyclehisto.m: Chosen cycle frequency is zero.');
else fcycle = fcycle(:); end;

%   
    for icond=1:Pres.Ncond,
        fcar = fcycle(icond, 1);
        T = 1e3/fcar; % period in ms
        dur = D.Stim.Duration(icond,1); % burst dur in ms
        spt = [SPT{icond, :}];
        if isequal('burstdur', AW),
            aw = [0 dur];
        else,
            aw = AW;
            if isfield(D.Stim, 'Warp'),
                aw = aw*2.^(-D.Stim.Warp(icond));
            end
        end
        %round(aw)
        spt = AnWin(spt, aw);
        [VS, Alpha] = vectorstrength(spt,fcar);
        phi = angle(VS)/(2*pi);
        VS = deciRound(abs(VS),2);
        spt = rem(spt,T)/T;
        h = axh(icond); % current axes handle

        % axes(h);  

        [N,Ph] = hist(spt,linspace(0,1,P.Nbin+1));
        bar(h, Ph, N, 'style','histc');  
        xlim(h, [0 1])    
        title(h, sprintf(fmt, Xval(icond)));
        VSstr = ['r = ' num2str(VS) ', phi = ' num2str(phi)];
        if Alpha<=0.001, 
            VSstr = [VSstr '*'];
        end
        set(gcf,'CurrentAxes',h);
        text(0.1, 0.1, VSstr, 'units', 'normalized', 'color', 'r', 'fontsize', 12 , 'interpreter', 'latex');
        data_struct.fcar = fcar;
        data_struct.T = T;
        data_struct.dur = dur;
        data_struct.spt{icond} = spt;
        data_struct.aw(icond,:) = aw;
        data_struct.VS(icond,:) = VS;
        data_struct.Alpha(icond,:) = Alpha;
        data_struct.Histo(icond,:) = N;
        data_struct.BinCenter(icond,:) = Ph;
        data_struct.xlim = xlim;
        data_struct.title{icond} = Xval(icond);
        data_struct.VSstr = VSstr;
        data_struct.xlabel = 'phase (cycle)';
        data_struct.ylabel = 'spike count';
    end

Xlabels(Bh,'phase (cycle)');
Ylabels(Lh,'spike count');
set(gcf,'CurrentAxes',axh(end));
text(0.1, 0.5, IDstring(D, 'full'), 'fontsize', 12, 'fontweight', 'bold','interpreter','none');
okay = 1;





function [T,G] = local_ParamGUI
% Returns the GUI for specifying the analysis parameters.
P = GUIpanel('cyclehisto','');
Nbin = ParamQuery('Nbin', '# bins:', '50', '', 'posint',...
    'Number of bins used for computing the histogram.', 1);
Anwin = ParamQuery('Anwin', 'analysis window:', 'burstdur', '', 'anwin',...
    'Analysis window (in ms) [t0 t1] re the stimulus onset. The string "burstdur" means [0 t], in which t is the burst duration of the stimulus.');
CycleOptions = {'auto','fcar ipsi' 'fcar contra' 'fmod ipsi' 'fmod contra' 'manual'};
Fcycle = ParamQuery('Fcycle', 'cycle options:', '', CycleOptions, '',...
    'Click to toggle between binning frequency options. "auto" means: mod if applicable.', 100);
Fmancycle = ParamQuery('Fmancycle', 'cycle freq:', '0', 'Hz', '~expr2str', ...
    'Manual value (in Hz) for binning frequency. Specify as nonnegative number e.g. 1000 or regular Matlab expression e.g. 5000 + [100:100:1000].');
P = add(P, Nbin);
P = add(P, Anwin, 'below');
P = add(P, Fcycle, 'below');
P = add(P, Fmancycle, 'below');
G = GUIpiece([mfilename '_parameters'],[],[0 0],[10 10]);
G = add(G,P);
G = marginalize(G,[10 10]);
% list all parameters in a struct
T = VoidStruct('Nbin/Anwin/Fcycle/Fmancycle');