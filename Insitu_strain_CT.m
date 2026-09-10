function Insitu_strain_CT
% Analysis of the in situ tensile and degradation experiments where all 
% samples of the same condition are summarized. The script is optimized to
% experiments performed at he P05 beamline at DESY, Hamburg. 

% The calculations are done for each sample in Insitu_strain_CT_single,
% where the following parameter are calculated:
%   - volume: degradation, cracks, material
%   - surface area: cracks and degradation
%   - crack length
%   - degradation thickness, distance-to-surface
%   - degradation-to-crack contact


close all

% Which method should be used?
% 1 = averaging over all samples of the same condition (not recommended)
% 2 = plotting all samples and giving mean curve
analysis_method = 2;

% Which speed and medium should be analyzed?
% Speed:  1=10-3, 2=5x10-4, 3=10-4, 4=10-5
% Medium: 1=air, 2=sbf
wanted_speed  = 3;
wanted_medium = 1;
year          = ; % when was the experiment conducted? (needed to define filepath)

% where should the results be saved?
writepath = '';
addpath(writepath)

% Output wanted or not
exporting = 0;

%% Define samples

% Which samples belong to the desired condition?
if wanted_medium == 1 %==air
    if wanted_speed == 1 % 10-3
        samples   = [];
        beamtimes = [];
    elseif wanted_speed == 2 % 5x10-4
        samples   = [];
        beamtimes = [];
    elseif wanted_speed == 3 % 10-4
        samples   = [];
        beamtimes = [];
    elseif wanted_speed == 4 % 10-5
        samples   = [];
        beamtimes = [];
    end

elseif wanted_medium == 2 %==sbf
    if wanted_speed == 1 % 10-3
        samples   = [];
        beamtimes = [];
    elseif wanted_speed == 2 % 5x10-4
        samples   = [];
        beamtimes = [];
    elseif wanted_speed == 3 % 10-4
        samples   = [];
        beamtimes = [];
    elseif wanted_speed == 4 % 10-5
        samples   = [];
        beamtimes = [];
    end
end

% define exporting names
if wanted_medium == 1
    medium_name = 'air';
elseif wanted_medium == 2
    medium_name = 'SBF';
end

if wanted_speed == 1
    speed_name = '10-3';
elseif wanted_speed == 2
    speed_name = '5x10-4';
elseif wanted_speed == 3
    speed_name = '10-4';
elseif wanted_speed == 4
    speed_name = '10-5';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Script %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load images and scan parameter
fprintf('Start analysis of %s 1/s in %s...\n', speed_name, medium_name)

% Pre-allocate variables
total_stress_steps        = nan(20, numel(samples));
total_volume_material     = nan(20, numel(samples));
total_volume_cracks       = nan(20, numel(samples));
total_volume_degradation  = nan(20, numel(samples));
total_surface_cracks      = nan(50000, 20, numel(samples));
total_surface_degradation = nan(50000, 20, numel(samples));
total_portion_surf_cracks = nan(50000, 20, numel(samples));
total_dcc                 = nan(20, numel(samples));
total_length_cracks       = cell(20, numel(samples));
total_length_degradation  = cell(20, numel(samples));
total_dist_deg            = cell(20, numel(samples));

% Check if results were already saved and load them (if yes) or save
% them (if no)
if isfile([writepath sprintf('Intermediate_results/%s_%s_stress_steps.mat', speed_name, medium_name)])
    fprintf('Analyzed data found: plotting if this data...\n')
    loaded_steps          = load([writepath sprintf('Intermediate_results/%s_%s_stress_steps.mat', speed_name, medium_name)]);
    loaded_volume_mat     = load([writepath sprintf('Intermediate_results/%s_%s_volume_material.mat', speed_name, medium_name)]);
    loaded_volume_cracks  = load([writepath sprintf('Intermediate_results/%s_%s_volume_cracks.mat', speed_name, medium_name)]);
    loaded_volume_deg     = load([writepath sprintf('Intermediate_results/%s_%s_volume_deg.mat', speed_name, medium_name)]);
    loaded_surface_cracks = load([writepath sprintf('Intermediate_results/%s_%s_surface_cracks.mat', speed_name, medium_name)]);
    loaded_surface_deg    = load([writepath sprintf('Intermediate_results/%s_%s_surface_deg.mat', speed_name, medium_name)]);
    loaded_port_surface   = load([writepath sprintf('Intermediate_results/%s_%s_port_surface.mat', speed_name, medium_name)]);
    loaded_dcc            = load([writepath sprintf('Intermediate_results/%s_%s_dcc.mat', speed_name, medium_name)]);
    loaded_length_cracks  = load([writepath sprintf('Intermediate_results/%s_%s_length_cracks.mat', speed_name, medium_name)]); 
    loaded_length_deg     = load([writepath sprintf('Intermediate_results/%s_%s_length_deg.mat', speed_name, medium_name)]);
    loaded_dist_deg       = load([writepath sprintf('Intermediate_results/%s_%s_dist_deg.mat', speed_name, medium_name)]); 

    total_stress_steps        = loaded_steps.total_stress_steps;
    total_volume_material     = loaded_volume_mat.total_volume_material;
    total_volume_cracks       = loaded_volume_cracks.total_volume_cracks;
    total_volume_degradation  = loaded_volume_deg.total_volume_degradation;
    total_surface_cracks      = loaded_surface_cracks.total_surface_cracks;
    total_surface_degradation = loaded_surface_deg.total_surface_degradation;
    total_portion_surf_cracks = loaded_port_surface.total_portion_surf_cracks;
    total_dcc                 = loaded_dcc.total_dcc;
    total_length_cracks       = loaded_length_cracks.total_length_cracks; 
    total_length_degradation  = loaded_length_deg.total_length_degradation;
    total_dist_deg            = loaded_dist_deg.total_dist_deg;
else

    % Run the single analysis for each sample and save the results in the
    % pre-defined arrays
    fprintf('No results found: new calculations will take a moment..\n')
    for idx = 1:numel(samples)
        [stress_steps, volume_arrays, surface_arrays, dcc, distrib_arrays] = Insitu_strain_CT_single(samples(idx), beamtimes(idx), year);

        total_stress_steps(1:size(stress_steps,1), idx)          = stress_steps;
        total_volume_material(1:size(volume_arrays,1), idx)      = volume_arrays(:, 1);
        total_volume_cracks(1:size(volume_arrays,1), idx)        = volume_arrays(:, 2);
        total_volume_degradation(1:size(volume_arrays,1), idx)   = volume_arrays(:, 3);
        total_surface_cracks(1:size(surface_arrays,1), 1:size(surface_arrays,2), idx)      = surface_arrays(:, :, 1);
        total_surface_degradation(1:size(surface_arrays,1), 1:size(surface_arrays,2), idx) = surface_arrays(:, :, 2);
        total_portion_surf_cracks(1:size(surface_arrays,1), 1:size(surface_arrays,2), idx) = surface_arrays(:, :, 3);
        total_dcc(1:size(dcc,1), idx)                            = dcc;
        total_length_cracks(1:size(distrib_arrays,2), idx)         = distrib_arrays(1,:)';
        total_length_degradation(1:size(distrib_arrays,2), idx)    = distrib_arrays(2,:)';
        total_dist_deg(1:size(distrib_arrays,2), idx)              = distrib_arrays(3,:)';
    end

    % Save results
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_stress_steps.mat', speed_name, medium_name)),'total_stress_steps','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_volume_material.mat', speed_name, medium_name)),'total_volume_material','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_volume_cracks.mat', speed_name, medium_name)),'total_volume_cracks','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_volume_deg.mat', speed_name, medium_name)),'total_volume_degradation','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_surface_cracks.mat', speed_name, medium_name)),'total_surface_cracks','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_surface_deg.mat', speed_name, medium_name)),'total_surface_degradation','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_port_surface.mat', speed_name, medium_name)),'total_portion_surf_cracks','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_dcc.mat', speed_name, medium_name)),'total_dcc','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_length_cracks.mat', speed_name, medium_name)),'total_length_cracks','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_length_deg.mat', speed_name, medium_name)),'total_length_degradation','-v7.3');
    save(fullfile([writepath 'Intermediate_results/'],sprintf('%s_%s_dist_deg.mat', speed_name, medium_name)),'total_dist_deg','-v7.3');
end

%% Define analysis method
% How is the condition analyzed? By averaging over all samples or plotting
% all and giving the mean curve?
% The analysis is done in separate functions

if analysis_method == 1
    fprintf('Calculating average of all sample...\n')
    [fig_vol_mat, fig_vol_crack, fig_vol_deg, fig_surf_crack, fig_surf_deg, fig_dcc] = averaging_all_samples(samples, total_stress_steps, total_volume_material, total_volume_cracks, total_volume_degradation, total_surface_cracks, total_surface_degradation, total_dcc, total_length_cracks, total_length_degradation, total_dist_deg, total_portion_surf_cracks);
elseif analysis_method == 2
    fprintf('Plotting all samples and giving average line...\n')
    [fig_vol_mat, fig_vol_crack, fig_vol_deg, fig_surf_crack, fig_surf_deg, fig_dcc, fig_len_crack, fig_len_deg, fig_dist_deg_surf] = plot_all_samples(samples, total_stress_steps, total_volume_material, total_volume_cracks, total_volume_degradation, total_surface_cracks, total_surface_degradation, total_dcc, total_length_cracks, total_length_degradation, total_dist_deg, total_portion_surf_cracks);
end

%% Export plots

if exporting == 1
    fprintf('Exporting figures...\n')
    image_height = 605;
    image_width  = 810;
    if wanted_medium == 2
        exportgraphics(fig_vol_deg,       [writepath sprintf('/%s_%s_volume_degradation.png', medium_name, speed_name)],  'width', image_width, 'height', image_height);
        exportgraphics(fig_surf_deg,      [writepath sprintf('/%s_%s_surface_degradation.png', medium_name, speed_name)], 'width', image_width, 'height', image_height);
        exportgraphics(fig_len_deg,       [writepath sprintf('/%s_%s_length_degradation.png', medium_name, speed_name)],  'width', image_width, 'height', image_height);
        exportgraphics(fig_dcc,           [writepath sprintf('/%s_%s_dcc.png', medium_name, speed_name)],                 'width', image_width, 'height', image_height);
        exportgraphics(fig_dist_deg_surf, [writepath sprintf('/%s_%s_deg_dist_to_surf.png', medium_name, speed_name)],    'width', image_width, 'height', image_height);
    end
    exportgraphics(fig_vol_mat,       [writepath sprintf('/%s_%s_volume_material.png', medium_name, speed_name)], 'width', image_width, 'height', image_height);
    exportgraphics(fig_vol_crack,     [writepath sprintf('/%s_%s_volume_cracks.png', medium_name, speed_name)],   'width', image_width, 'height', image_height);
    exportgraphics(fig_surf_crack,    [writepath sprintf('/%s_%s_surface_cracks.png', medium_name, speed_name)],  'width', image_width, 'height', image_height);
    exportgraphics(fig_len_crack,     [writepath sprintf('/%s_%s_length_cracks.png', medium_name, speed_name)],   'width', image_width, 'height', image_height);
end

end

%% Additional functions

function [fig_vol_mat, fig_vol_crack_deg, fig_surf_crack_deg, fig_dcc] = averaging_all_samples(samples, total_stress_steps, total_volume_material, total_volume_cracks, total_volume_degradation, total_surface_cracks, total_surface_degradation, total_dcc, total_length_cracks, total_length_degradation, total_dist_deg, total_portion_surf_cracks)
% all samples of the same condition are averaged over. As the variation
% between the different samples can be large, the error may be high and it
% is difficult to interpret the results.

%% Find equal stress steps

% which sample has most scans?
[~, most_scans]  = max(sum(total_stress_steps~=0));
all_samples      = 1:1:numel(samples);
samples_to_check = all_samples(all_samples~=most_scans);

% pre-allocate padded arrays
pad_stress_steps = zeros(nnz(total_stress_steps(:,most_scans)),numel(samples));
pad_dcc          = nan(nnz(total_stress_steps(:,most_scans)),numel(samples));
pad_volume_material     = nan(nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_volume_cracks       = nan(nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_volume_degradation  = nan(nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_surface_cracks      = nan(50000, nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_surface_degradation = nan(50000, nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_portion_surf_cracks = nan(50000, nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_length_cracks       = cell(nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_length_degradation  = cell(nnz(total_stress_steps(:,most_scans)), numel(samples));
pad_dist_deg            = cell(nnz(total_stress_steps(:,most_scans)), numel(samples));

% Go through the scans and check if all other samples have stress steps 
% with +- 3 MPa. If not, pad the array with NaN. 
% !!! All arrays need to be padded accordingly !!!

for idx_scan = 1:nnz(total_stress_steps(:,most_scans))
    for idx_sample = 1:numel(samples_to_check)
        % Define stress threshold
        min_stress = floor(total_stress_steps(idx_scan,most_scans)-3);
        max_stress = ceil(total_stress_steps(idx_scan,most_scans)+3);

        % which samples have stress steps in threshold?
        current_sample       = samples_to_check(idx_sample);
        current_stress_steps = round(total_stress_steps(:, current_sample));
        found_stress_step    = current_stress_steps(current_stress_steps >= min_stress & current_stress_steps <= max_stress & current_stress_steps>0);

        % If a roughly equal stress step is found, add the results in the
        % padded arrays
        if nnz(found_stress_step) == 1
            [pos_stress_step, ~] = find(round(current_stress_steps)==found_stress_step,1);
            pad_stress_steps(idx_scan, current_sample)           = total_stress_steps(pos_stress_step,current_sample);
            pad_dcc(idx_scan, current_sample)                    = total_dcc(pos_stress_step, current_sample);
            pad_volume_material(idx_scan, current_sample)        = total_volume_material(pos_stress_step, current_sample);
            pad_volume_cracks(idx_scan, current_sample)          = total_volume_cracks(pos_stress_step, current_sample);
            pad_volume_degradation(idx_scan, current_sample)     = total_volume_degradation(pos_stress_step, current_sample);
            pad_surface_cracks(:, idx_scan, current_sample)      = total_surface_cracks(:, pos_stress_step, current_sample);
            pad_surface_degradation(:, idx_scan, current_sample) = total_surface_degradation(:, pos_stress_step, current_sample);
            pad_portion_surf_cracks(:, idx_scan, current_sample) = total_portion_surf_cracks(:, pos_stress_step, current_sample);
            pad_length_cracks(idx_scan, current_sample)          = total_length_cracks(pos_stress_step, current_sample);
            pad_length_degradation(idx_scan, current_sample)     = total_length_degradation(pos_stress_step, current_sample);
            pad_dist_deg(idx_scan, current_sample)               = total_dist_deg(pos_stress_step, current_sample);

        % if more than one stress step fits, redo but with smaller
        % interval
        elseif nnz(found_stress_step) > 1
            % Adjust threshold
            min_stress = total_stress_steps(idx_scan,most_scans)-2;
            max_stress = total_stress_steps(idx_scan,most_scans)+2;

            % find stress step of new threshold
            current_sample       = total_stress_steps(:,samples_to_check(idx_sample));
            found_stress_step    = current_sample(current_sample >= min_stress & current_sample <= max_stress);
            [pos_stress_step, ~] = find(found_stress_step,'first');

            % add to padded array
            pad_stress_steps(idx_scan, current_sample)           = total_stress_steps(pos_stress_step,current_sample);
            pad_dcc(idx_scan, current_sample)                    = total_dcc(pos_stress_step, current_sample);
            pad_volume_material(idx_scan, current_sample)        = total_volume_material(pos_stress_step, current_sample);
            pad_volume_cracks(idx_scan, current_sample)          = total_volume_cracks(pos_stress_step, current_sample);
            pad_volume_degradation(idx_scan, current_sample)     = total_volume_degradation(pos_stress_step, current_sample);
            pad_surface_cracks(:, idx_scan, current_sample)      = total_surface_cracks(:, pos_stress_step, current_sample);
            pad_surface_degradation(:, idx_scan, current_sample) = total_surface_degradation(:, pos_stress_step, current_sample);
            pad_portion_surf_cracks(:, idx_scan, current_sample) = total_portion_surf_cracks(:, pos_stress_step, current_sample);
            pad_length_cracks(idx_scan, current_sample)          = total_length_cracks(pos_stress_step, current_sample);
            pad_length_degradation(idx_scan, current_sample)     = total_length_degradation(pos_stress_step, current_sample);
            pad_dist_deg(idx_scan, current_sample)               = total_dist_deg(pos_stress_step, current_sample);
        end
    end
end

% add the results of the longest sample
pad_stress_steps(:, most_scans)           = total_stress_steps(1:nnz(total_stress_steps(:,most_scans)),most_scans);
pad_dcc(:, most_scans)                    = total_dcc(1:nnz(total_stress_steps(:,most_scans)), most_scans);
pad_volume_material(:, most_scans)        = total_volume_material(1:nnz(total_stress_steps(:,most_scans)), most_scans);
pad_volume_cracks(:, most_scans)          = total_volume_cracks(1:nnz(total_stress_steps(:,most_scans)), most_scans);
pad_volume_degradation(:, most_scans)     = total_volume_degradation(1:nnz(total_stress_steps(:,most_scans)), most_scans);
% pad_surface_cracks(:, :, most_scans)      = total_surface_cracks(:, 1:nnz(total_stress_steps(:,most_scans)), most_scans);
% pad_surface_degradation(:, :, most_scans) = total_surface_degradation(:, 1:nnz(total_stress_steps(:,most_scans)), most_scans);
% pad_portion_surf_cracks(:, :, most_scans) = total_portion_surf_cracks(:, 1:nnz(total_stress_steps(:,most_scans)), most_scans);
% pad_length_cracks(:, most_scans)          = total_length_cracks(1:nnz(total_stress_steps(:,most_scans)), most_scans);
% pad_length_degradation(:, most_scans)     = total_length_degradation(1:nnz(total_stress_steps(:,most_scans)), most_scans);
% pad_dist_deg(:, most_scans)               = total_dist_deg(1:nnz(total_stress_steps(:,most_scans)), most_scans);


%% Average over all samples

% The arrays are now of the same length with ~the same stress steps being
% aligned. Now, the values need to be averaged and the stabw calculated.
% For the surface calculations, the averaging makes no sense, because the
% array consists of all the detected cracks and their respective surface
% area. An averaging would make sense if the overall surface area is taken
% not the individual areas.

%avg_stress_steps       = mean(pad_stress_steps, 2, 'omitnan');
avg_dcc                = mean(pad_dcc, 2, 'omitnan');
avg_volume_material    = mean(pad_volume_material, 2, 'omitnan');
avg_volume_cracks      = mean(pad_volume_cracks, 2, 'omitnan');
avg_volume_degradation = mean(pad_volume_degradation, 2, 'omitnan');

%std_stress_steps       = std(pad_stress_steps, 0, 2, 'omitnan');
std_dcc                = std(pad_dcc, 0, 2, 'omitnan');
std_volume_material    = std(pad_volume_material, 0, 2, 'omitnan');
std_volume_cracks      = std(pad_volume_cracks, 0, 2, 'omitnan');
std_volume_degradation = std(pad_volume_degradation, 0, 2, 'omitnan');

%% Plot results

fprintf('Plot results...\n')

% Figure settings
set(groot, 'defaultAxesFontSize', 26)
marker_size_err = 18;
err_line_width = 1.3;
hereon_blue = [0 70 125]/255;
hereon_red  = [230 0 70]/255;

fig_vol_mat = figure;
errorbar(pad_stress_steps(:,most_scans), avg_volume_material.*10^9, std_volume_material.*10^9, 'o', 'MarkerSize', marker_size_err, 'MarkerEdgeColor', hereon_blue, 'MarkerFaceColor', hereon_blue, 'LineWidth', err_line_width);
xlabel('Stress / MPa')
ylabel('Volume / mm³')
xlim([0 300])
ylim([0 2.1])

fig_vol_crack_deg = figure;
vc_err = errorbar(pad_stress_steps(:,most_scans), avg_volume_cracks.*10^9, std_volume_cracks.*10^9, 'o', 'MarkerSize', marker_size_err, 'MarkerEdgeColor', hereon_blue, 'MarkerFaceColor', hereon_blue, 'LineWidth', err_line_width);
hold on
vd_err = errorbar(pad_stress_steps(:,most_scans), avg_volume_degradation.*10^9, std_volume_degradation.*10^9, 'o', 'MarkerSize', marker_size_err, 'MarkerEdgeColor', hereon_red, 'MarkerFaceColor', hereon_red, 'LineWidth', err_line_width);
hold off
vc_err.MarkerSize = marker_size_err;
vd_err.MarkerSize = marker_size_err;
xlabel('Stress / MPa')
ylabel('Volume / mm³')
legend('cracks', 'degradation')
xlim([0 300])
ylim([0 0.0005])

fig_surf_crack_deg = figure;
scatter(total_stress_steps, sum(total_surface_cracks).*10^6, 35, hereon_blue, 'filled')
hold on
scatter(total_stress_steps, sum(total_surface_degradation).*10^6, 30, hereon_red, 'filled')
hold off
xlabel('Stress / MPa')
ylabel('Surface Area / mm²')
legend('cracks', 'degradation', 'Location', 'southeast')
xlim([0 300])
ylim([0 0.1])

fig_port_cracks = figure;
scatter(total_stress_steps, total_portion_surf_cracks, 35, hereon_blue, 'filled')
xlabel('Stress / MPa')
ylabel('Surface cracks / %')
xlim([0 300])
ylim([0 100])

fig_dcc = figure;
errorbar(pad_stress_steps(:,most_scans), avg_dcc, std_dcc, 'o', 'MarkerSize', marker_size_err, 'MarkerEdgeColor', hereon_red, 'MarkerFaceColor', hereon_red, 'LineWidth', err_line_width);
set(gca,'YScale', 'log')
xlabel('Stress / MPa')
ylabel('DCC / %')
xlim([0 300])
ylim([0 15])
end

function [fig_vol_mat, fig_vol_crack, fig_vol_deg, fig_surf_crack, fig_surf_deg, fig_dcc, fig_len_crack, fig_len_deg, fig_dist_deg_surf] = plot_all_samples(samples, total_stress_steps, total_volume_material, total_volume_cracks, total_volume_degradation, total_surface_cracks, total_surface_degradation, total_dcc, total_length_cracks, total_length_degradation, total_dist_deg, total_portion_surf_cracks)
% All samples of the same condition are plotted. As the variation between
% samples can be high, this method shows the true behavior of each sample.

%% Distribution plots
% To make it easier to understand, the mean value and error of the
% distributions is plotted instead of all distributions

% Create distribution plots
lambda_dist_cracks       = zeros(size(total_stress_steps,1), size(total_length_cracks, 1));
lambda_dist_degradation  = zeros(size(total_stress_steps,1), size(total_length_degradation, 1));
lambda_dist_distance_deg = zeros(size(total_stress_steps,1), size(total_dist_deg, 1));

std_dist_cracks       = zeros(size(total_stress_steps,1), size(total_length_cracks, 1));
std_dist_degradation  = zeros(size(total_stress_steps,1), size(total_length_degradation, 1));
std_dist_distance_deg = zeros(size(total_stress_steps,1), size(total_dist_deg, 1));

for idx_sample = 1:size(total_length_cracks, 2)
    for steps = 1:size(total_length_cracks, 1)
        
        % Take lambda und calculate standard deviation
        if ~isempty(total_length_cracks{steps, idx_sample})
            interm_poisson = total_length_cracks{steps, idx_sample};
            lambda_dist_cracks(steps, idx_sample)       = interm_poisson.lambda;
            std_dist_cracks(steps, idx_sample)          = sqrt(lambda_dist_cracks(steps, idx_sample));
        end

        if ~isempty(total_length_degradation{steps, idx_sample})
            interm_poisson = total_length_degradation{steps, idx_sample};
            lambda_dist_degradation(steps, idx_sample)  = interm_poisson.lambda;
            std_dist_degradation(steps, idx_sample)     = sqrt(lambda_dist_degradation(steps, idx_sample));
            lambda_dist_distance_deg(steps, idx_sample) = total_dist_deg{steps, idx_sample}.lambda;
            std_dist_distance_deg(steps, idx_sample)    = sqrt(lambda_dist_distance_deg(steps, idx_sample));
        end
    end
end

%% Plot results

% Figure settings
set(groot, 'defaultAxesFontSize', 26)
marker_size_err  = 18;
marker_size_scat = 120;
err_line_width   = 1.3;
color_array      = [230, 159, 0; 86, 180, 233; 0, 158, 115; 240, 228, 66]./255; 
symbol_array     = {'o', 'd', 'square', '^'};

% Material volume
fig_vol_mat       = figure;
legend_vol_mat    = cell(1, numel(samples));
legend_vol_mat(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    scatter(total_stress_steps(:,idx_sample), total_volume_material(:,idx_sample).*10^9, marker_size_scat, symbol_array{idx_sample}, 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :))
    legend_vol_mat{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

xlabel('\sigma / MPa')
ylabel('V / mm³')
legend(legend_vol_mat)
xlim([0 300])
ylim([0 4])
xticks(0:100:300)

% Crack volume
fig_vol_crack       = figure;
legend_vol_crack    = cell(1, numel(samples));
legend_vol_crack(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    scatter(total_stress_steps(:,idx_sample), total_volume_cracks(:,idx_sample).*10^9, marker_size_scat, symbol_array{idx_sample}, 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :))
    legend_vol_crack{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

xlabel('\sigma / MPa')
ylabel('V / mm³')
legend(legend_vol_crack, 'Location', 'northwest')
xlim([0 300])
ylim([0 0.0007])
xticks(0:100:300)

% Degradation volume
fig_vol_deg       = figure;
legend_vol_deg    = cell(1, numel(samples));
legend_vol_deg(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    scatter(total_stress_steps(:,idx_sample), total_volume_degradation(:,idx_sample).*10^9, marker_size_scat, symbol_array{idx_sample}, 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :))
    legend_vol_deg{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

xlabel('\sigma / MPa')
ylabel('V / mm³')
legend(legend_vol_deg, 'Location','northwest')
xlim([0 300])
ylim([0 0.1])
xticks(0:100:300)

% Crack surface area
fig_surf_crack       = figure;
legend_surf_crack    = cell(1, numel(samples));
legend_surf_crack(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    scatter(total_stress_steps(:,idx_sample), sum(total_surface_cracks(:,:,idx_sample), 'omitnan').*10^6, marker_size_scat, symbol_array{idx_sample}, 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :))
    legend_surf_crack{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

set(gca,'YScale', 'log')
xlabel('\sigma/ MPa')
ylabel('A / mm²')
legend(legend_surf_crack, 'Location', 'northwest')
xlim([0 300])
xticks(0:100:300)
ylim([0 4])

% Degradation surface area
fig_surf_deg       = figure;
legend_surf_deg    = cell(1, numel(samples));
legend_surf_deg(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    scatter(total_stress_steps(:,idx_sample), sum(total_surface_degradation(:,:,idx_sample), 'omitnan').*10^6, marker_size_scat, symbol_array{idx_sample}, 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :))
    legend_surf_deg{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

set(gca,'YScale', 'log')
xlabel('\sigma / MPa')
ylabel('A / mm²')
legend(legend_surf_deg, 'Location', 'northwest')
xlim([0 300])
ylim([0 13])
xticks(0:100:300)

% DCC
fig_dcc       = figure;
legend_dcc    = cell(1, numel(samples));
legend_dcc(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    scatter(total_stress_steps(:,idx_sample), total_dcc(:,idx_sample), marker_size_scat, symbol_array{idx_sample}, 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :))
    legend_dcc{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

xlabel('\sigma / MPa')
ylabel('DCC / %')
legend(legend_dcc, 'Location', 'northwest')
xlim([0 300])
ylim([0 15])
xticks(0:100:300)
yticks(0:5:15)

% Crack length
fig_len_crack        = figure;
legend_len_cracks    = cell(1, numel(samples));
legend_len_cracks(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    errorbar(total_stress_steps(:,idx_sample), lambda_dist_cracks(:,idx_sample), std_dist_cracks(:,idx_sample), symbol_array{idx_sample}, 'Color', color_array(idx_sample, :), 'MarkerSize', marker_size_err, 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :), 'LineWidth', err_line_width);
    legend_len_cracks{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

xlabel('\sigma / MPa')
ylabel('l_{cracks} / µm')
legend(legend_len_cracks, 'Location', 'northwest')
xlim([0 300])
xticks(0:100:300)

% Degradation depth
fig_len_deg       = figure;
legend_len_deg    = cell(1, numel(samples));
legend_len_deg(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    errorbar(total_stress_steps(:,idx_sample), lambda_dist_degradation(:,idx_sample), std_dist_degradation(:,idx_sample), symbol_array{idx_sample}, 'MarkerSize', marker_size_err, 'Color', color_array(idx_sample, :), 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :), 'LineWidth', err_line_width);
    legend_len_deg{idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

xlabel('\sigma / MPa')
ylabel('t_{degradation} / µm')
legend(legend_len_deg, 'Location', 'northwest')
xlim([0 300])
ylim([0 50])
xticks(0:100:300)
yticks(0:10:50)

% Distance degradation to surface
fig_dist_deg_surf       = figure;
legend_dist_deg_surf    = cell(1, numel(samples));
legend_dist_deg_surf(:) = '';

hold on
grid on
for idx_sample = 1:numel(samples)
    errorbar(total_stress_steps(:,idx_sample), lambda_dist_distance_deg (:,idx_sample), std_dist_distance_deg(:,idx_sample), symbol_array{idx_sample}, 'MarkerSize', marker_size_err, 'Color', color_array(idx_sample, :), 'MarkerEdgeColor', color_array(idx_sample, :), 'MarkerFaceColor', color_array(idx_sample, :), 'LineWidth', err_line_width);
    legend_dist_deg_surf {idx_sample} = sprintf('Sample %d', idx_sample);
end
hold off

xlabel('\sigma / MPa')
ylabel('d_{surf} / µm')
legend(legend_dist_deg_surf, 'Location', 'northeast')
xlim([0 300])
ylim([0 200])
xticks(0:100:300)
yticks(0:50:200)
end