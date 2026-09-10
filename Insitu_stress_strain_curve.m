function Insitu_stress_strain_curve
% Plot the stress-strain curve without the waiting and scanning time of the
% insitu SCC experiments. It can be run for a single or multiple
% sample(s).

close all

% define sample and beamtime
samples   = [];
beamtimes = []; 
years     = [];
exporting = 0;

%%%%%%%%%%%%%%%%%%%%%% Script %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create figure for plotting
plot_samples = figure;
set(gca, 'FontSize', 18)


for overall_samples = 1:numel(samples)
    sample   = samples(overall_samples);
    beamtime = beamtimes(overall_samples);
    year     = years(overall_samples);

    %% Define sample
    
    % define medium and speed

    sample_array = [ ];
    medium_array = {''};
    speed_array  = {''};  
    
    pos_sample = find(sample_array == sample,1);
    medium     = medium_array{pos_sample};
    speed      = speed_array{pos_sample};
    
    % define filepath
    folderpath = sprintf('/asap3/petra3/gpfs/p05/%d/data/1101%d/', beamtime, year);
    addpath(folderpath);

    radius=0.7*10^(-3);%m
    
    % hom many steps are there
    sample_folder = dir([folderpath sprintf('raw/%03d*_setforce',sample)]);
    
    %% Load strain data
    
    filepath_strain = [folderpath 'raw/'];
    addpath(filepath_strain)
    
    % pre-allocate arrays
    time_pusher           = [];
    position_value_pusher = [];
    time_loadcell         = [];
    force_loadcell        = [];
    data_points_pusher    = []; %how many data points does every pull have: needed for later cleaning of data
    data_points_loadcell  = [];

    numel_folder = numel(sample_folder);
    if sample == 22 && beamtime == 6384
        numel_folder = numel_folder-1;
    end
    
    % Analysis of the different force steps
    for folder_idx = 1:numel_folder
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Read strain data & calculate strain step %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % What is the folder name? Get it from the processed folder and look in
        % the raw folder
        strain_folder = sample_folder(folder_idx).name;
        name_forces   = ['/' strain_folder '_nexus.h5'];
    
        %%% Pusher results %%%
        % Time: needed for deleting the waiting time
        
        time_data_pusher = h5read([filepath_strain strain_folder name_forces],'/entry/hardware/pusher/position/time');
        time_pusher      = [time_pusher
                            time_data_pusher];
        % Position of the motor: needed for the strain calculation
        position_data_pusher  = h5read([filepath_strain strain_folder name_forces],'/entry/hardware/pusher/position/value');
        position_value_pusher = [position_value_pusher
                                 position_data_pusher];
        data_points_pusher    = [data_points_pusher
                                 numel(position_data_pusher)]; % Data points: needed for deletig the waiting time
    
        %%% Loadcell results %%%
        % Force: needed to calculate the stress. Attention: it is actually the
        % voltage that is saved. It needs to be converted with the calibration
        % factor!
        
        cal_factor = h5read([filepath_strain strain_folder name_forces],'/entry/hardware/loadcell/calibration_factor');

        % if calibration factor is empty, take it from other sample of same
        % beamtime
        if isempty(cal_factor)
            cal_factor = h5read([filepath_strain strain_folder '/' sample_folder(1).name '_nexus.h5'],'/entry/hardware/loadcell/calibration_factor');
        end
    
        force_data_loadcell  = h5read([filepath_strain strain_folder name_forces],'/entry/hardware/adc1/value');
        force_loadcell       = [force_loadcell
                                force_data_loadcell.*cal_factor]; % convert voltage to force
        data_points_loadcell = [data_points_loadcell
                                numel(force_data_loadcell)];
        % Time: needed for deleting the waiting time
    
        time_data_loadcell = h5read([filepath_strain strain_folder name_forces],'/entry/hardware/adc1/time');
        time_loadcell      = [time_loadcell
                              time_data_loadcell];
    end

    % clear the variables that have only information about one single sample
    % (it only confuses)
    clear force_data_loadcell position_data_pusher time_data_loadcell time_data_pusher
    
    %%% Ajusting the results %%%
    % 1. Set values to 0: non of the time points start at 0. Therefore, they
    %    have to be set to 0 manually. 
    % 2. Additionally, the loadcell saves negative voltage values, which has 
    %    to be adjusted.
    % 3. The position of the pusher is saved in µm and needs to be converted 
    %    to mm.
    
    time_pusher           = (time_pusher-time_pusher(1,1));
    position_value_pusher = (position_value_pusher-position_value_pusher(1,1))*10^(-3);
    time_loadcell         = (time_loadcell-time_loadcell(1,1));
    force_loadcell        = abs(force_loadcell);
    
    %%% Delete waiting time %%%
    % Attention: there are two different stress files: _nexus and
    % _nexus_setforce! 
    % _nexus mainly records during the waiting time  -> uninteresting for us
    % _nexus_setforce records during the deformation -> is used here!
    % Since we don't have data during the waiting time, the time axis needs to
    % be modified to delete the big jumps in the time
        
    filtered_time_loadcell   = nan(15000,1);
    filtered_force_loadcell  = nan(15000,1);
    filtered_time_pusher     = nan(15000,1);
    filtered_position_pusher = nan(15000,1);
    
    % find positions where time values are equal-> interpolation is not 
    % possible if there are equal x-values
    % Loadcell==stress: in the case of the loadcell, it has to be checked,
    % if the acquisition was started before the sample was reached: define
    % new starting time
    [~, pos_min_force] = min(force_loadcell(1:round(numel(force_loadcell)/4)),[],"all");
    if sample == 46
        pos_min_force = find(force_loadcell(pos_min_force:end) > 3, 1) + pos_min_force;

    elseif sample == 38 && beamtime == 6384
        [~, pos_min_force] = min(force_loadcell(3501:round(numel(force_loadcell)/2)),[],"all");
        pos_min_force = pos_min_force + 3500;

    elseif sample == 8 || sample == 6
        pos_min_force = 1;
    end

    force_loadcell = force_loadcell - force_loadcell(pos_min_force);
    start_time     = double(time_loadcell(pos_min_force));

    idx_steps = 1;
    
    for time_steps = (pos_min_force+1):numel(time_loadcell)
        if (time_loadcell(time_steps) - time_loadcell(time_steps-1)) ~= 0
            filtered_time_loadcell(idx_steps)  = time_loadcell(time_steps);
            filtered_force_loadcell(idx_steps) = force_loadcell(time_steps);

            idx_steps = idx_steps+1;
        end
    end
    
    % Pusher==strain: find position where the minimum force was detected
    % and set this as the new zero strain
    start_pusher = find(abs(double(time_pusher)-start_time) <= 100, 1);

    if sample == 38
        start_pusher = find(abs(double(time_pusher)-start_time) <= 150, 1);
    end

    position_value_pusher = position_value_pusher-position_value_pusher(start_pusher);
    idx_steps = 1;
    
    for time_steps = (start_pusher+1):numel(time_pusher)
        if (time_pusher(time_steps) - time_pusher(time_steps-1)) ~= 0
            filtered_time_pusher(idx_steps)  = time_pusher(time_steps);
            filtered_position_pusher(idx_steps) = position_value_pusher(time_steps);
            idx_steps = idx_steps+1;
        end
    end
    
    % delete additional nan values in the array
    filtered_time_loadcell   = filtered_time_loadcell(~isnan(filtered_time_loadcell));
    filtered_force_loadcell  = filtered_force_loadcell(~isnan(filtered_force_loadcell));
    filtered_time_pusher     = filtered_time_pusher(~isnan(filtered_time_pusher));
    filtered_position_pusher = filtered_position_pusher(~isnan(filtered_position_pusher));
    
    interpol_position = interp1(filtered_time_pusher, filtered_position_pusher, filtered_time_loadcell);
    
    %% Convert results

    % Convert N to MPa
    stress_sample = (filtered_force_loadcell./(pi()*radius^2))*10^(-6);

    % Convert distance to strain: the sample is 5 mm long (therefore, divide by
    % 5 ;))
    sample_length = 5; %mm

    interpol_position = interpol_position/sample_length; 
    strain_sample = interpol_position.*100;

    % Parameters from stress-strain curve
    UTS        = max(stress_sample, [], 'all');
    elongation = strain_sample(stress_sample==UTS);

    fprintf('Condition Sample %d: %s, %s 1/s\n', sample, medium, speed)
    fprintf('UTS: %.2f MPa\n', UTS)
    fprintf('Elongation to fracture: %.2f%%\n\n', elongation)
    
    %% Plot results
    color_array  = [230, 159, 0; 86, 180, 233; 0, 158, 115; 240, 228, 66]./255; 
    
    hold on
    plot(strain_sample, stress_sample, 'Color', color_array(overall_samples,:), 'LineWidth',2)
    legend_entries{1,overall_samples} = sprintf('Sample %d', overall_samples);
    grid on

    xlabel('\epsilon / %')
    ylabel('\sigma / MPa')
    ylim([0 270])
    xlim([-0.5 20])
    clear sample_end
end

legend(legend_entries, 'Location','northwest')

% re-write speed for exporting
if strcmp(speed,'5')
    speed_text = '10-3';
elseif strcmp(speed, '0p5') && contains(name_forces, 'long')
    speed_text = '10-5';
elseif strcmp(speed, '2p5')
    speed_text = '5x10-4';
elseif strcmp(speed, '0p5') && ~contains(name_forces, 'long')
    speed_text = '10-4';
end

fprintf('%s %s\n', medium, speed_text)

if exporting == 1    
    exportgraphics(plot_samples, sprintf('/asap3/petra3/gpfs/p05/2023/data/11016384/processed/Analysis results/%s_%s_stress_strain.png', medium, speed_text), 'width', 810, 'height', 605);
end
end