function [ Thr, dsThr ] = getThr4Cell(Exp, CellNr, ignoreUserData, SeqNr)
% % getThr4Cell - Get characteristic frequency for given data file and cell number
% %
% % THR = getThr4Cell(DataFile, CellNr, ignoreUserData{, thrSeqNr})
% 
% %B. Van de Sande 29-08-2003
% %K. Spiritus
% 
% 
% %% ---------------- CHANGELOG -----------------------
% %  Tue Jan 18 2011  Abel   
% %   - Updated to use new getTHRSeq() syntax: [SeqNr, dsTHR] = getTHRSeq(ds.filename, ds.icell)
% %	- Clean up/document code
% %	- Bugfix: userdata was not called (i.e. never) when SeqNr was empty
% %	- Added standard info string
% %  Fri Jan 21 2011  Abel   
% %   - bugfix, catch block was not reached when no userdata was found
% %  Mon Jan 24 2011  Abel   
% %   - added source entry
% %  Wed Apr 13 2011  Abel   
% %   - added dsThr as output
% 
% %% ---------------- Default parameters --------------
% % Declare some needed variables
% dsThr = [];
% Units.Thr = 'dB';
% Units.SR = 'spk/sec';
% exp_name = Exp;
% %% ---------------- Main program --------------------
% %If CellNr is NaN, force a return NaN and warn user
% if isnan(CellNr)
% 	SeqNr = NaN;
% 	ignoreUserData = 1;
% 	warning('EARLY::Info', 'No THR information found for this cell: Invalid CellNr');
% end
% 
% %If a THR sequence nr was supplied we don't need to read the seq from the userdata 
% if nargin == 4 && ~isempty(SeqNr)
% 	ignoreUserData = 1;
% end
% 
% %If a THR sequence nr was NOT supplied set it empty
% if nargin < 4
%     SeqNr = [];
% end
% 
% %When only file and cell are given, always check userdata
% if nargin < 3
%     ignoreUserData = 0;
% end
% 
% %Check userdata for THR sequence nr
% SeqNrSource = {};
% if ~ignoreUserData && isempty(SeqNr)
%     try
%         more off;
%         if mym(10, 'status')
%             mym(10, 'open', 'lan-srv-01.med.kuleuven.be', 'audneuro', '1monkey');
%             mym(10, 'use ExpData');
%         end
%         SeqNr = mym(10, ['SELECT THRSeq FROM UserData_CellCF WHERE FileName="' exp_name '" AND iCell=' num2str(CellNr) ';']);
% 		if isnan(SeqNr);
% 			error('No SeqNr found,... going to catch block');
% 		end
% 		SeqNrSource = {'UserData'};
% 	catch
%         SeqNr = [];
%     end
% end
% 
% % nothing found? try without userdata
% if isempty(SeqNr)
% 	warning('EARLY:Debug', 'No THR information found in USERDATA for Experiment:%s and cell:%d', ...
% 		exp_name, CellNr);
%     [SeqNr, dsThr] = getTHRSeq(Exp, CellNr);
% end
% 
% %If a THR sequence was found, get THR info, else return NaN
% if ~isnan(SeqNr)
% 	if isempty(dsThr)
% 		dsThr = dataset(Exp, SeqNr);
% 	end
%     [CF, SR, Thr, BW, Q10] = EvalTHR(dsThr, 'plot', 'n');
% 	
% 	%Generate standard info string for THR 
% 	Str = { ... 
% 		sprintf('\\bfThreshold curve:\\rm \\it%s <%s>\\rm', exp_name, num2str(SeqNr)); ...
% 		sprintf('\\itCF:\\rm %s @ %s', Param2Str(CF, 'Hz', 0), Param2Str(Thr, 'Hz', 0)); ...
% 		sprintf('\\itSR:\\rm %s', Param2Str(SR, Units.SR, 1)); ...
% 		sprintf('\\itBW:\\rm %s', Param2Str(BW, 'Hz', 1)); ...
% 		sprintf('\\itQ10:\\rm %s', Param2Str(Q10, '', 1)) ...
% 		};
% else
% 	warning('EARLY:Info', 'No THR information found for datafile:%s and cell:%d', ...
% 		Exp.ID.Name, CellNr);
%     [CF, SR, Thr, BW, Q10, SeqNr, Str] = deal(NaN);
% end
% 	
% THR = lowerFields(CollectInStruct(CF, SR, Thr, BW, Q10, SeqNr, Str, SeqNrSource));

% getThr4Cell - Get characteristic frequency for given data file and cell number
%
% THR = getThr4Cell(DataFile, CellNr, ignoreUserData{, thrSeqNr})

%B. Van de Sande 29-08-2003
%K. Spiritus


%% ---------------- CHANGELOG -----------------------
%  Tue Jan 18 2011  Abel   
%   - Updated to use new getTHRSeq() syntax: [SeqNr, dsTHR] = getTHRSeq(ds.filename, ds.icell)
%	- Clean up/document code
%	- Bugfix: userdata was not called (i.e. never) when SeqNr was empty
%	- Added standard info string
%  Fri Jan 21 2011  Abel   
%   - bugfix, catch block was not reached when no userdata was found
%  Mon Jan 24 2011  Abel   
%   - added source entry
%  Wed Apr 13 2011  Abel   
%   - added dsThr as output

%% ---------------- Default parameters --------------
% Declare some needed variables
dsThr = [];
Units.Thr = 'dB';
Units.SR = 'spk/sec';
exp_name = Exp.ID.Name;
%% ---------------- Main program --------------------
%If CellNr is NaN, force a return NaN and warn user
if isnan(CellNr)
	SeqNr = NaN;
	ignoreUserData = 1;
	warning('EARLY::Info', 'No THR information found for this cell: Invalid CellNr');
end

%If a THR sequence nr was supplied we don't need to read the seq from the userdata 
if nargin == 4 && ~isempty(SeqNr)
	ignoreUserData = 1;
end

%If a THR sequence nr was NOT supplied set it empty
if nargin < 4
    SeqNr = [];
end

%When only file and cell are given, always check userdata
if nargin < 3
    ignoreUserData = 0;
end

%Check userdata for THR sequence nr
SeqNrSource = {};
% if ~ignoreUserData && isempty(SeqNr)
%     try
%         more off;
%         if mym(10, 'status')
%             mym(10, 'open', 'lan-srv-01.med.kuleuven.be', 'audneuro', '1monkey');
%             mym(10, 'use ExpData');
%         end
%         SeqNr = mym(10, ['SELECT THRSeq FROM UserData_CellCF WHERE FileName="' exp_name '" AND iCell=' num2str(CellNr) ';']);
% 		if isnan(SeqNr);
% 			error('No SeqNr found,... going to catch block');
% 		end
% 		SeqNrSource = {'UserData'};
% 	catch
%         SeqNr = [];
%     end
% end

% nothing found? try without userdata
if isempty(SeqNr)
	warning('EARLY:Debug', 'No THR information found in USERDATA for Experiment:%s and cell:%d', ...
		exp_name, CellNr);
    [SeqNr, dsThr] = getTHRSeq(Exp, CellNr);
end

%If a THR sequence was found, get THR info, else return NaN
if ~isnan(SeqNr)
	if isempty(dsThr)
		dsThr = dataset(DataFile, SeqNr);
	end
    [CF, SR, Thr, BW, Q10] = EvalTHR(dsThr, 'plot', 'n');
	
	%Generate standard info string for THR 
	Str = { ... 
		sprintf('\\bfThreshold curve:\\rm \\it%s <%s>\\rm', exp_name, num2str(SeqNr)); ...
		sprintf('\\itCF:\\rm %s @ %s', Param2Str(CF, 'Hz', 0), Param2Str(Thr, 'Hz', 0)); ...
		sprintf('\\itSR:\\rm %s', Param2Str(SR, Units.SR, 1)); ...
		sprintf('\\itBW:\\rm %s', Param2Str(BW, 'Hz', 1)); ...
		sprintf('\\itQ10:\\rm %s', Param2Str(Q10, '', 1)) ...
		};
else
	warning('SGSR:Info', 'No THR information found for datafile:%s and cell:%d', ...
		Exp.ID.Name, CellNr);
    [CF, SR, Thr, BW, Q10, SeqNr, Str] = deal(NaN);
end
	
Thr = lowerFields(CollectInStruct(CF, SR, Thr, BW, Q10, SeqNr, Str, SeqNrSource));



