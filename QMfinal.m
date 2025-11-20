clc; clear; close all;

% Define file path
filename = '......\Bcorrection.xlsx'; % introduce the excel file like Bcorrection.xlsx; results of extract time series for specific lon/lat ;

% Read observational data (2015-2024)
Pr_target = xlsread(filename, 'obs');
% Split data into calibration (96) and validation (24)
calibration_size = 96;
validation_size = 24;
Pr_target_cal = Pr_target(1:calibration_size);
Pr_target_val = Pr_target(calibration_size+1:end);


% Climate change scenarios
scenarios = {'ssp126', 'ssp245', 'ssp370', 'ssp585'};
[index, CS] = listdlg('PromptString', 'Select a climate scenario:', ...
    'SelectionMode', 'single', 'ListString', scenarios, 'ListSize', [140, 100]);

if isempty(index)
    error('No scenario selected. Program terminated.');
end


% Read selected scenario data
Pr_SSP_all = xlsread(filename, scenarios{index});
Pr_SSP = Pr_SSP_all(1:120, :);
Pr_SSP_future = Pr_SSP_all(121:end, :);

% Split model data into calibration and validation
Pr_SSP_cal = Pr_SSP(1:calibration_size, :);
Pr_SSP_val = Pr_SSP(calibration_size+1:end, :);


% Define climate models and their exclusions per scenario
excluded_models = struct(...
    'ssp126', [21, 22, 31], ...
    'ssp245', [17], ...
    'ssp370', [5, 11, 17, 18, 21, 22, 31], ...
    'ssp585', []);

models = {'1.UKESM1-0-LL', '2.TaiESM1', '3.NorESM2-MM', '4.NorESM2-LM', ...
    '5.NESM3', '6.MRI-ESM2-0', '7.MPI-ESM1-2-LR', '8.MPI-ESM1-2-HR', ...
    '9.MIROC6', '10.MIROC-ES2L', '11.KIOST-ESM', '12.KACE-1-0-G', ...
    '13.IPSL-CM6A-LR', '14.INM-CM5-0', '15.INM-CM4-8', '16.IITM-ESM', ...
    '17.HadGEM3-GC31-MM', '18.HadGEM3-GC31-LL', '19.GISS-E2-1-G', ...
    '20.GFDL-ESM4', '21.GFDL-CM4_gr2', '22.GFDL-CM4', '23.FGOALS-g3', ...
    '24.EC-Earth3-Veg-LR', '25.EC-Earth3', '26.CanESM5', '27.CNRM-ESM2-1', ...
    '28.CNRM-CM6-1', '29.CMCC-ESM2', '30.CMCC-CM2-SR5', '31.CESM2-WACCM', ...
    '32.CESM2', '33.BCC-CSM2-MR', '34.ACCESS-ESM1-5', '35.ACCESS-CM2', 'median'};

% Filter out excluded models for the selected scenario
valid_indices = setdiff(1:numel(models), excluded_models.(scenarios{index}));
filtered_models = models(valid_indices);

[modelIndices, CM] = listdlg('PromptString', 'Select climate models:', ...
    'SelectionMode', 'multiple', 'ListString', filtered_models, 'ListSize', [250, 530]);

if isempty(modelIndices)
    error('No models selected. Program terminated.');
end


% Convert back to original indices
selected_models = valid_indices(modelIndices);

% Initialize storage for model evaluation metrics
model_scores = zeros(numel(selected_models), 3); % Columns: MAE, RMSE, Correlation
model_scores_cal = zeros(numel(selected_models), 3); % Columns: MAE, RMSE, Correlation
model_scores_val = zeros(numel(selected_models), 3); % Columns: MAE, RMSE, Correlation


% Identify the median model (assuming it's always the last in the list)
median_model_index = find(strcmp(models, 'median'));

% Initialize figure
figure;
hold on;
colors = lines(numel(selected_models)); % Generate distinct colors

% Storage for best model selection
best_model = '';
best_score = Inf;

for i = 1:numel(selected_models)
    modelIndex = selected_models(i);
    model_name = models{modelIndex};
    Pr_SSP_cal_model = Pr_SSP_cal(:, modelIndex);
    Pr_SSP_val_model = Pr_SSP_val(:, modelIndex);



        % Quantile Mapping for Bias Correction
    [sim_cdf, uniqueIdx] = unique(sort(Pr_SSP_cal_model)); % Ensure unique values
    obs_cdf = sort(Pr_target_cal);
    obs_cdf = obs_cdf(uniqueIdx); % Ensure same length

    % Perform Quantile Mapping
    corrected_cal = interp1(sim_cdf, obs_cdf, Pr_SSP_cal_model, 'linear', 'extrap');
    corrected_val = interp1(sim_cdf, obs_cdf , Pr_SSP_val_model);
    
    %  % GAM for Bias Correction (Calibration)
    % gam_model_cal = fitrgam(Pr_SSP_cal_model, Pr_target_cal);
    % corrected_cal = predict(gam_model_cal, Pr_SSP_cal_model);
    % 
    % % GAM for Bias Correction (Validation)
    % corrected_val = predict(gam_model_cal, Pr_SSP_val_model);

    % Plot Calibration
    subplot(2,1,1);
    plot(sort(corrected_cal), linspace(0,1,length(corrected_cal)), '--', 'Color', colors(i, :), 'LineWidth', 1, ...
        'DisplayName', model_name);
    legendEntries_cal{i} = model_name;
        hold on;
   plot(sort(Pr_SSP_cal_model), linspace(0,1,length(Pr_SSP_cal_model)), ':', 'Color', colors(i, :), 'LineWidth', 1);
  

    title('Calibration Data and CMIP6 data');
    xlabel('Precipitation'); ylabel('Cumulative Probability');
        xlim tight
    ylim tight
    grid on;
    
    
    % Plot Validation
    subplot(2,1,2);
    plot(sort(corrected_val), linspace(0,1,length(corrected_val)), '--', 'Color', colors(i, :), 'LineWidth', 1, ...
        'DisplayName', model_name);
    legendEntries_val{i} = model_name;
    hold on;
  plot(sort(Pr_SSP_val_model), linspace(0,1,length(Pr_SSP_val_model)), ':', 'Color', colors(i, :), 'LineWidth', 1);
    title('Validation Data');
    xlabel('Precipitation'); ylabel('Cumulative Probability');
        xlim tight
    ylim tight
    grid on;
   


   % Compute mean and standard deviation for model selection
   mean_sim_cal = mean(Pr_SSP_cal_model);
   mean_sim_val = mean(Pr_SSP_val_model);
   mean_corrected_cal = mean(corrected_cal);
   mean_corrected_val = mean(corrected_val);
   std_sim_cal = std(Pr_SSP_cal_model);
   std_sim_val = std(Pr_SSP_val_model);
   std_corrected_cal = std(corrected_cal);
   std_corrected_val = std(corrected_val);
   
   % Display model statistics
   fprintf('Calibration_Model: %s\n', model_name);
   fprintf('Mean (Observed): %.2f | Mean (CMIP6 data): %.2f | Mean (Bias-Corrected): %.2f \n', ...
         mean(Pr_target_cal), mean_sim_cal, mean_corrected_cal);
   fprintf('Std Dev (Observed): %.2f | Std Dev (CMIP6 data): %.2f | Std Dev (Bias-Corrected): %.2f \n', ...
         std(Pr_target_cal), std_sim_cal, std_corrected_cal);
   fprintf('--------------------------------------------------\n');
   fprintf('validation_Model: %s\n', model_name);
   fprintf('Mean (Observed): %.2f | Mean (CMIP6 data): %.2f | Mean (Bias-Corrected): %.2f \n', ...
         mean(Pr_target_val), mean_sim_val, mean_corrected_val);
   fprintf('Std Dev (Observed): %.2f | Std Dev (CMIP6 data): %.2f | Std Dev (Bias-Corrected): %.2f \n', ...
         std(Pr_target_val), std_sim_val, std_corrected_val);
   fprintf('--------------------------------------------------\n');
    
    
   % Compute Evaluation Metrics
   MAE_cal = mean(abs(corrected_cal - Pr_target_cal)); 
   MAE_val = mean(abs(corrected_val - Pr_target_val)); 
   RMSE_cal = sqrt(mean((corrected_cal - Pr_target_cal).^2));
   RMSE_val = sqrt(mean((corrected_val - Pr_target_val).^2));
   Correlation_cal = corr(corrected_cal, Pr_target_cal, 'Rows', 'complete'); % Pearson correlation
   Correlation_val = corr(corrected_val, Pr_target_val, 'Rows', 'complete'); % Pearson correlation
 
   %  % Store scores
   model_scores_cal(i, :) = [MAE_cal, RMSE_cal, Correlation_cal];
   model_scores_val(i, :) = [MAE_val, RMSE_val, Correlation_val];
   model_scores(i, :) = (model_scores_cal(i, :)+ model_scores_val(i, :))/2;
    
   % Print Results
    fprintf('Model: %s\n', models{modelIndex});
   fprintf('MAE_cal: %.3f | RMSE_cal: %.3f | Correlation_cal: %.3f \n', MAE_cal, RMSE_cal, Correlation_cal);
    fprintf('\n')
    fprintf('MAE_val: %.3f | RMSE_val: %.3f | Correlation_val: %.3f \n', MAE_val, RMSE_val, Correlation_val);
   fprintf('--------------------------------------------------\n');
end

subplot(2,1,1)
legend(legendEntries_cal); % Show all legend entries for the first plot
plot(sort(Pr_target_cal), linspace(0,1,length(corrected_cal)), '-', 'Color', 'k', 'LineWidth', 2, ...
            'DisplayName', ' Observed data');
subplot(2,1,2)
legend(legendEntries_val);
  plot(sort(Pr_target_val), linspace(0,1,length(corrected_val)), '-', 'Color', 'k', 'LineWidth', 2, ...
            'DisplayName', ' Observed data');




%% the best
% Select the best model based on lowest RMSE and highest correlation
[~, best_model_idx] = min(model_scores_cal(:, 2)+ model_scores_val(:, 2)); % Find index of min RMSE for cal + validation

best_model = models{selected_models(best_model_idx)};

gam_model_best_cal = fitrgam(Pr_SSP_cal(:,best_model_idx), Pr_target_cal);
corrected_cal_best =round(predict(gam_model_best_cal, Pr_SSP_cal(:,best_model_idx)),1);
for i=1: length(corrected_cal_best)
if corrected_cal_best(i) < 2
    corrected_cal_best(i)= 0;
end
end

corrected_val_best = round(predict(gam_model_best_cal, Pr_SSP_val(:,best_model_idx)),1);
for i=1: length(corrected_val_best)
if corrected_val_best(i) < 2
    corrected_val_best(i)= 0;
end
end

fprintf('The best model is: %s\n', best_model);

errors_cal=round((Pr_target_cal-corrected_cal_best),2);
errors_val=round((Pr_target_val-corrected_val_best),2);
RMSE_cal=round(sqrt(mean(errors_cal(:).^2)),2);
RMSE_val=round(sqrt(mean(errors_val(:).^2)),2);
MAE_cal=mean(round(abs(errors_cal(:)),2));
MAE_val=mean(round(abs(errors_val(:)),2));

barG=[[corrected_cal_best; corrected_val_best], Pr_target];

 
figure;
subplot(2,2,[1 2]);
bar(barG, 'grouped', 'LineWidth', 1.5);
ylabel('Precipitation');
%1-96 calibration 97-120 validation
title(['Bias-Corrected Precipitation GAM', best_model, ' vs Measured']);
legend('Bias-Corrected GAM', 'Measured', 'Location', 'best');
grid on


subplot(2,2,3);
h=histfit(errors_cal,10,'normal');
h(1).FaceColor = [0.3 0.3 0.3];
ylabel('Frequency')
xlabel('Errors')
grid on
title(['Error: MAE = ' num2str(MAE_cal) ', RMSE = ' num2str(RMSE_cal)]);

subplot(2,2,4);
h=histfit(errors_val,10,'normal');
h(1).FaceColor = [0.3 0.3 0.3];
ylabel('Frequency')
xlabel('Errors')
grid on
title(['Error: MAE = ' num2str(MAE_val) ', RMSE = ' num2str(RMSE_val)]);



figure;
plotregression(Pr_target_cal,corrected_cal_best)
title(['Best Model: ', best_model, ' (Calibration:r = ', num2str(corr(Pr_target_cal, corrected_cal_best), '%.2f'), ')']);
xlabel('Observation'); ylabel(['Bias correction for',best_model]);
grid on


figure;
plotregression(Pr_target_val,corrected_val_best)
title(['Best Model: ', best_model, ' (Validation:r = ', num2str(corr(Pr_target_val, corrected_val_best), '%.2f'), ')']);
xlabel('Observation'); ylabel(['Bias correction for',best_model]);
grid on

% Apply bias correction to future data using the best model
best_model_index = find(strcmp(models, best_model));
Pr_SSP_future_best_model = Pr_SSP_future(:, best_model_index);  % Get the best model's data

% GAM for future data bias correction

corrected_future_data = predict(gam_model_best_cal,Pr_SSP_future_best_model); % Use the *same* GAM model



% Plot the future bias-corrected data
% Ensure both datasets are column vectors
corrected_future_data = round(corrected_future_data(:),1); % Convert to column vector
for i=1: length(corrected_future_data)
if corrected_future_data(i) < 2
    corrected_future_data(i)= 0;
end
end
Pr_SSP_future_best_model = Pr_SSP_future_best_model(:); % Convert to column vector

% Combine the data into a matrix for grouped bar plot
bar_data = [corrected_future_data, Pr_SSP_future_best_model];



%% plot results for future (corrected VS CMIP6)
errors=round((corrected_future_data-Pr_SSP_future_best_model),2);
RMSE=round(sqrt(mean(errors(:).^2)),2);
MAE=mean(round(abs(errors(:)),2));
error_std=round(std(errors(:)),2);
figure;
subplot(2,1,1);
bar(bar_data, 'grouped', 'LineWidth', 1.5);
xlabel('Years (2025-2050)');
ylabel('Precipitation');
title(['Bias-Corrected Precipitation for Future (2025-2050) using ', best_model, ' vs CMIP6 Data']);
grid on;
bar(bar_data, 'grouped', 'LineWidth', 1.5);
xlabel('Years (2025-2050)');
ylabel('Precipitation');
title(['Bias-Corrected Precipitation for Future (2025-2050) using ', best_model, ' vs CMIP6 Data']);
grid on;
% % Add legend
legend('Bias-Corrected Future Data', 'CMIP6 Data', 'Location', 'best');
% subplot(2,2,3);


    subplot(2,1,2);
    h=histfit(errors,10,'normal');
    h(1).FaceColor = [0.3 0.3 0.3];
    ylabel('Frequency')
    xlabel('Errors')
    grid on
    title(['Error: MAE = ' num2str(MAE) ', RMSE = ' num2str(RMSE)]);
    
  



%% Decadal Simulation with Anomaly Detection and Trend Analysis

% Data Setup
aa=[corrected_cal_best; corrected_val_best];
bias_corrected_data = [aa; corrected_future_data]; % Ensure this is 1×432 data
threshold = 1.5; % Standard deviation threshold for anomaly detection

% Define time-related parameters
years = repelem(2015:2050, 12); % Repeat each year 12 times for monthly data
months = repmat(1:12, 1, 36); % Monthly breakdown (1:12 for each year)
time_indices = 1:432; % Monthly indices for plotting purposes

% Compute annual averages
unique_years = 2015:2050;
annual_means = arrayfun(@(yr) mean(bias_corrected_data(years == yr)), unique_years);

% Define decades (start and end years)
decades = [2015 2024; 2025 2034; 2035 2044; 2045 2050];

% Initialize anomaly storage
anomalies = [];

% Loop through each decade
for i = 1:size(decades, 1)
    % Extract indices for the current decade
    is_decade = (years >= decades(i, 1)) & (years <= decades(i, 2));
    decade_data = bias_corrected_data(is_decade);
    
    % Compute mean and standard deviation for the current decade
    mu = mean(decade_data);
    sigma = std(decade_data);
    
    % Identify anomalies: values beyond (mean ± threshold * std deviation)
    anomaly_indices = abs(decade_data - mu) > threshold * sigma;
    
    % Extract anomaly values and corresponding years & months
    detected_anomalies = decade_data(anomaly_indices);
    anomaly_years = years(is_decade);
    anomaly_months = months(is_decade);
    
    % Ensure consistent dimensions
    anomaly_years = anomaly_years(anomaly_indices);
    anomaly_months = anomaly_months(anomaly_indices);

    % Ensure detected_anomalies is a column vector
    detected_anomalies = detected_anomalies(:);
    anomaly_years = anomaly_years(:);
    anomaly_months = anomaly_months(:);

    % Only concatenate if there are detected anomalies
    if ~isempty(detected_anomalies)
        anomalies = [anomalies; [anomaly_years, anomaly_months, detected_anomalies]];
    end

    % Display results for the current decade
    fprintf('Decade %d-%d: Mean = %.2f, Std Dev = %.2f, Anomalies Detected = %d\n', ...
        decades(i, 1), decades(i, 2), mu, sigma, length(detected_anomalies));
end

% Display all detected anomalies in table format
if isempty(anomalies)
    disp('No anomalies detected.');
else
    disp('Detected Anomalies (Year, Month, Value):');
    disp(array2table(anomalies, 'VariableNames', {'Year', 'Month', 'Value'}));
end

%% Trend Analysis: Monthly Data
figure;

% Compute global mean and standard deviation for all data
global_mu = mean(bias_corrected_data);
global_sigma = std(bias_corrected_data);

% Fit a linear trend model
p_monthly = polyfit(time_indices, bias_corrected_data, 1);
trend_monthly = polyval(p_monthly, time_indices);

% Plot monthly data
subplot(2, 1, 1); % Monthly graph
plot(time_indices, bias_corrected_data, 'b', 'LineWidth', 1.5); hold on;
plot(time_indices, trend_monthly, 'r', 'LineWidth', 2); % Trend line

% Threshold lines
yline(global_mu + threshold * global_sigma, '--r', 'Threshold (+1.5σ)');

% Highlight anomalies
if ~isempty(anomalies)
    anomaly_time_indices = (anomalies(:, 1) - 2015) * 12 + anomalies(:, 2);
    scatter(anomaly_time_indices, anomalies(:, 3), 100, 'k', 'filled'); % Highlight anomalies
end

% Formatting monthly graph
xlabel('Time (Months from Jan 2015)');
ylabel('Bias-Corrected Data');
title('Monthly Bias-Corrected Data with Trend and Anomalies');
legend('Bias-Corrected Data', 'Trend Line', 'Upper Threshold', 'Anomalies', 'Location', 'Best');
grid on;
hold off;

%% Trend Analysis: Annual Averages
% Ensure unique_years and annual_means are column vectors
unique_years = unique_years(:);
annual_means = annual_means(:);

% Fill missing values in annual_means if any
annual_means = fillmissing(annual_means, 'linear');

% Fit a linear trend model for annual data
p_annual = polyfit(unique_years, annual_means, 1);
trend_annual = polyval(p_annual, unique_years);

% Plot annual averages
subplot(2, 1, 2); 
plot(unique_years, annual_means, 'bo-', 'LineWidth', 1.5); hold on;
plot(unique_years, trend_annual, 'r-', 'LineWidth', 2); % Trend line

% Add threshold lines
annual_mu = mean(annual_means);
annual_sigma = std(annual_means);
yline(annual_mu + threshold * annual_sigma, '--r', 'Threshold (+1.5σ)');
yline(annual_mu - threshold * annual_sigma, '--r', 'Threshold (-1.5σ)');
grid on;

% Formatting annual graph
xlabel('Year');
ylabel('Annual Mean Bias-Corrected Data');
title('Annual Averages with Trend and Threshold Lines');
legend('Annual Mean', 'Trend Line', 'Upper Threshold', 'Lower Threshold', 'Location', 'Best');

% Display trend information
fprintf('Monthly Trend Slope: %.4f per month\n', p_monthly(1));
fprintf('Annual Trend Slope: %.4f per year\n', p_annual(1));

%%
figure;

% Fit a linear trend model
p_monthly = polyfit(time_indices, bias_corrected_data, 1);
trend_monthly = polyval(p_monthly, time_indices);

% Plot monthly data
subplot(2, 1, 1); % Monthly graph
plot(time_indices, bias_corrected_data, 'b', 'LineWidth', 1.5); hold on;
plot(time_indices, trend_monthly, 'r', 'LineWidth', 2); % Trend line

% Decadal-specific ylines for monthly data
decades = [2015, 2025, 2035,2045]; % Start years of decades
colors = ['g', 'm', 'c', 'r']; % Colors for each decade

for i = 1:length(decades)
    % Define start and end months for the current decade
    start_month = (decades(i) - 2015) * 12 + 1; 
    if i < length(decades)
        end_month = (decades(i + 1) - 2015) * 12;
    else
        end_month = length(time_indices); % Until the last data point
    end

    % Extract data for the current decade
    current_decade_data = bias_corrected_data(start_month:end_month);
    
    % Define threshold values for this decade
    decade_mu = mean(current_decade_data);
    decade_sigma = std(current_decade_data);
    
    % Plot thresholds for this decade only
    plot(start_month:end_month, ...
         repmat(decade_mu + threshold * decade_sigma, end_month - start_month + 1, 1), ...
         '--', 'LineWidth', 1.5, 'Color', colors(i), ...
         'DisplayName', ['Upper Threshold (' num2str(decades(i)) 's)']);
    plot(start_month:end_month, ...
         repmat(decade_mu - threshold * decade_sigma, end_month - start_month + 1, 1), ...
         '--', 'LineWidth', 1.5, 'Color', colors(i), ...
         'DisplayName', ['Lower Threshold (' num2str(decades(i)) 's)']);
end

% Highlight anomalies
if ~isempty(anomalies)
    anomaly_time_indices = (anomalies(:, 1) - 2015) * 12 + anomalies(:, 2);
    scatter(anomaly_time_indices, anomalies(:, 3), 100, 'k', 'filled'); % Highlight anomalies
end

% Formatting monthly graph
xlabel('Time (Months from Jan 2015)');
ylabel('Bias-Corrected Data');
title('Monthly Bias-Corrected Data with Decadal Thresholds and Anomalies');
legend('Bias-Corrected Data', 'Trend Line', 'Location', 'Best');
grid on;
hold off;

%% Trend Analysis: Annual Averages
% Ensure unique_years and annual_means are column vectors
unique_years = unique_years(:);
annual_means = annual_means(:);

% Fill missing values in annual_means if any
annual_means = fillmissing(annual_means, 'linear');

% Fit a linear trend model for annual data
p_annual = polyfit(unique_years, annual_means, 1);
trend_annual = polyval(p_annual, unique_years);

% Plot annual averages
subplot(2, 1, 2); 
plot(unique_years, annual_means, 'bo-', 'LineWidth', 1.5); hold on;
plot(unique_years, trend_annual, 'r-', 'LineWidth', 2); % Trend line

% Decadal-specific ylines for annual data
for i = 1:length(decades)
    % Define start and end years for the current decade
    start_year = decades(i);
    if i < length(decades)
        end_year = decades(i + 1) - 1;
    else
        end_year = max(unique_years); % Until the last year in data
    end

    % Find indices for the current decade
    decade_indices = find(unique_years >= start_year & unique_years <= end_year);

    % Extract data for the current decade
    current_decade_years = unique_years(decade_indices);
    current_decade_data = annual_means(decade_indices);
    
    % Define threshold values for this decade
    decade_mu = mean(current_decade_data);
    decade_sigma = std(current_decade_data);

    % Plot thresholds for this decade only
    plot(current_decade_years, ...
         repmat(decade_mu + threshold * decade_sigma, length(current_decade_years), 1), ...
         '--', 'LineWidth', 1.5, 'Color', colors(i), ...
         'DisplayName', ['Upper Threshold (' num2str(start_year) 's)']);
    plot(current_decade_years, ...
         repmat(decade_mu - threshold * decade_sigma, length(current_decade_years), 1), ...
         '--', 'LineWidth', 1.5, 'Color', colors(i), ...
         'DisplayName', ['Lower Threshold (' num2str(start_year) 's)']);
end

grid on;

% Formatting annual graph
xlabel('Year');
ylabel('Annual Mean Bias-Corrected Data');
title('Annual Averages with Decadal Threshold Lines');
legend('Annual Mean', 'Trend Line', 'Location', 'Best');

% Display trend information
fprintf('Monthly Trend Slope: %.4f per month\n', p_monthly(1));
fprintf('Annual Trend Slope: %.4f per year\n', p_annual(1));

