fprintf('\n');
fprintf('========================================\n');
fprintf('    Octave Test Script Starting\n');
fprintf('========================================\n');

% --- Configuration ---
ROOT_DIR = fullfile(getenv('HOME'), 'Testing_Scripts', 'software_test_result');
SOFTWARE_DIR = 'Octave_testingResult';
SOFTWARE_FILE_PREFIX = 'Octave';

fprintf('Configuration loaded.\n');
fprintf('ROOT_DIR: %s\n', ROOT_DIR);

% --- 1. Collect Core Information ---
fprintf('\n[1/5] Collecting version information...\n');

try
    version_str = version;
    fprintf('   Octave version: %s\n', version_str);
catch err
    fprintf('   Error getting version: %s\n', err.message);
    version_str = 'unknown';
end

date_str = datestr(now, 'yyyy.mm.dd');
start_ts = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
start_time = tic;

fprintf('   Date: %s\n', date_str);

% --- 2. Collect Environment Information ---
fprintf('\n[2/5] Collecting environment information...\n');

try
    pkg_list = pkg('list');
    if isempty(pkg_list)
        custom_tools = 'No packages installed';
    else
        tool_names = cellfun(@(x) x.name, pkg_list, 'UniformOutput', false);
        custom_tools = strjoin(tool_names, ', ');
    end
    fprintf('   Packages: %s\n', custom_tools);
catch err
    fprintf('   Error listing packages: %s\n', err.message);
    custom_tools = 'Error listing packages';
end

loaded_modules = getenv('LOADEDMODULES');
partition = getenv('SLURM_JOB_PARTITION');
nodelist = getenv('SLURM_JOB_NODELIST');
slurm_id = getenv('SLURM_JOB_ID');
hostname = getenv('HOSTNAME');

if isempty(hostname)
    [~, hostname] = system('hostname');
    hostname = strtrim(hostname);
end

fprintf('   Hostname: %s\n', hostname);

% --- 3. Create Directory Structure ---
fprintf('\n[3/5] Creating output directory...\n');

outdir = fullfile(ROOT_DIR, SOFTWARE_DIR);
fprintf('  Target: %s\n', outdir);

[status, msg] = mkdir(outdir);

if status == 0
    fprintf('   ERROR: Could not create directory\n');
    fprintf('  Message: %s\n', msg);
    error('Directory creation failed');
end

fprintf('   Directory ready\n');

% --- 4. Determine Output File Name ---
fprintf('\n[4/5] Preparing output file...\n');

safe_version = regexprep(version_str, '[^\w\.\-]', '_');
outfile = fullfile(outdir, sprintf('%s_%s-%s', SOFTWARE_FILE_PREFIX, safe_version, date_str));

fprintf('  File: %s\n', outfile);

% --- 5. Write Results to File ---
fprintf('\n[5/5] Writing results...\n');

fid = fopen(outfile, 'w');
if fid == -1
    fprintf('   ERROR: Could not open file for writing\n');
    error('File creation failed');
end

fprintf(fid, '=== Octave Test Result ===\n');
fprintf(fid, 'Software: GNU Octave\n');
fprintf(fid, 'Version:   %s\n', version_str);
fprintf(fid, 'Timestamp Start: %s\n', start_ts);

fprintf(fid, '\n--- Runtime environment ---\n');
if ~isempty(hostname)
    fprintf(fid, 'Hostname: %s\n', hostname);
end

fprintf(fid, '\n--- Installed Packages (Custom Tools) ---\n');
fprintf(fid, '%s\n', custom_tools);

if ~isempty(loaded_modules)
    fprintf(fid, '\n--- Loaded modules ---\n');
    module_list = strsplit(loaded_modules, ':');
    for i = 1:length(module_list)
        if ~isempty(module_list{i})
            fprintf(fid, '%s\n', module_list{i});
        end
    end
end

if ~isempty(slurm_id) || ~isempty(partition) || ~isempty(nodelist)
    fprintf(fid, '\n--- Slurm execution info ---\n');
    if ~isempty(slurm_id)
        fprintf(fid, 'JobID:    %s\n', slurm_id);
    end
    if ~isempty(partition)
        fprintf(fid, 'Partition:%s\n', partition);
    end
    if ~isempty(nodelist)
        fprintf(fid, 'NodeList: %s\n', nodelist);
    end
end

end_ts = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
duration = toc(start_time);

fprintf(fid, '\nTimestamp End:   %s\n', end_ts);
fprintf(fid, 'Duration (sec):  %d\n', round(duration));

fclose(fid);

fprintf('   File written successfully\n');

% --- Summary ---
fprintf('\n');
fprintf('========================================\n');
fprintf('    Test Complete!\n');
fprintf('========================================\n');
fprintf('Output saved to:\n');
fprintf('%s\n', outfile);
fprintf('========================================\n');
fprintf('\n');
