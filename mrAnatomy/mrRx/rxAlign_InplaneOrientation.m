function rx = rxAlign_InplaneOrientation(session,varargin)
%
% rxAlign([view or session dir]);
%
% Interface to use mrRx to perform alignments
% on mrVista sessions.
%
% The argument can either be the path to a mrVista
% session directory, or a view from an existing
% directory. If omitted, it assumes you're already
% in the session directory and starts up a hidden
% inplane view.
%
% To save the alignment, you'll want to use the
% following menu in the control figure:
%
% File | Save ... | mrVista alignment
%
% ras 03/05.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Changed the way the inplane is loaded to the way it is done in mrVista to
% account for a flip in the z-axis between mrVista and rxAlign. This occured for some older
% sessions that have been processed using the fLocAnalysis Script using the
% 'mri Convert force ras' function from freesurfer. For a more detailed description see below.
% MN 11/18

if ieNotDefined('session'), session = pwd;  end

mrGlobals;

if isstruct(session)
    % assume view; set globals
    inplane = session;
    clear session;
elseif ischar(session)
    HOMEDIR = session;
    loadSession;
    inplane = initHiddenInplane;
    clear session;
end

% get vAnatomy / xformed volume
vANATOMYPATH = getVAnatomyPath(mrSESSION.subject);
[vol volVoxelSize] = readVolAnat(vANATOMYPATH);

% get anatomy / reference volume
if ~isfield(inplane,'anat') || isempty(inplane.anat)
    inplane = loadAnat(inplane);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% This part has been edited to fix the issue that parameter maps
% were not transformed correctly from inplane to volume view after the
% niis of the inplane and functional runs underwent 'mri convert force ras'
% (in the flocAnalysis).The 'mri convert force ras' had been introduced to account for
% issues of axes being flipped when they came from the scanner. It resolved 
% that issue but removed some information from the nii header causing issues 
% with rxAlign in some cases. It is assumed that the parameter maps were 
% flipped because the inplane was loaded in different ways in rxAlign and 
% in mrVista. The following lines of code intend to load the inplane as in 
% mrVista to solve that problem. It has been tested both on sessions
% processed using mri_Convert and without. 

inplane = viewSet(inplane, 'Inplane orientation', sessionGet(mrSESSION,'functional orientation'));

% go ahead and (re)load the anatomicals with the new orientation setting
inplane = loadAnat(inplane, sessionGet(mrSESSION,'Inplane Path'));
anat = inplane.anat.data;

% Now We don't need this anymore
%anat = viewGet(inplane,'Anatomy Data');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ipVoxelSize = viewGet(inplane,'Voxel Size');

vol = double(vol);
anat = double(anat);

% call mrRx
rx = mrRx(vol, anat, 'volRes', volVoxelSize, 'refRes', ipVoxelSize);

% open a prescription figure
rx = rxOpenRxFig(rx);

% % check for a screen save file
% if exist('Raw/Anatomy/SS','dir')
% %     rxLoadScreenSave;
%     openSSWindow;
% end

% check for an existing params file
paramsFile = fullfile(HOMEDIR,'mrRxSettings.mat');
if exist(paramsFile,'file')
    rx = rxLoadSettings(rx,paramsFile);
    rxRefresh(rx);
else
	% add a few decent defaults
    hmsg = msgbox('Adding some preset Rxs ...');
    rx = rxMidSagRx(rx);
    rx = rxMidCorRx(rx);
    rx = rxObliqueRx(rx);
    close(hmsg);
end

% load any existing alignment
if isfield(mrSESSION,'alignment')
    rx = rxLoadMrVistaAlignment(rx,'mrSESSION.mat');
end


return
