clear all
close all


spikeSorted = True;


if SpikeSorted

%this should be dynamically done for time being let this be
analyzedFolder = '/mnt/disk15tb/mmpatil/MEA_Analysis/AnalyzedData/';
end

project_name = 'Organoid';

% set DIV 0 date

div0 = '12/13/2022'; % format: MM/DD/YYYY

% Burst Parameters.


% set Gaussian kernel standard deviation [s] (smoothing window)
gaussianSigma = 0.16; %0.18
% set histogram bin size [s]
binSize = 0.02;
% set minimum peak distance [s]
minPeakDistance = 1.0;
% set burst detection threshold [rms / fixed]
thresholdBurst =1.5; %1.2
% set fixed threshold;
use_fixed_threshold = false;
% Set the threshold to find the start and stop time of the bursts. (start-stop threshold)
thresholdStartStop = 0.4; %0.3

%%%%% ignore settings below if choose to use auto path setting %%%%%
% manually set path to folder containing subfolders that contain h5 files
%parentFolderPath = '/mnt/harddrive-2/ADNP/';
parentFolderPath = '/mnt/harddrive-2/Organoids_Mandeep_Fink_Lab/Cdkl5_Organoids_Mano0855-D/221118/16719/';
% set path to excel file that has the reference note
%refDir = '/home/jonathan/Documents/Scripts/Python/ADNP_Notes.xlsx';
refDir = '/home/mmp/Documents/Syngap3_Notes.xlsx';
% set output folder
%opDir = '/home/jonathan/Documents/Scripts/Matlab/scripts_output/ADNP/';
opDir = '/home/mmp/Documents/test_output/Syngap3_withoutss/';

% Set Threshold function for later use
threshold_fn = 'Threshold';
if use_fixed_threshold
    threshold_fn = 'FixedThreshold';
end

% make output folder
if not(isfolder(append(opDir,'Network_outputs/Raster_BurstActivity/')))
    mkdir(append(opDir,'Network_outputs/Raster_BurstActivity/'));
end

% extract runID info from reference excel sheet
T = readtable(refDir);
run_ids = unique(T.(4));
run_id_and_type = [T(:,[4,7])];

% defines
% convert div 0 to date datatype
div0_date = datetime(div0, "InputFormat",'MM/dd/yyyy');
% create table elements
Run_ID = [];
DIV = [];
Time = [];
Chip_ID = [];
IBI = [];
Burst_Peak = [];
Number_Bursts = [];
Spike_per_Burst = [];

% create a list to catch error runIDs
error_l = [];

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(parentFolderPath, '**/Network/**/*raw.h5'); 
theFiles = dir(filePattern);

for k = 1 : length(theFiles)
    % reset recording info
    scan_runID = nan;
    scan_chipID = nan;
    meanIBI = nan;
    meanBurstPeak = nan;
    nBursts = nan;
    meanSpikesPerBurst = nan;
    spikesPerBurst = nan;
    hd5Date = nan; 
    scan_div = nan;

    baseFileName = theFiles(k).name;
    pathFileNetwork = fullfile(theFiles(k).folder, baseFileName);
    
    if spikeSorted
        fileParts = strsplit(theFiles(k).folder, '/');
        matFilePath = strjoin(fileParts(end-5:end), '/');
        matFilePath = [matFilesFolder matFilePath '/'];



    end
    % extract dir informationfileNames
    fileDirParts = strsplit(pathFileNetwork, filesep); % split dir into elements
    scan_runID = str2double(fileDirParts{end-1}); % extract runID
    scan_runID_text = fileDirParts{end-1};
    scan_chipID = str2double(fileDirParts{end-3}); % extract chipID

    if ismember(scan_runID,run_ids)
        fprintf(1, 'Now reading %s\n', pathFileNetwork);

        % create fileManager object for the Network recording
        try
            networkData = mxw.fileManager(pathFileNetwork);
        catch
            error_l = [error_l string(scan_runID_text)];
            continue
        end
        
        samplingFreq =networkData.fileObj.samplingFreq;
        % get the startTime of the recordings
        hd5_time = networkData.fileObj.stopTime;
        try
            hd5Date = datetime(hd5_time,'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        catch
            hd5Date = datetime(hd5_time,'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
        end
        scan_div = fix(daysact(div0_date , hd5Date));
    
        if spikeSorted
        
            fprintf(1, 'Now reading mat files in  %s\n', matFilePath);
            matfilePattern = fullfile(matFilePath,'*.mat');
            matFiles = dir(matfilePattern);
            relativeSpikeTimes.time = {};
            relativeSpikeTimes.channel = {};
            for z = 1 :numel(matFiles)
            try
                

                spiking_data = load(matFiles); 
               
                % If everything is successful, display a message
                fprintf('Successfully read the .mat file: %s\n', matFilePath);
                
            catch ME
                % Handle the error
                fprintf('Error while reading the .mat file: %s\n', ME.message);
                
                % Exit MATLAB with an error code (optional)
                exit(1);
            end
            
            spikeTimes = spiking_data.spike_frames / samplingFreq;
            firstFrame = min(spikeTimes);

            relativeSpikeTimes.time{end+1} = spikeTimes - firstFrame;
            relativeSpikeTimes.channel{end+1} = spiking_data.units;
            end
            networkAct = mxw.networkActivity.computeNetworkAct(relativeSpikeTimes, 'BinSize', binSize,'GaussianSigma', gaussianSigma);
            networkStats = computeNetworkStats_JL(networkAct, threshold_fn, thresholdBurst, 'MinPeakDistance', minPeakDistance);
    

        else
         % compute Network Activity and detect bursts
        relativeSpikeTimes = mxw.util.computeRelativeSpikeTimes(networkData);
        networkAct = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', binSize,'GaussianSigma', gaussianSigma);
        networkStats = computeNetworkStats_JL(networkAct, threshold_fn, thresholdBurst, 'MinPeakDistance', minPeakDistance);
    
        end
       
        
        %% Tim's code for averaging and aggregating mean spiking data (IBI, Burst peaks, Spikes within Bursts, # of Bursts etc.)
        %average IBI
        meanIBI = mean(networkStats.maxAmplitudeTimeDiff);
        %average Burst peak (burst firing rate y-value)
        meanBurstPeak = mean(networkStats.maxAmplitudesValues);
        %Number of bursts
        nBursts = length(networkStats.maxAmplitudesTimes);
        


        %average spikesPerBurst        
        if length(networkStats.maxAmplitudesTimes)>3
            peakAmps = networkStats.maxAmplitudesValues';
            peakTimes = networkStats.maxAmplitudesTimes;
            
            % get the times of the burst start and stop edges
            edges = double.empty(length(peakAmps),0);
            for i = 1:length(peakAmps)
               % take a sizeable (±6 s) chunk of the network activity curve 
               % around each burst peak point
               idx = networkAct.time>(peakTimes(i)-6) & networkAct.time<(peakTimes(i)+6);
               t1 = networkAct.time(idx);
               a1 = networkAct.firingRate(idx)';
              
               % get the amplitude at the desired peak width
               peakWidthAmp = (peakAmps(i)-round(peakAmps(i)*thresholdStartStop));
               
               % get the indices of the peak edges
               idx1 = find(a1<peakWidthAmp & t1<peakTimes(i));
               idx2 = find(a1<peakWidthAmp & t1>peakTimes(i));
               
               if ~isempty(idx1)&&~isempty(idx2)       
                   tBefore = t1(idx1(end));
                   tAfter = t1(idx2(1));
                   edges(i,[1 2]) = [tBefore tAfter];
               end
            end
            if spikeSorted
            
            ts = ((double(spikeTimes)...
                - double(firstFrame))/networkData.fileObj.samplingFreq)';
            ch = spiking_data.units;

            else
           % identify spikes that fall within the bursts
            ts = ((double(networkData.fileObj.spikes.frameno)...
                - double(networkData.fileObj.firstFrameNum))/networkData.fileObj.samplingFreq)';
            ch = networkData.fileObj.spikes.channel;
            end
            spikesPerBurst = double.empty(length(edges),0);
            tsWithinBurst = [];
            chWithinBurst = [];
            for i = 1:length(edges)
               idx = (ts>edges(i,1) & ts<edges(i,2));
               spikesPerBurst(i) = sum(idx); 
               tsWithinBurst = [tsWithinBurst ts(idx)];
               chWithinBurst = [chWithinBurst ch(idx)'];
            end
            meanSpikesPerBurst = mean(spikesPerBurst);
        end
   
        % append information to table elements
        Run_ID = [Run_ID scan_runID];
        DIV = [DIV scan_div];
        Time = [Time hd5Date];
        Chip_ID = [Chip_ID scan_chipID];
        IBI = [IBI meanIBI];
        Burst_Peak = [Burst_Peak meanBurstPeak];
        Number_Bursts = [Number_Bursts nBursts];
        Spike_per_Burst = [Spike_per_Burst meanSpikesPerBurst];
        runIDstemp = run_id_and_type.Run_;
        types = run_id_and_type.NeuronSource;
        index = find(runIDstemp == scan_runID);
        targetType = types{index};
        % plot results
            figure('Color','w','Position',[0 0 400 800],'Visible','off');
            subplot(2,1,1);
            mxw.plot.rasterPlot(relativeSpikeTimes,'Figure',false);
            box off;
            %xlim([0 round(max(relativeSpikeTimes.time)/4)])
            xlim([0 120])
            ylim([1 max(relativeSpikeTimes.channel)])
            
            subplot(2,1,2);
            mxw.plot.networkActivity(networkAct,'Threshold',thresholdBurst,'Figure',false);
            box off;
            hold on;
            plot(networkStats.maxAmplitudesTimes,networkStats.maxAmplitudesValues,'or')
            %xlim([0 round(max(relativeSpikeTimes.time)/4)])
            xlim([0 120])
            ylim([0 20])
            saveas(gcf,append(opDir,'Network_outputs/Raster_BurstActivity/Raster_BurstActivity',scan_runID_text,'_',num2str(scan_chipID),'_DIV',num2str(scan_div),'_',targetType,'.png'))
            %savefig(append(opDir,'Network_outputs/Raster_BurstActivity/Raster_BurstActivity',scan_runID_text,'.fig'))
    end
end

%% construct table
% convert row list to columns
Run_ID = Run_ID';
DIV = DIV';
Time = Time';
Chip_ID = Chip_ID';
IBI = IBI';
Burst_Peak = Burst_Peak';
Number_Bursts = Number_Bursts';
Spike_per_Burst = Spike_per_Burst';
% make table
T = table(Run_ID,DIV,Time,Chip_ID,IBI,Burst_Peak,Number_Bursts,Spike_per_Burst);
T = sortrows(T,"Run_ID","ascend");
writetable(T, fullfile(opDir,'Network_outputs/Compiled_Networks.csv'));

if ~isempty(error_l)
    error_str = strjoin(error_l,', ');
    fprintf('Unable to read file with runID: %s, file(s) skipped.\n',error_str);
end

fprintf('Network analysis successfully compiled.\n')















