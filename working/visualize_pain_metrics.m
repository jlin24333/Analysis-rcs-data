%{
The purpose of this script is to visualize the pain metrics recorded 
longitudinally in the paitents' home setting (i.e., Stages 1, 2, and 3 of
the RC+S stim study for chronic pain (UH# HEAL Grant; IRB Study: G190160)).

RCS04's pain metrics will be used for the development of this
script as their data are of current clinical interest, but this script will
generalize.

For RCS04:

IVs:
    Stim programs           (A, B, C, vs D)

        Note that EVEN within a patient, the stim program letters are
        not always consistent
            -> utilize metadata from 'ProcessRCS()' and/or
               'RCS_pain_preprocess()' to define N of unique stim programs

            -> further, see how stim programs can be grouped (useful to
               reduce the number of comparisons made)

    
    Side                    (L caudate, R thalamus, vs both)
    
    Stim parameters         (polarity, pulse width, frequency, cycling, etc)
        
    
    Days on patch           (day 1, day 2, day 3)

% IJ suggestion (see Slack)

    "Left Caudate Bipolar Stim group A: Contacts 9+11- (variable amplitudes- 
    worth looking at 0.5, 1, 1.5, 2 mA respectively) 125 hz, 300 microsecond 
    pulse width
    
    Right Thalamus Bipolar Stim group A: Contacts 9+11- (variable amplitudes-
    worth looking at 0.5, 1, 1.5, 2 mA respectively) 125 hz, 300 microsecond 
    pulse width
    
    I think it would be best to compare these two for now and possibly expand 
    into including some further Left caudate stim at other contacts- but to 
    start off lets stick with this and maybe compare these two regions as well 
    as break it down by day of fentanyl patch (which can be found in RCS04s 
    streaming notes under the medication section in redcap)"

DVs:
    Daily                   (NRS-intensity, NRS-worst VAS-intensity, VAS-unpleasantness, 
                             MPQ-affective, MPQ-somatic and MPQ-total)

    Weekly                  (AE reporting, C-SSRS, Hamd6 Self-rating Scale
                            for Depression)

    Monthly                 (AE reporting, C-SSRS, Beck Depression Inventory (BDI), 
                            Beck Anxiety Inventory (BAI), Rand 36 Item SF 
                            Health Survey Instrument, IMS-25, Promis Sf
                            V11 Global Health, Clinical Global Impressions 
                            Scale)
    

Assuming sufficient (>10) number of pain metrics (see Shirvalkar et al., 2020 where
min of 10 trials is used to justify the duration of Stage 0 which allows 
generalizability of the streaming sessions indexed in this script to 
subsequent neurophy analysis).
    -> If this assumption fails, reconsider grouping.


Visualization Approach
-> flesh this out once table with pain metrics is cleanly imported



Statistical Approach
    Individual
        RCS04: (N-way ind ANOVA, regression, etc.)

        RCSXX: (2-way ind ANOVA - stim progam BY side)

    Group-level
        TBD

%}


% rootdir             = '/Volumes/PrasadX5/' ;

github_dir          = '/Users/Leriche/Github/';

% patientroot_dir     = fullfile(rootdir,char(regexp(PATIENTIDside,...
%                         '\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02
% 
% scbs_dir = fullfile(patientroot_dir,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTIDside);


cd(github_dir);         addpath(genpath(github_dir))


API_token = '95FDE91411C10BF91FD77328169F7E1B';

% pulls/organizes arms from REDcap (go into fxn to add new arms)
pt_pain            = RCS_redcap_painscores(API_token);

% import RCS files



%% plot daily metrics
%{
Specify, 'all-time' for a 5 nearest report sliding average of all daily
reported pain metrics. Alternatively, to see the last n days of pain metrics
specify 'PreviousDays' followed by n days (without the sliding average).

06/25/22 RBL
Add overlay of stim, days on patch, contacts, etc., as optional arguements 
(see introduction comment)

%}

plot_daily(pt_pain.RCS04, 'all-time');

plot_daily(pt_pain.RCS04,'PreviousDays',30);

plot_daily(pt_pain.RCS04,'PreviousDays', 14);



%% 

