function octave_test(varargin)
% OnDemand GUI test script for GNU Octave
% Usage:
%   octave_test                 % auto-detect version
%   octave_test('8.4.0')        % explicit version
%
% Output path (default):
%   ./software_test_result/Octave_testingResult/Octave_<version>-YYYY.MM.DD
% Override base dir with env: TEST_RESULT_ROOT=/path/to/root

  % ===== Config =====
  ROOT_DIR_DEFAULT = 'software_test_result';
  SOFTWARE_DIR     = 'Octave_testingResult';
  FILE_PREFIX      = 'Octave';

  % ----- helpers -----
  now_datestr = @() strftime('%Y.%m.%d', localtime(time()));
  iso_ts      = @() strftime('%Y-%m-%dT%H:%M:%S', localtime(time()));
  getenv_default = @(k,d) iff(emptystr(getenv(k)), d, getenv(k));
  function r = emptystr(s), r = isempty(s) || all(s == ' '); end
  function x = iff(c,a,b), if c, x=a; else, x=b; end
  function v = first_nonflag_arg(args)
    v = '';
    for i = 1:numel(args)
      a = args{i};
      if isempty(a) || a(1) == '-'  % ignore flags like "-f"
        continue;
      end
      v = a; return;
    end
  end
  function v = detect_version(args)
    v = first_nonflag_arg(args);
    if ~isempty(v), v = sanitize_token(v); return; end
    try
      v = version(); if ~isempty(v), v = sanitize_token(v); return; end
    catch, end
    try
      info = ver('octave');
      if ~isempty(info) && isfield(info,'Version') && ~isempty(info.Version)
        v = sanitize_token(info.Version); return;
      end
    catch, end
    v = 'unknown';
  end
  function t = sanitize_token(t)
    % Make sure version safe in filename
    t = strtrim(t);
    t = regexprep(t,'[^\w\.\-]+','_');  % keep [A-Za-z0-9_ . -]
  end
  function ok = ensure_dir(p)
    if exist(p,'dir') ~= 7
      [ok,msg] = mkdir(p);
      if ~ok, error('Failed to create directory %s: %s', p, msg); end
    end
    ok = true;
  end

  % ===== main =====
  % Resolve root directory (absolute), default to CWD/software_test_result
  root_env = getenv_default('TEST_RESULT_ROOT', '');
  if emptystr(root_env)
    base_root = fullfile(pwd, ROOT_DIR_DEFAULT);
  else
    base_root = root_env;
    if ~isabsolute(base_root), base_root = fullfile(pwd, base_root); end
  end
  base_root = strrep(base_root, filesep, filesep); %#ok<NASGU>

  % Final paths
  root_dir = base_root;
  outdir   = fullfile(root_dir, SOFTWARE_DIR);

  % Create directories (idempotent)
  ensure_dir(root_dir);
  ensure_dir(outdir);

  ver_str   = detect_version(varargin);
  date_str  = now_datestr();
  start_ts  = iso_ts();
  t0        = time();

  % Diagnostics
  loaded_modules = {};
  lm = getenv_default('LOADEDMODULES','');
  if ~emptystr(lm)
    loaded_modules = strsplit(lm, ':');
    loaded_modules = loaded_modules(~cellfun(@isempty, loaded_modules));
  end
  partition = getenv_default('SLURM_JOB_PARTITION','');
  nodelist  = getenv_default('SLURM_JOB_NODELIST','');
  jobid     = getenv_default('SLURM_JOB_ID','');

  hostname = getenv_default('HOSTNAME','');
  if emptystr(hostname)
    try, [st,out] = system('hostname'); if st==0, hostname = strtrim(out); end; catch, end
  end

  % Subset of installed packages
  pkg_lines = {};
  try
    pkgs = pkg('list');
    for i = 1:numel(pkgs)
      pkg_lines{end+1} = sprintf('%s %s', pkgs{i}.name, pkgs{i}.version); %#ok<AGROW>
    end
  catch
    % ignore
  end

  % Output file (absolute)
  outfile = fullfile(outdir, sprintf('%s_%s-%s', FILE_PREFIX, ver_str, date_str));

  % Open + write
  fid = fopen(outfile, 'w');
  if fid < 0
    error('Cannot open output file for writing: %s', outfile);
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, '=== Octave Test Result ===\n');
  fprintf(fid, 'Software: Octave\n');
  fprintf(fid, 'Version:  %s\n', ver_str);
  fprintf(fid, 'Timestamp Start: %s\n', start_ts);

  % Runtime env block
  env_lines = {};
  if ~emptystr(hostname), env_lines{end+1} = sprintf('Hostname: %s', hostname); end %#ok<AGROW>
  try, env_lines{end+1} = sprintf('Octave:  %s', version()); catch, end %#ok<AGROW>
  if ~isempty(env_lines)
    fprintf(fid, '\n--- Runtime environment ---\n');
    fprintf(fid, '%s\n', strjoin(env_lines, '\n'));
  end

  if ~isempty(pkg_lines)
    fprintf(fid, '\n--- Installed packages ---\n');
    fprintf(fid, '%s\n', strjoin(pkg_lines, '\n'));
  end

  if ~isempty(loaded_modules)
    fprintf(fid, '\n--- Loaded modules ---\n');
    fprintf(fid, '%s\n', strjoin(loaded_modules, '\n'));
  end

  if ~emptystr(partition) || ~emptystr(nodelist) || ~emptystr(jobid)
    fprintf(fid, '\n--- Slurm execution info ---\n');
    if ~emptystr(jobid),     fprintf(fid, 'JobID:    %s\n', jobid); end
    if ~emptystr(partition), fprintf(fid, 'Partition:%s\n', partition); end
    if ~emptystr(nodelist),  fprintf(fid, 'NodeList: %s\n', nodelist); end
  end

  % Wrap-up
  end_ts  = iso_ts();
  dur_sec = int32(time() - t0);
  fprintf(fid, '\nTimestamp End:   %s\n', end_ts);
  fprintf(fid, 'Duration (sec):  %d\n', dur_sec);

  % Console confirmations
  printf('Root dir:   %s\n', root_dir);
  printf('Output dir: %s\n', outdir);
  printf('Saved:      %s\n', outfile);
end

function tf = isabsolute(p)
  if ispc()
    tf = ~isempty(regexp(p, '^[A-Za-z]:[\\/]', 'once'));
  else
    tf = startsWith(p, '/');
  end
end

