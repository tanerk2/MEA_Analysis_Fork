function [output_arg] = Compare_NetworkParameters(fileDir, refDir, outDir, parameter,param_val, varargin)

p = inputParser;
p.addRequired('fileDir');
p.addRequired('refDir');
p.addRequired('outDir');
p.addRequired('parameter');
p.addParameter('BaseParameters', [0.3, 0.1, 1.0, 1.2, false, 0.3]);
p.addParameter('VarParameter', [0, 0.2, 2]);
p.addParameter('Assay', 'today')

p.parse(fileDir, refDir, outDir, parameter, varargin{:});
args = p.Results;

%set path to folder containing subfolders that contain h5 files
% parentFolderPath = '/mnt/harddrive-2/CDKL5/CDKL5/230328/';
parentFolderPath = fileDir;

%make output folder
%opDir = char('/home/jonathan/Documents/Scripts/Matlab/scrpits_output/CDKL5/ParameterCompare_MinPeakDistance/');
opDir = char(append(outDir, "ParameterCompare_", parameter, "/"));
mkdir(opDir);

% set base parameters
% set Gaussian kernel standard deviation [s] (smoothing window)
gaussianSigma_opt = args.BaseParameters(1);
% set histogram bin size [s]
binSize_opt = args.BaseParameters(2);
% set minimum peak distance [s]
minPeakDistance_opt = args.BaseParameters(3);
% set burst detection threshold [rms firing rate]
thresholdBurst_opt = args.BaseParameters(4);
% set fixed threshold;
use_fixed_threshold = args.BaseParameters(5);
% Set the threshold to find the start and stop time of the bursts. (start-stop threshold)
thresholdStartStop = args.BaseParameters(6);


% Set parameter start, increment, and end values
parameter_start = args.VarParameter(1);
parameter_inc = args.VarParameter(2);
if parameter_start == 0 && or(strcmp(parameter,'Gaussian'),strcmp(parameter,'BinSize'))
    parameter_start = parameter_start + parameter_inc;
end
parameter_end = args.VarParameter(3);
% set output plot x-axis increment
plot_inc = (parameter_end - parameter_start)*.1;

% Set Threshold function for later use
threshold_fn = 'Threshold';
if use_fixed_threshold
    threshold_fn = 'FixedThreshold';
end

% extract wt/het ChipIDs from reference sheet
T = readtable(refDir);
wt_T = T(contains(T.(7),'wt',IgnoreCase=true),:);
wt = unique(wt_T.(6)).';
het_T = T(contains(T.(7),'het',IgnoreCase=true),:);
het = unique(het_T.(6)).';

% create a list to catch error runIDs
error_l = [];

% double check if wt/het has same ChipIDs
if ~isempty(intersect(wt,het))
    error('Some chips are labled with more than one genotype. Please double check the reference sheet and make sure the information is correct.')
end

% extract run ids based on the desired assay type
assay_T = T(contains(T.(3),'network',IgnoreCase=true) & contains(T.(3), args.Assay, IgnoreCase=true),:);
asssy_runIDs = unique(assay_T.(4)).';

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(parentFolderPath, '**/Network/**/*raw.h5'); 
theFiles = dir(filePattern);
%Mandar's implementation of electrodes./
csv_data=readtable("/home/mmp/disktb/mmpatil/MEA_Analysis/Python/path_electrodes_2.csv" ,'Delimiter', ',');

for f = 1 : length(theFiles)
    baseFileName = theFiles(f).name;
    %fullFileName = fullfile(theFiles(k).folder, baseFileName);
    pathFileNetwork = fullfile(theFiles(f).folder, baseFileName);
    % extract dir information
    fileDirParts = strsplit(pathFileNetwork, filesep); % split dir into elements
    runID = str2double(fileDirParts{end-1}); % extract runID
    if ismember(runID,asssy_runIDs)
        fprintf(1, 'Now reading %s\n', pathFileNetwork);
        
        
        % create fileManager object for the Network recording
        try
            networkData = mxw.fileManager(pathFileNetwork);
        catch
            error_l = [error_l string(runID)];
            continue
        end

        %mandars
        % Step 2: Find the matching row index (assuming the file path is in the 'FilePath' column)
        matchingRowIndex = find(strcmp(csv_data.path, pathFileNetwork));
        
        if isempty(matchingRowIndex)
            disp('File path not found in the CSV file.');
        else
            % Step 3: Get the electrode value (assuming the electrode values are in the 'Electrode' column)
            electrodesInterest = csv_data.electrodes(matchingRowIndex);

            % Remove the brackets '[' and ']' from the character array
            electrodesInterest = electrodesInterest{1};
            electrodesInterest = strrep(electrodesInterest, '[', '');
            electrodesInterest = strrep(electrodesInterest, ']', '');
            electrodesInterest = str2num(electrodesInterest);

            if isempty(electrodesInterest)
                disp('No specific electrodes of interest')
            else
                matchingIndices =ismember(networkData.rawMap.map.electrode,electrodesInterest);

                %updating networkData.rawMap
                
                networkData.rawMap.map.channel=networkData.rawMap.map.channel(matchingIndices);
                networkData.rawMap.map.electrode=networkData.rawMap.map.electrode(matchingIndices);
                networkData.rawMap.map.x=networkData.rawMap.map.x(matchingIndices);
                networkData.rawMap.map.y=networkData.rawMap.map.y(matchingIndices);
                
                
                %updating the extracted spikes.
                networkData.extractedSpikes.frameno = networkData.extractedSpikes.frameno(matchingIndices);
                networkData.extractedSpikes.amplitude = networkData.extractedSpikes.amplitude(matchingIndices);
                
                %now get channels mapping.
                matchingChannelIndices = ismember(networkData.rawMap.spikes.channel,networkData.rawMap.map.channel);
                networkData.rawMap.spikes.channel = networkData.rawMap.spikes.channel(matchingChannelIndices);
                networkData.rawMap.spikes.frameno = networkData.rawMap.spikes.frameno(matchingChannelIndices);
                networkData.rawMap.spikes.amplitude = networkData.rawMap.spikes.amplitude(matchingChannelIndices);
                
                %updating the networkData.fileObj
                networkData.fileObj.map = networkData.rawMap.map;
                networkData.fileObj.spikes = networkData.rawMap.spikes;
                
                
                %updating networkData.processsedMap
                matchingIndices =ismember(networkData.processedMap.electrode,electrodesInterest);
                networkData.processedMap.electrode = networkData.processedMap.electrode(matchingIndices);
                networkData.processedMap.xpos = networkData.processedMap.xpos(matchingIndices);
                networkData.processedMap.ypos = networkData.processedMap.ypos(matchingIndices);
                networkData.processedMap.recordingIndex = ones(length(networkData.processedMap.electrode),1);
                networkData.processedMap.nonRoutedElec= (0:26399)';
                indicesToRemove = ismember(networkData.processedMap.nonRoutedElec, networkData.processedMap.electrode);
                networkData.processedMap.nonRoutedElec(indicesToRemove)=[];
            end

            
        end

        
        %% Loop through different parameters.
        avg_opt_title = parameter;
        Averages_opt = [{'ChipID',avg_opt_title,'IBI','Burst Peak','# Bursts','Spikes per Burst'}];
    
        %relativeSpikeTimes_opt = mxw.util.computeRelativeSpikeTimes(networkData);
    
        for k = parameter_start:parameter_inc:parameter_end

            % reset values
            meanSpikesPerBurst = nan;
            meanIBI = nan;        
            meanBurstPeak = nan;       
            nBursts = nan;
            spikesPerBurst = NaN;


            % compute network according to desired parameter to compare
            if strcmp(parameter, 'Gaussian')
                networkAct_opt = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', binSize_opt,'GaussianSigma', k);
                networkStats_opt =computeNetworkStats_JL(networkAct_opt, threshold_fn, thresholdBurst_opt, 'MinPeakDistance', minPeakDistance_opt);
            elseif strcmp(parameter, 'BinSize')
                networkAct_opt = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', k,'GaussianSigma', gaussianSigma_opt);
                networkStats_opt = computeNetworkStats_JL(networkAct_opt, threshold_fn, thresholdBurst_opt, 'MinPeakDistance', minPeakDistance_opt);
            elseif strcmp(parameter, 'Threshold')
                networkAct_opt = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', binSize_opt,'GaussianSigma', gaussianSigma_opt);
                networkStats_opt = computeNetworkStats_JL(networkAct_opt, 'Threshold', k, 'MinPeakDistance', minPeakDistance_opt);
            elseif strcmp(parameter, 'FixedThreshold')
                networkAct_opt = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', binSize_opt,'GaussianSigma', gaussianSigma_opt);
                networkStats_opt = computeNetworkStats_JL(networkAct_opt, 'FixedThreshold', k, 'MinPeakDistance', minPeakDistance_opt);
            elseif strcmp(parameter, 'StartStopThreshold')
                networkAct_opt = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', binSize_opt,'GaussianSigma', gaussianSigma_opt);
                networkStats_opt = computeNetworkStats_JL(networkAct_opt, threshold_fn, thresholdBurst_opt, 'MinPeakDistance', minPeakDistance_opt);
                thresholdStartStop = k;
            elseif strcmp(parameter, 'MinPeakDistance')
                networkAct_opt = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', binSize_opt,'GaussianSigma', gaussianSigma_opt);
                networkStats_opt = computeNetworkStats_JL(networkAct_opt, threshold_fn, thresholdBurst_opt, 'MinPeakDistance', k);
            end
    
            %{
            networkAct_opt = mxw.networkActivity.computeNetworkAct(networkData, 'BinSize', binSize_opt,'GaussianSigma', gaussianSigma_opt);
            networkStats_opt = mxw.networkActivity.computeNetworkStats_test(networkAct_opt, 'Threshold', thresholdBurst_opt, 'MinPeakDistance', minPeakDistance_opt);
            %}
    
            meanIBI_opt = mean(networkStats_opt.maxAmplitudeTimeDiff);
            meanBurstPeak_opt = mean(networkStats_opt.maxAmplitudesValues);
            nBursts_opt = length(networkStats_opt.maxAmplitudesTimes);
            
            %{
            % Set the threshold to find the start and stop time of the bursts.
            %This is the Start-Stop threshold from the Scope software
            %thresholdStartStop = 0.3;
            % 0.3 means 30% value of the burst peak. Note that by raising
            % the value, the percentage of spikes within bursts and the burst duration 
            % increase, since the bursts are considered wider. 
            %}
    
            if length(networkStats_opt.maxAmplitudesTimes)>3
                peakAmps = networkStats_opt.maxAmplitudesValues';
                peakTimes = networkStats_opt.maxAmplitudesTimes;
                
                % get the times of the burst start and stop edges
                edges = double.empty(length(peakAmps),0);
                for i = 1:length(peakAmps)
               % take a sizeable (±6 s) chunk of the network activity curve 
               % around each burst peak point
                   idx = networkAct_opt.time>(peakTimes(i)-6) & networkAct_opt.time<(peakTimes(i)+6);
                   t1 = networkAct_opt.time(idx);
                   a1 = networkAct_opt.firingRate(idx)';
                  
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
                
               % identify spikes that fall within the bursts
                ts = ((double(networkData.fileObj.spikes.frameno)...
                    - double(networkData.fileObj.firstFrameNum))/networkData.fileObj.samplingFreq)';
                ch = networkData.fileObj.spikes.channel;
                
                spikesPerBurst = double.empty(length(edges),0);
                tsWithinBurst = [];
                chWithinBurst = [];
                for i = 1:length(edges)
                   idx = (ts>edges(i,1) & ts<edges(i,2));
                   spikesPerBurst(i) = sum(idx); 
                   tsWithinBurst = [tsWithinBurst ts(idx)];
                   chWithinBurst = [chWithinBurst ch(idx)'];
                   meanSpikesPerBurst = mean(spikesPerBurst);
                end
            end
            
        %%Tim's code for averaging and aggregating mean spiking data (IBI, Burst
        %%peaks, Spikes within bursts, # of Bursts etc.)
            
        %chipID =  str2num( regexprep( pathFileNetwork, {'\D*([\d\.]+\d)[^\d]*', '[^\d\.]*'}, {'$1 ', ' '} ) )
        extractChipID = regexp(pathFileNetwork,'\d{5}\.?','match');
        %chipID = regexp(pathFileNetwork,'\d{5}\.?\d*','match')
        chipID = extractChipID(:,2);
        
        
        chipAverages = [];
        
        %average spikesPerBurst
        meanSpikesPerBurst = mean(spikesPerBurst);
        
        %average IBI
        meanIBI = mean(networkStats_opt.maxAmplitudeTimeDiff);
        
        %average Burst peak (burst firing rate y-value)
        meanBurstPeak = mean(networkStats_opt.maxAmplitudesValues);
        
        %Number of bursts
        nBursts = length(networkStats_opt.maxAmplitudesTimes);
        
        chipAverages = [meanSpikesPerBurst, meanIBI, meanBurstPeak, nBursts];
        Averages_opt = [Averages_opt; {chipID,k,meanIBI_opt, meanBurstPeak_opt, nBursts_opt, meanSpikesPerBurst}];
           
        
        end
        T = cell2table(Averages_opt(2:end,:),'VariableNames',Averages_opt(1,:));
        IDstring = string(chipID);
        writetable(T,opDir + IDstring + '.csv');
    end
end

if ~isempty(error_l)
    error_str = strjoin(error_l,', ');
    fprintf('Unable to read file with runID: %s, file skipped.\n',error_str);
end

%% Plot parameter compare
parentFolderPath = opDir;

% delete existing single plot pdf because the code will append graphs to the existing pdf
if isfile(append(opDir, "paramsCompare.pdf"))
    delete(append(opDir, "paramsCompare.pdf"));
end

% set graph x-coordinate title according to desired parameter to compare
if strcmp(parameter, 'Gaussian')
    plot_x_title = parameter;
elseif strcmp(parameter, 'BinSize')
    plot_x_title = parameter;
elseif strcmp(parameter, 'Threshold')
    plot_x_title = 'rms Threshold';
elseif strcmp(parameter, 'FixedThreshold')
    plot_x_title = 'Fixed Threshold';
elseif strcmp(parameter, 'StartStopThreshold')
    plot_x_title = 'Start-Stop Threshold';
elseif strcmp(parameter, 'MinPeakDistance')
    plot_x_title = 'Min Peak Distance';
end

IBI_max = 0;
BurstPeak_max = 0;
nBursts_max = 0;
spikePerBurst_max = 0;

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(parentFolderPath, '*.csv'); 
theFiles = dir(filePattern);
for f = 1 : length(theFiles)
    baseFileName = theFiles(f).name;
    pathFileNetwork = fullfile(theFiles(f).folder, baseFileName);
    datafile = (pathFileNetwork);
    data = readtable(datafile,'PreserveVariableNames',true);
    IBI_max = max([IBI_max, max(data.(3))]);
    BurstPeak_max = max([BurstPeak_max, max(data.(4))]);
    nBursts_max = max([nBursts_max, max(data.(5))]);
    spikePerBurst_max = max([spikePerBurst_max, max(data.(6))]);
end

for f = 1 : length(theFiles)
    baseFileName = theFiles(f).name;
    pathFileNetwork = fullfile(theFiles(f).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', pathFileNetwork);
    
    datafile = (pathFileNetwork);
    data = readtable(datafile,'PreserveVariableNames',true);
    
    extractChipID = regexp(pathFileNetwork,'\d{5}?','match');

    idDouble = str2double(extractChipID);
    if ismember(idDouble,wt)
        geno = 'WT';
        genoStr = string(geno);
    end
    
    if ismember(idDouble,het)
        geno = 'HET';
        genoStr = string(geno);
    end    

    
    fig = figure('color','w','Position',[0 0 1600 800],'Visible','off');
    subplot(2,2,1);
    plot(data.(2),data.(3));
    title(string(extractChipID) + ' ' + genoStr + ' IBI')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end)
    xticks('auto')
    ylim([0 IBI_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    grid on

    subplot(2,2,2);
    plot(data.(2),data.(4));
    title(string(extractChipID) + ' ' + genoStr +' Burst Peak')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end)
    xticks('auto')
    ylim([0 BurstPeak_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    grid on

    subplot(2,2,3);
    plot(data.(2),data.(5));
    title(string(extractChipID) + ' ' + genoStr + ' # of Bursts')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end
    xticks('auto')
    ylim([0 nBursts_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    grid on

    subplot(2,2,4);
    plot(data.(2),data.(6));
    title(string(extractChipID) + ' ' + genoStr + ' Spikes per Burst')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end)
    xticks('auto')
    ylim([0 spikePerBurst_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    grid on

    exportFile = [opDir 'paramsCompare.pdf']; %folder and filename for raster figures
    exportgraphics(fig, exportFile ,'Append',true,'Resolution',150)
end
%% Plot all lines on one plot
fig2 = figure('color','w','Position',[0 0 800 800],'Visible','off');


% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(parentFolderPath, '*.csv'); 
theFiles = dir(filePattern);

for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
    %fullFileName = fullfile(theFiles(k).folder, baseFileName);
    pathFileNetwork = fullfile(theFiles(k).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', pathFileNetwork);
    
    datafile = (pathFileNetwork);
    data = readtable(datafile,'PreserveVariableNames',true);
    
    extractChipID = regexp(pathFileNetwork,'\d{5}?','match');

    idDouble = str2double(extractChipID);
    if ismember(idDouble,wt)
        geno = 'WT';
        genoStr = string(geno);
        color = '-k';
    end

    if ismember(idDouble,het)
        geno = 'HET';
        genoStr = string(geno);
        color = '--r';
    end    
    
    subplot(3,2,1);
    plot(data.(2),data.(3),color);
    title('IBI')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end)
    xticks('auto')
    ylim([0 IBI_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    grid on
    hold on

    subplot(3,2,2);
    plot(data.(2),data.(4),color);
    title('Burst Peak')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end)
    xticks('auto')
    ylim([0 BurstPeak_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    
    grid on
    hold on

    subplot(3,2,3);
    plot(data.(2),data.(5),color);
    title('# of Bursts')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end)
    xticks('auto')
    ylim([0 nBursts_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    
    grid on
    hold on

    subplot(3,2,4);
    plot(data.(2),data.(6),color);
    title('Spikes per Burst')
    xlabel(plot_x_title)
    %xticks(parameter_start:plot_inc:parameter_end)
    xticks('auto')
    ylim([0 spikePerBurst_max*10/8])
    xline(param_val,'b--', 'LineWidth', 0.5)
    % Add a text annotation for the xline value
    text(param_val, 0, ['x = ', num2str(param_val)], 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center')
    
    grid on
    hold on
    
end


exportFile = [opDir 'paramsCompare_singlePlot.pdf']; %folder and filename for raster figures
exportgraphics(fig2, exportFile ,'Resolution',150)

fprintf("%s compare saved at %s", parameter, opDir);
%output_arg = append(parameter, " compare saved at ", opDir);

end