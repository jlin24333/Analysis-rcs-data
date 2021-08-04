function [textlog] = RCS_logs(rootdir,PATIENTIDside)

% RCS Database

% This function loops through all session folders in the path to create a
% database of all RC+S metrics of interest including processing of the
% adaptive text logs

% INPUTS: 
% 1. ROOTDIR is the local root directory pathname for all patient session files
%       ! ! Make sure patient name is NOT included (e.g RCS02 would be a subfolder in the input folder)
%        This should look something like 'C:/Desktop/'
%            ** including:
%            ** AppLog.txt: adaptive state changes
%            ** EventLog.txt: open loop group changes
% 
% 2. PATIENTIDside (this should indicate the side (L/R) of which device you are
%       analyzing (i.e. RCS02R) - EXCEPT for CPRCS01, there is no letter after
%       the name

% OUTPUT: 
% 1. textlog.mat timetable with fields:

%    [{'time'}; {'rec'}; {'sessname'  };  {'duration'  }; ...
%     {'battery'   };{'TDfs'      };{'fft'};
%     {'power'     };{'stim'    };   {'stimName'  }; ...
%     {'stimparams'};  {'path'};  {'powerbands'}]; ...
%     {'adaptiveLD_mean'}; {'adaptiveLD_std'}; {'untsreamedGroupChanges'};


% function dependencies:
%    read_adaptive_txt_log (starr lab analysis repo) % by Ro'ee Gilron
%    makeDataBaseRCSdata (Chronic Pain RCS repo) % by Prasad Shirvalkar
%       Open Mind functions in makeDataBaseRCSData: % by Kristin Sellers
%       and Open Mind team
        %   	createDeviceSettingsTable
        %       createStimSettingsFromDeviceSettings
        %       deserializeJSON
        %       createStimSettingsTable
% other dependencies:
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the same directory as the processing scripts


% Ashlyn Schmitgen May2021

%%% Updates %%%
%   P Shirvalkar July 28 2021 
%   -  Updated redundant calculations and included recharge sessions, group
%      changes and detector changes to output
%   - created new plotting tools for this analysis (as part of RCS_CL which
%   calls this function)
%%%

% For OpenMind

%% create loop through all text files for adaptive_read_log_txt.m for database

warning("off", "all"); 
tic

% exception for CPRCS01
if ~ (contains(PATIENTIDside,'CPRCS01'))
    PATIENTID = PATIENTIDside(1:end-1); %remove the L or R letter
else 
    PATIENTID = PATIENTIDside;
end

fprintf('Compiling database for %s /n', PATIENTIDside)
    
    
scbsdir = fullfile(rootdir,PATIENTID,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTIDside);
adbsdir = fullfile(rootdir,PATIENTID,'/SummitData/StarrLab/', PATIENTIDside);

filelist = dir(fullfile(scbsdir,'**/*.txt')); % all txt files contains within session files
% remove the files that start with ._  (some icloud issue of duplicate files to ignore)
badfiles = arrayfun(@(x) contains(x.name,'._'),filelist);
filelist(badfiles)=[];
filelist = filelist(~[filelist.isdir]);

AppLogData = table(); % create empty tables
GroupchangeData = table();
RechargeData=table();
AdaptiveDetect=table();
for i = 1:numel(filelist)
    f = filelist(i);
    if endsWith(f.name,"AppLog.txt")
        [adaptiveLogTable, ~, ~,adaptiveDetectionEvents] = read_adaptive_txt_log(fullfile(f.folder, f.name));
        AppLogData = [AppLogData; adaptiveLogTable];
        AdaptiveDetect = [AdaptiveDetect; adaptiveDetectionEvents];
        fprintf("Done %s, %d/%d: %d\n", f.name, i, numel(filelist), size(adaptiveLogTable, 1)); 
        
    elseif endsWith(f.name,"EventLog.txt")
        [~, rechargeSessions, groupChanges,~] = read_adaptive_txt_log(fullfile(f.folder, f.name));
        GroupchangeData = [GroupchangeData; groupChanges];
        RechargeData =[RechargeData; rechargeSessions];
        fprintf("Done %s, %d/%d: %d\n", f.name, i, numel(filelist), size(groupChanges, 1));
    end
end

fprintf("Done!\n");
toc


%% format Text Log tables and eliminate duplicates from overlap

% make sure time is datetime
AppLogData.time = datetime(AppLogData.time);
GroupchangeData.time = datetime(GroupchangeData.time);
AdaptiveDetect.time = datetime(AdaptiveDetect.time);
RechargeData.time = datetime(RechargeData.time);

% sort all rows by date
sorted_ALD = sortrows(AppLogData, 1);
sorted_ELD = sortrows(GroupchangeData, 1);
sorted_AD = sortrows(AdaptiveDetect, 1); 
sorted_RD = sortrows(RechargeData, 1);

% remove all duplicate timestamps
[~, ALD_ind] = unique(sorted_ALD.time);
[~, ELD_ind] = unique(sorted_ELD.time);
[~, AD_ind] = unique(sorted_AD.time);  %comment out if detections may occur at below 1sec timescale
[~, RD_ind] = unique(sorted_RD.time); %ok to remove dups since we only care about recharging on minute scale.

unique_sorted_ALD = table2timetable(sorted_ALD(ALD_ind, :));
unique_sorted_ELD = table2timetable(sorted_ELD(ELD_ind, :));
unique_sorted_AD =  table2timetable(sorted_AD(AD_ind, :));
unique_sorted_RD = table2timetable(sorted_RD(RD_ind, :));

% rename final variables for Text logs 
textlog.app = unique_sorted_ALD;
textlog.groupchange = unique_sorted_ELD;
textlog.groupchange.time.TimeZone = 'America/Los_Angeles'; % assign same time zone as ProcessRCS
textlog.adaptive = unique_sorted_AD;
textlog.recharge = unique_sorted_RD; 
%% SAVE The Text Log structure

fn = [PATIENTIDside '_textlogs.mat'];
save(fullfile(rootdir,PATIENTID,fn),'textlog')
fprintf('mat of Text Logs (Log structure) saved to \n %s \n',fullfile(rootdir,PATIENTID,fn));

%% Make the RCS database 


%% Clean and combine the session Database with Textlog database


% 
% % create new variable in database_out for group changes (extracted from EventLog.txt)
% % outside of streaming sessions
% unstreamedGroupChanges = [];
% 
% % insert EventLog changes into the following session time
% for row = 2:size(database_out, 1)
%     prior_end_times = database_out{row-1, 'time'}{1} + database_out{row-1, 'duration'}{1};
%     last_end_time = max(prior_end_times);
%     
%     curr_start_times = database_out{row, 'time'}{1};
%     first_start_time = min(curr_start_times);
%     
%     TR = timerange(last_end_time, first_start_time);
%     unstreamedGroupChanges = [unstreamedGroupChanges; {Log.groupchange(TR, 'group')}];
% end
% unstreamedGroupChanges(2:end+1,:) = unstreamedGroupChanges(1:end,:);
% 
% % new column with group changes between sessions
% database_out.unstreamedGroupChanges = unstreamedGroupChanges;

%% expanding all fields within each struct

% expanded_database = [];
% 
% for rowidx = 1:size(database_out, 1)
%     tmp_row = database_out(rowidx,:);
%     if size(tmp_row.time{1}, 1) > 1  % duplicating entire row if there are multiple entries per session
%         
%         for new_row = 1:size(tmp_row.time{1}, 1)
%             expanded_database = [expanded_database; tmp_row];
%             for col_name = ["time", "duration", "TDfs"]
%                 expanded_database{end, col_name}{1} = expanded_database{end, col_name}{1}(new_row);
%             end
%             
%             expanded_database{end}.entry = rowidx + (new_row/10); %(this will make the entry numbered for subsessions like 2.1,2.2 etc.)
%      
%         end
%     else  % print the single value  if only one entry per session\
%         
%         expanded_database = [expanded_database; tmp_row];
%                 expanded_database(end).entry = rowidx;
%         for col_name = ["time", "duration", "TDfs"]
%             expanded_database{end, col_name}{1} = expanded_database{end, col_name}{1}(1);
%         end
%         
% 
% 
%     end
% end
% 
% % expand all variables for each row
% expanded_database.time = transpose([expanded_database.time{:, 1}]);
% expanded_database.duration = transpose([expanded_database.duration{:, 1}]);
% expanded_database.TDfs = transpose([expanded_database.TDfs{:, 1}]);
% 
% 
% 
% expanded_database = table2timetable(expanded_database);
% 
% % expanded_timetable = movevars(expanded_timetable, {'TD_chan1', 'TD_chan2', 'TD_chan3', 'TD_chan4'}, 'After', 'TDfs');
% 
% RCSdatabase_out = expanded_database; % rename output for clarity

    