function [total_stress_steps, combined_volume, combined_surface, total_dcc, combined_distrib] = Insitu_strain_CT_single(sample, beamtime, year) % analysis_insitu_CT_single
% Calculation of all parameters given in Insitu_strain_CT for individual
% samples. It can be run alone or by running Insitu_strain_CT for multiple
% samples of the same condition. 

close all

% define sample and beamtime (if not already defined by Insitu_strain_CT)
if nargin < 1
    sample = 1;
end

if nargin < 2
    beamtime = 1;
end

if nargin < 2
    year = 1;
end

vx_size  = 2.57*10^-6; %m
output = 0; % do you want to track the analysis process by printing the output to command window?
plotting  = 1; % should the results be plotted
exporting = 0; % should the results be saved?
combine   = 1; % needed if multiple analysis is used: it combines several arrays for easy use


%%%%%%%%%%%%%%%%%%%%%% Script %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Define sample

% define medium and speed
sample_array = [];
medium_array = {'air'};
speed_array  = {'0p5'};

pos_sample = find(sample_array == sample,1);
medium     = medium_array{pos_sample};
speed      = speed_array{pos_sample};

% define filepath
folderpath = sprintf('/asap3/petra3/gpfs/p05/%d/data/1101%d/', year, beamtime);
addpath(folderpath);
radius=0.7*10^(-3);%m

% how many steps are there
sample_folder = dir([folderpath sprintf('processed/%03d_*',sample)]);

% Location of strain data
filepath_strain = [folderpath 'raw/'];
addpath(filepath_strain)

%% Analysis

% Pre-allocate variables
time_pusher           = [];
position_value_pusher = [];
time_loadcell         = [];
force_loadcell        = [];
data_points_pusher    = []; %how many data points does every pull have: needed for later cleaning of data
data_points_loadcell  = [];

total_stress_steps        = nan(numel(sample_folder),1);
total_volume_material     = nan(numel(sample_folder),1);
total_volume_hydrides     = nan(numel(sample_folder),1);
total_volume_cracks       = nan(numel(sample_folder),1);
total_volume_degradation  = nan(numel(sample_folder),1);
total_surface_cracks      = nan(50000, numel(sample_folder));
total_surface_degradation = nan(50000, numel(sample_folder));
total_length_cracks       = cell(1, numel(sample_folder));
total_length_degradation  = cell(1, numel(sample_folder));
total_portion_surf_cracks = nan(numel(sample_folder),1);
total_dcc                 = nan(numel(sample_folder),1);
total_dist_deg            = cell(1, numel(sample_folder));

% Analysis of the different force steps
for folder_idx = 1:numel(sample_folder)
    
    %% Read strain data & calculate strain step

    % Reading of strain data
    strain_folder = sample_folder(folder_idx).name;
    name_forces   = [strain_folder '_nexus.h5'];

    time_data_pusher = h5read([filepath_strain strain_folder '/' name_forces],'/entry/hardware/pusher/position/time');
    time_pusher      = [time_pusher 
                        time_data_pusher];
    position_data_pusher  = h5read([filepath_strain strain_folder '/' name_forces],'/entry/hardware/pusher/position/value');
    position_value_pusher = [position_value_pusher
                             position_data_pusher];

    cal_factor          = h5read([filepath_strain strain_folder '/' name_forces],'/entry/hardware/loadcell/calibration_factor');
    time_data_loadcell  = h5read([filepath_strain strain_folder '/' name_forces],'/entry/hardware/adc1/time');
    time_loadcell       = [time_loadcell
                           time_data_loadcell];
    force_data_loadcell = h5read([filepath_strain strain_folder '/' name_forces],'/entry/hardware/adc1/value');

    % if calibration factor is empty, take it from other sample of same
    % beamtime
    if isempty(cal_factor)
        cal_factor = h5read([filepath_strain strain_folder '/' sample_folder(1).name '_nexus.h5'],'/entry/hardware/loadcell/calibration_factor');
    end

    % convert voltage to force
    force_loadcell = [force_loadcell
                      force_data_loadcell.*cal_factor];

    data_points_pusher   = [data_points_pusher
                            numel(position_data_pusher)];
    data_points_loadcell = [data_points_loadcell
                            numel(force_data_loadcell)];

    total_stress_steps(folder_idx,1) = abs((force_loadcell(end)./(pi()*radius^2))*10^(-6));
    fprintf('Analyzing %d MPa scan...\n', round(total_stress_steps(folder_idx)))
    
    %% Read images and define labels
    
    % check which labelling is present
    folder_labelled = dir([folderpath 'processed/' sample_folder(folder_idx).name '/reco/Labelled*']);
    folder_names    = {folder_labelled.name};

    if isempty(folder_labelled)
        continue
    else
    
    if output == 1
        fprintf('Reading images...\n')
    end

    % Check if there is one folder with all segmentations (air, material,
    % degradation) or separate folder

    % only one folder
    if nnz(contains(folder_names, 'Labelled_final'))>0
        images = ReadIn_images([folderpath 'processed/' sample_folder(folder_idx).name '/reco/Labelled_final/' ]);

        % Define labels
        material = images==1;
        cracks   = images==2;

    elseif isscalar(folder_names) && strcmp(folder_labelled(:).name, 'Labelled_material')
        images = ReadIn_images([folderpath 'processed/' sample_folder(folder_idx).name '/reco/Labelled_material/' ]);
        material = images==1;
        cracks   = images==2;

    % there are two folders with Labelled in name (mostly SBF)
    elseif numel(folder_names) == 2
        images_material   = ReadIn_images([folderpath 'processed/' sample_folder(folder_idx).name '/reco/Labelled_material/' ]);
        images_cracks_deg = ReadIn_images([folderpath 'processed/' sample_folder(folder_idx).name '/reco/Labelled_cracks_degradation/' ]);

        % Define labels
        material    = images_material==1;
        cracks      = images_cracks_deg==1;
        degradation = images_cracks_deg==2;
    end
    
    %% Analyze material, cracks, and degradation

    %%%%%%%%%%%%%%%%
    %%% Material %%%
    %%%%%%%%%%%%%%%%
    if output == 1
        fprintf('Analyzing material...\n')
    end

    % Calculate volume of material
    volume_material = nnz(material).*vx_size^3;

    % Calculate volume of hydrides, if they are segmented
    if exist('hydrides','var')
        volume_hydrides = nnz(hydrides).*vx_size^3;
    end    
    
    %%%%%%%%%%%%%%
    %%% Cracks %%%
    %%%%%%%%%%%%%%
    % Calculated are crack volume, crack surface area, crack length
    % (distribution)

    % check if cracks are segmented
    if nnz(cracks)>0
        
        if output == 1
            fprintf('Analyzing cracks...\n')
        end

        % Volume
        volume_cracks = nnz(cracks).*vx_size^3;

        % Regionprops: surface area (and length distribution)
        crack_conncomp      = bwconncomp(cracks, 26);
        regprops_cracks     = regionprops3(crack_conncomp,'SurfaceArea', 'PrincipalAxisLength', 'VoxelIdxList');
        surface_area_cracks = cat(1,regprops_cracks.SurfaceArea).*vx_size^2;
        voxel_cracks        = cat(1,regprops_cracks.VoxelIdxList);

        % Crack length distribution
        length_cracks = zeros(crack_conncomp.NumObjects(1),1);
        fprintf('Calculate crack length..\n')

        parfor curr_crack = 1:size(voxel_cracks,1)
            logical_cracks = false(size(cracks));
            logical_cracks(voxel_cracks{curr_crack}) = true;
            length_cracks(curr_crack) = crack_length(logical_cracks);
        end
        
        length_cracks = length_cracks.*vx_size*10^6;

        if ~isempty(length_cracks)
            dist_length_cracks  = fitdist(length_cracks,"Poisson");
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%
    %%% Surface cracks %%%
    %%%%%%%%%%%%%%%%%%%%%%

    % How many cracks reach the surface of the material?
    if exist('cracks', 'var') && ~exist('degradation', 'var')
        [portion_surface_cracks, surface_material] = surface_contact(material, cracks);
    elseif exist('cracks', 'var') &&  exist("degradation", 'var')
        [portion_surface_cracks, surface_material] = surface_contact(material, cracks, degradation);
    end
    
    %%%%%%%%%%%%%%%%%%%
    %%% Degradation %%%
    %%%%%%%%%%%%%%%%%%%
    % Calculated are degradation volume, degradation surface area, 
    % degradation length (distribution), degradation-to-crack contact
    % (DCC), degradation distance to surface

    % Check if degradation is present
    if exist('degradation','var') && nnz(degradation)>0
        
        if output == 1
            fprintf('Analyzing degradation...\n')
        end

        % Volume
        volume_degradation = nnz(degradation).*vx_size^3;

        % Regionprops: surface area and length distribution
        regprops_degradation     = regionprops3(degradation, 'SurfaceArea', 'PrincipalAxisLength'); 
        surface_area_degradation = cat(1,regprops_degradation.SurfaceArea).*vx_size^2;
        pa_length_degradation    = cat(1,regprops_degradation.PrincipalAxisLength).*vx_size;
        length_degradation       = max(pa_length_degradation,[],2).*10^6;

        if ~isempty(length_degradation)
            dist_length_degradation  = fitdist(length_degradation,"Poisson");
        end

        % Degradation-to-crack contact (DCC): how much degradation surface
        % is in contact with crack surface
        dcc = degradation_to_crack_contact(degradation, cracks).*100;

        % Distance to surface
        interm_distance_deg = deg_dist_to_surf(surface_material, degradation).*(vx_size*10^6);

        if ~isempty(interm_distance_deg)
            distance_deg = fitdist(interm_distance_deg(interm_distance_deg>0), "Poisson");
        end
    end

    %% Concatenate results
    % all results are concatenated to one array

    total_volume_material(folder_idx,1) = volume_material;
    
    if exist("hydrides","var")
        total_volume_hydrides(folder_idx,1) = volume_hydrides;
    end
    
    % have cracks been segmented?
    if nnz(cracks)>0
        total_volume_cracks(folder_idx,1)  = volume_cracks;
        total_surface_cracks(1:numel(surface_area_cracks), folder_idx) = surface_area_cracks;
        total_length_cracks{1, folder_idx} = dist_length_cracks;
        total_portion_surf_cracks(folder_idx,1) = portion_surface_cracks;
    end
    
    % has degradation been segmented?
    if exist('degradation','var') && nnz(degradation)>0
        total_volume_degradation(folder_idx,1)  = volume_degradation;
        total_surface_degradation(1:numel(surface_area_degradation),folder_idx) = surface_area_degradation;
        total_dcc(folder_idx,1) = dcc;
        
        if ~isempty(distance_deg)
            total_dist_deg{1, folder_idx} = distance_deg;
        end

        if ~isempty(length_degradation)
            total_length_degradation{1, folder_idx} = dist_length_degradation;
        end
    end
    end
end

%% Optional: Combine arrays of all samples
if combine == 1
    combined_volume(1:size(total_volume_material,1),1)        = total_volume_material;
    combined_volume(1:size(total_volume_cracks,1),2)          = total_volume_cracks;
    combined_volume(1:size(total_volume_degradation,1),3)     = total_volume_degradation;
    combined_surface(1:size(total_surface_cracks,1),:,1)      = total_surface_cracks;
    combined_surface(1:size(total_surface_degradation,1),:,2) = total_surface_degradation;
    combined_surface(1:size(total_portion_surf_cracks,1),1,3) = total_portion_surf_cracks;
    combined_distrib = [total_length_cracks; total_length_degradation; total_dist_deg];
end

%% Optional: Plot results

if plotting == 1
    if output == 1
        fprintf('Plot results...\n')
    end

    % Figure settings
    set(groot, 'defaultAxesFontSize', 15)
    hereon_blue = [0 70 125]/255;
    hereon_red  = [230 0 70]/255;
    length_gradient = numel(total_length_cracks);
    gradient_cracks = colormap(winter(length_gradient));
    gradient_deg    = colormap(autumn(length_gradient));
    
    % Material volume
    fig_vol_mat = figure;
    scatter(total_stress_steps, total_volume_material.*10^9, 35, 'filled')
    xlabel('Stress / MPa')
    ylabel('Volume / mm³')
    xlim([0 300])
    ylim([0 4])
    
    % Crack and degradation volume
    fig_vol_crack_deg = figure;
    scatter(total_stress_steps, total_volume_cracks.*10^9, 35, hereon_blue, 'filled')
    hold on
    scatter(total_stress_steps, total_volume_degradation.*10^9, 35, hereon_red, 'filled')
    hold off
    xlabel('Stress / MPa')
    ylabel('Volume / mm³')
    legend('cracks', 'degradation')
    title('Crack and degradation volume')
    xlim([0 300])
    ylim([0 0.0005])
    
    % Crack and degradation surface area
    fig_surf_crack_deg = figure;
    scatter(total_stress_steps, sum(total_surface_cracks, 'omitnan').*10^6, 35, hereon_blue, 'filled')
    hold on
    scatter(total_stress_steps, sum(total_surface_degradation, 'omitnan').*10^6, 30, hereon_red, 'filled')
    hold off
    xlabel('Stress / MPa')
    ylabel('Surface Area / mm²')
    legend('cracks', 'degradation', 'Location', 'southeast')
    title('Crack and degradation surface area')
    xlim([0 300])
    ylim([0 0.1])
    
    % Portion of surface cracks
    fig_port_cracks = figure;
    scatter(total_stress_steps, total_portion_surf_cracks, 35, hereon_blue, 'filled')
    xlabel('Stress / MPa')
    ylabel('Surface cracks / %')
    title('Portion of surface cracks')
    xlim([0 300])
    ylim([0 100])
    
    % DCC
    fig_dcc = figure;
    scatter(total_stress_steps, total_dcc, 30, hereon_red, 'filled')
    xlabel('Stress / MPa')
    ylabel('DCC / %')
    title('DCC')
    xlim([0 300])
    ylim([0 15])
    
    %%% Create distribution plots
    x_dist     = (0:1:200);
    x_dist_deg = 0:1:250;

    total_dist_cracks       = zeros(size(x_dist,2), numel(total_length_cracks));
    total_dist_degradation  = zeros(size(x_dist,2), numel(total_length_degradation));
    total_dist_distance_deg = zeros(size(x_dist_deg,2), numel(total_dist_deg));
    
    % Create figure of crack distributions
    fig_len_crack      = figure;
    ax_len_crack       = axes('Parent', fig_len_crack);
    legend_dist_cracks = {};

    hold on
    for steps = 1:numel(total_length_cracks)
        if ~isempty(total_length_cracks{steps})
            total_dist_cracks(:,steps) = pdf(total_length_cracks{steps}, x_dist);
            plot(ax_len_crack, x_dist, total_dist_cracks(:,steps),'LineWidth', 2, 'Color', gradient_cracks(steps,:));
            legend_dist_cracks{end+1} = sprintf('%d MPa', round(total_stress_steps(steps)));
        end
    end
    hold off
    grid on

    xlabel(ax_len_crack, 'Length / µm')
    ylabel(ax_len_crack, 'Number / AU')
    title('Crack length distribution')
    xlim(ax_len_crack, [0 200])
    ylim(ax_len_crack, [0 0.13])
    legend(ax_len_crack, legend_dist_cracks)
    
    % Create figure of degradation distributions
    fig_len_deg     = figure;
    ax_len_deg      = axes('Parent', fig_len_deg);
    legend_dist_deg = {};

    hold on
    for steps = 1:numel(total_length_cracks)
        if exist('degradation','var') && ~isempty(total_length_degradation{steps})
            % Calculate y values of length degradation
            total_dist_degradation(:,steps) = pdf(total_length_degradation{steps}, x_dist);
            plot(ax_len_deg, x_dist, total_dist_degradation(:,steps),'LineWidth', 2, 'Color', gradient_deg(steps,:));
            legend_dist_deg{end+1} = sprintf('%d MPa', round(total_stress_steps(steps)));
        end
    end
    hold off
    grid on

    xlabel(ax_len_deg, 'Length / µm')
    ylabel(ax_len_deg, 'Number / AU')
    title('Degradation thickness')
    xlim(ax_len_deg, [0 200])
    ylim(ax_len_deg, [0 0.15])
    legend(ax_len_deg, legend_dist_deg)
    
    % Create figure of degradation distance
    fig_dist_deg_surf    = figure;
    ax_dist_deg_surf     = axes('Parent', fig_dist_deg_surf);
    legend_dist_deg_surf = {};

    hold on
    for steps = 1:size(total_dist_deg,2)
        if exist('degradation', 'var') && ~isempty(total_dist_deg{steps})
            total_dist_distance_deg(:,steps) = pdf(total_dist_deg{steps}, x_dist_deg);
            plot(ax_dist_deg_surf, x_dist_deg, total_dist_distance_deg(:,steps),'LineWidth', 2, 'Color', gradient_deg(steps,:))
            legend_dist_deg_surf{end+1} = sprintf('%d MPa', round(total_stress_steps(steps)));
        end
    end
    hold off
    grid on

    xlabel(ax_dist_deg_surf, 'Distance to surface / µm')
    ylabel(ax_dist_deg_surf, 'Number / AU')
    title('Degradation distance to surface')
    legend(ax_dist_deg_surf, legend_dist_deg_surf)
    xlim(ax_dist_deg_surf, [0 250])
    ylim(ax_dist_deg_surf, [0 0.1])
end

%% Exporting

if exporting == 1
    fprintf('Exporting figures...\n')
    exportgraphics(fig_vol_mat, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_volume_material.png', sample, medium, speed)]);
    exportgraphics(fig_vol_crack_deg, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_volume_cracks_degradation.png', sample, medium, speed)]);
    exportgraphics(fig_surf_crack_deg, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_surface_cracks_degradation.png', sample, medium, speed)]);
    exportgraphics(fig_len_crack, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_length_cracks.png', sample, medium, speed)]);
    exportgraphics(fig_len_deg, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_length_degradation.png', sample, medium, speed)]);
    exportgraphics(fig_port_cracks, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_port_surf_cracks.png', sample, medium, speed)]);
    exportgraphics(fig_dcc, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_dcc.png', sample, medium, speed)]);
    exportgraphics(fig_dist_deg_surf, [folderpath 'processed/' sample_folder(1).name sprintf('/%03d_%s_%s_deg_dist_to_surf.png', sample, medium, speed)]);
end
end

%% Additional functions

function [percentage_surf_cracks, surface_material] = surface_contact(material, cracks, degradation)
% is the detected crack in contact with the surface (even through
% degradation)

% check if degradation is present
if nargin < 3
    degradation = 0;
end

% connected components of cracks and degradation
cc_cracks_deg = bwconncomp((cracks+degradation));
cracks_deg    = labelmatrix(cc_cracks_deg);

% calculation of surface of material
[~, surface_material] = contact_area(material, 1, 0);
surface_material      = surface_material + 1000;

% find positions by adding surface and labelled cracks_deg and finding all
% the unique values
added_labels          = double(cracks_deg) + surface_material;
number_surface_cracks = max(unique(added_labels),[],'all')-1000;

% determine the percentage of cracks reaching the surface
cc_cracks              = bwconncomp(cracks);
number_cracks          = cc_cracks.NumObjects;
percentage_surf_cracks = number_surface_cracks/number_cracks * 100;

% make surface material binary again
surface_material = surface_material -1000;
end


function dcc = degradation_to_crack_contact(degradation, crack)
% calculate the percentage of degradation surface in contact with crack
% surface

% determine crack surface: it's rather the layer around the crack so that
% later it can be added to the degradation to see where it overlaps.
% Contact_area determines the area inside first label value
[~, surface_crack] = contact_area(crack, 0, 1);

% determine degradation surface
[no_surface_deg, surface_deg] = contact_area(degradation, 0, 1);

% determine intersection of crack and degradation
comb_crack_deg = surface_crack + surface_deg;
no_crack_deg   = nnz(comb_crack_deg>1);

% DCC
dcc = no_crack_deg/no_surface_deg;

end


function dist_degradation = deg_dist_to_surf(surface_material, degradation)
% calculate the distance of the degradation to the surface of the material

idx = 1;

% determine degradation regions and their centers
cc_degradation        = bwconncomp(degradation);
regprop_degradation   = regionprops3(cc_degradation, 'Centroid');
centroids_degradation = ceil(regprop_degradation.Centroid);

% where does the degradation start and where does it end
start_deg        = min(centroids_degradation(:,3));
end_deg          = max(centroids_degradation(:,3));
sorted_centroids = sortrows(centroids_degradation, 3);

dist_degradation = zeros(50, size(sorted_centroids,1));

% calculate eucl. distance between positions: each row is the distance of 
% the respective row in first array (degradation) to all positions in 
% second array (surface). Only interesting is the min distance in each row!
for slice = start_deg:end_deg

    if nnz(sorted_centroids(:,3) == slice)>0
        curr_centroid = sorted_centroids(sorted_centroids(:,3) == slice, :);

        % find all positions of material surface
        [y_surf, x_surf] = find(surface_material(:,:,slice)>0);
    
        % distance to surface
        interm_dist_degradation = pdist2(curr_centroid(:,1:2), [x_surf y_surf]);

        % convert 0&1 to nan to omit it
        interm_dist_degradation(interm_dist_degradation<=5) = NaN;
        dist_degradation(1:size(curr_centroid,1),idx)       = min(interm_dist_degradation, [], 2, 'omitnan');

        idx = idx+1;
    end
    
end

end

function [max_length] = crack_length(cracks)

% Skeletonize the segmented cracks and prune side cracks and tiny
% cracks
skel_cracks = bwskel(cracks, 'MinBranchLength', 2); % cracks that are shorter than MinBranchLength are not considered

% find the endpoints of the crack
endpoints_crack                          = bwmorph3(skel_cracks,"endpoints");
[ep_crack_row, ep_crack_col, ep_crack_z] = ind2sub(size(skel_cracks), find(endpoints_crack));

% calculate geodesic distance in 3D: determine the longest of the
% shortest paths through crack
no_ep      = numel(ep_crack_row);
max_length = 0;


for ep = 1:no_ep

    % create seed image
    seed = false(size(skel_cracks));
    seed(ep_crack_row(ep), ep_crack_col(ep), ep_crack_z(ep)) = true;

    % geodesic distance
    interm_length = bwdistgeodesic(skel_cracks, seed, 'quasi-euclidean');

    % max. path length
    max_length = max(max_length, max(interm_length(:), [], 'omitnan'));
end
end