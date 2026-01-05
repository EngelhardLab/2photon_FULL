function run_session_analysis(corrected_folder, syncfolder)
% One-call session analysis:
%   A) Reward vs No-reward PSTH (−3..+3 s) with proper 2p->behavior time mapping
%   B) Prev Success vs Failure by Position (logic-based success)
%   C) Current Success vs Not by Position (logic-based success)
%   D) Position tuning (overall; feature-binned)
%   E) Speed tuning (overall; feature-binned, Y-axis speed)
%   F) Cue-onset PSTH (ipsi vs contra), skipped if no cues
%
% Call: run_session_analysis(corrected_folder, syncfolder)

% ----------- defaults you can tweak here -----------
RecordedHemisphere = 'L';      % 'L' or 'R' for ipsi/contra mapping
PosEdges           = 0:10:300; % TRUE edges (cm)
SpeedEdges         = 0:50:500;       % [] => quartiles; or provide edges, e.g., [0 5 10 20 40 80]
PSTHWindow         = [-3 3];
PSTH_dt            = 0.1;
VisibleFigures     = 'off';
TrackDim           = 2;        % position/velocity axis: 1=X, 2=Y (your rig uses Y)
UseLogicSuccess    = true;     % true: choice==trialType ; false: reward present

% ----------------- load core -----------------
A = must_load(fullfile(corrected_folder,'000_all_dffs_session.mat'),'A'); 
N = numel(A);

behav_t_full = must_load(fullfile(syncfolder,'syncdata','frames_behav_time_vec.mat'),'frames_behav_time_vec');
behav_t = behav_t_full(1:2:end);                           % match stored traces (A)
rw_times = must_load(fullfile(syncfolder,'syncdata','rw_times.mat'),'rw_times'); 
rw_times = rw_times(:)';

% also load 2p timeline for timebase mapping
frames_2p_time_vec = try_load_2p_timevec(syncfolder);      % [] if not present

% behavior log (pick the LONGEST block)
bhv = dir(fullfile(syncfolder,'PoissonBlocksShapingC_Cohort5','*.mat'));
if isempty(bhv)
    tmp = dir(fullfile(syncfolder,'*.mat'));
    bad = contains({tmp.name},{'frames_','rw_times','frames_2p'});
    bhv = tmp(~bad);
end
assert(~isempty(bhv),'No behavior log .mat found.');
[~,ix] = max([bhv.datenum]);
Slog   = load(fullfile(bhv(ix).folder,bhv(ix).name),'log');
blocks = Slog.log.block;
[~, session_idx] = max(arrayfun(@(b) numel(b.trial), blocks));
trials = blocks(session_idx).trial; 
nT = numel(trials);

% ----------------- labels & windows (with proper timebase mapping) -----------------
[sT, eT_anchor, hasR, rtime_behav] = reward_labels_sync(trials, rw_times, behav_t, frames_2p_time_vec);

[trialChoice, trialType] = choice_and_type(trials);
logic_known      = ~(trialChoice=="" | trialType=="");
success_by_logic = false(nT,1); 
success_by_logic(logic_known) = strcmpi(trialChoice(logic_known), trialType(logic_known));

if UseLogicSuccess
    currTrue  =  success_by_logic & logic_known;
    currFalse = ~success_by_logic & logic_known;
    prevTrue  = [false; success_by_logic(1:end-1)];
    prevFalse = ~prevTrue;
    prevTrue(~[false; logic_known(1:end-1)])  = false; % drop unknown prev labels
    prevFalse(~[false; logic_known(1:end-1)]) = false;
else
    currTrue  = hasR;  currFalse = ~hasR;
    prevTrue  = [false; hasR(1:end-1)];
    prevFalse = ~prevTrue;
end

% ----------------- output dirs -----------------
baseout = fullfile(corrected_folder,'actv_nns','per_neuron'); mkd(baseout);

% ========================= A) Reward vs No-reward PSTH =========================
out_rnr = fullfile(baseout,'reward_vs_noreward'); mkd(out_rnr);
t_axis = PSTHWindow(1):PSTH_dt:PSTHWindow(2);
[ActR,ActN] = align_reward_no_reward(A, behav_t, t_axis, rtime_behav, eT_anchor, hasR);
cols2 = lines(2);

for c = 1:N
    [mR,seR,nR] = mean_sem(ActR(:,:,c)); [mN,seN,nN] = mean_sem(ActN(:,:,c));
    fig = figure('Visible',VisibleFigures,'Color','w'); hold on
    shaded_err(t_axis,mR,seR,'Color',cols2(1,:));
    shaded_err(t_axis,mN,seN,'Color',cols2(2,:));
    xline(0,'k-'); xlabel('Time from event (s)'); ylabel('\DeltaF/F');
    title(sprintf('Neuron %03d — Reward vs No-reward',c));
    legend({sprintf('Reward (n=%d)',nR),sprintf('No-reward (n=%d)',nN)},'Location','best');
    exportgraphics(fig, fullfile(out_rnr, sprintf('n%03d_reward_vs_noreward.png',c)), 'Resolution',300);
    close(fig);
end

% ========================= Build position & speed streams ======================
[pos_t, pos_u, pos_tid] = reconstruct_pos_with_ids(trials, TrackDim);
[pos_t, pos_u] = rescale_position_to_cm(pos_t, pos_u);  % meters->cm if needed

[spd_t, spd_u, ~]       = reconstruct_speed_with_ids(trials, TrackDim);
spd_u = abs(spd_u);                                  % absolute speed

% Clip to interpolation range to avoid NaNs:
br = [min(behav_t) max(behav_t)];
inr_pos = pos_t>=br(1) & pos_t<=br(2);  pos_t=pos_t(inr_pos); pos_u=pos_u(inr_pos); pos_tid=pos_tid(inr_pos);
inr_spd = spd_t>=br(1) & spd_t<=br(2);  spd_t=spd_t(inr_spd); spd_u=spd_u(inr_spd);

% ========================= B,C) Outcome vs POSITION ============================
raw_pos_edges = PosEdges(:)';                         % TRUE EDGES (e.g., 0:10:300)
pos_edges     = ensure_edges_cover_data(pos_u, raw_pos_edges, 'position');
pos_centers   = ((pos_edges(1:end-1) + pos_edges(2:end))/2).';   % column

prevTrue_samp  = ismember(pos_tid, find(prevTrue));
prevFalse_samp = ismember(pos_tid, find(prevFalse));
currTrue_samp  = ismember(pos_tid, find(currTrue));
currFalse_samp = ismember(pos_tid, find(currFalse));

[pos_prevTrue_means, pos_prevTrue_se, ~]   = binned_means_over_signal(A, behav_t, pos_t, pos_u, pos_edges, prevTrue_samp);
[pos_prevFalse_means,pos_prevFalse_se, ~]  = binned_means_over_signal(A, behav_t, pos_t, pos_u, pos_edges, prevFalse_samp);
[pos_currTrue_means, pos_currTrue_se, ~]   = binned_means_over_signal(A, behav_t, pos_t, pos_u, pos_edges, currTrue_samp);
[pos_currFalse_means,pos_currFalse_se, ~]  = binned_means_over_signal(A, behav_t, pos_t, pos_u, pos_edges, currFalse_samp);

out_prevpos = fullfile(baseout,'prev_outcome_vs_position'); mkd(out_prevpos);
out_currpos = fullfile(baseout,'curr_outcome_vs_position'); mkd(out_currpos);

for c = 1:N
    % Prev outcome vs Position
    fig = figure('Visible',VisibleFigures,'Color','w'); hold on
    shaded_err(pos_centers, pos_prevTrue_means(:,c),  pos_prevTrue_se(:,c),'Color',cols2(1,:));
    shaded_err(pos_centers, pos_prevFalse_means(:,c), pos_prevFalse_se(:,c),'Color',cols2(2,:));
    xlabel('Position (cm)'); ylabel('\DeltaF/F'); xlim([pos_edges(1) pos_edges(end)]);
    title(sprintf('Neuron %03d — Prev Success vs Failure (by Position)',c));
    legend({'Prev Success','Prev Failure'},'Location','best');
    exportgraphics(fig, fullfile(out_prevpos, sprintf('n%03d_prev_vs_position.png',c)), 'Resolution',300);
    close(fig);

    % Current outcome vs Position
    fig = figure('Visible',VisibleFigures,'Color','w'); hold on
    shaded_err(pos_centers, pos_currTrue_means(:,c),  pos_currTrue_se(:,c),'Color',cols2(1,:));
    shaded_err(pos_centers, pos_currFalse_means(:,c), pos_currFalse_se(:,c),'Color',cols2(2,:));
    xlabel('Position (cm)'); ylabel('\DeltaF/F'); xlim([pos_edges(1) pos_edges(end)]);
    title(sprintf('Neuron %03d — Current Success vs Not (by Position) — Neuron %03d',c,c));
    legend({'Success','Not'},'Location','best');
    exportgraphics(fig, fullfile(out_currpos, sprintf('n%03d_curr_vs_position.png',c)), 'Resolution',300);
    close(fig);
end

% ========================= D) Position tuning (overall) ========================
out_pos = fullfile(baseout,'position_tuning'); mkd(out_pos);
[pos_all_means, pos_all_se, pos_all_n] = binned_means_over_signal( ...
    A, behav_t, pos_t, pos_u, pos_edges, true(size(pos_t)));

% show mean ± SEM instead of just a plain line
col_pos = lines(1);
for c = 1:N
    fig = figure('Visible',VisibleFigures,'Color','w','Renderer','opengl'); hold on
    shaded_err(pos_centers, pos_all_means(:,c), pos_all_se(:,c), 'Color', col_pos(1,:));
    xlabel('Position (cm)'); ylabel('\DeltaF/F'); xlim([pos_edges(1) pos_edges(end)]);
    title(sprintf('Neuron %03d — Position tuning (mean \x00B1 SEM)',c));
    exportgraphics(fig, fullfile(out_pos, sprintf('n%03d_position.png',c)), 'Resolution',300);
    close(fig);
end



% ========================= E) Speed tuning (overall) ===========================
out_spd = fullfile(baseout,'speed_tuning'); mkd(out_spd);

% pick edges (you can keep your 0:10:100 default)
if isempty(SpeedEdges)
    q = quantile(spd_u(~isnan(spd_u)), [0 0.25 0.5 0.75 1]);
    spd_edges = unique(q);
    if numel(spd_edges) < 2
        m = min(spd_u); M = max(spd_u);
        spd_edges = linspace(m, max(M, m+1), 5); % 4 bins minimum
    end
else
    spd_edges = SpeedEdges(:)'; 
end
spd_edges(spd_edges<0) = 0;
spd_edges  = ensure_edges_cover_data(spd_u, spd_edges, 'speed');
spd_centers= ((spd_edges(1:end-1)+spd_edges(2:end))/2).';

% >>> compute mean, SEM, and counts
[spd_all_means, spd_all_se, spd_all_n] = binned_means_over_signal( ...
    A, behav_t, spd_t, spd_u, spd_edges, true(size(spd_t)));

% optional: one consistent color
col_spd = lines(1);

for c = 1:N
    fig = figure('Visible',VisibleFigures,'Color','w','Renderer','opengl'); hold on
    shaded_err(spd_centers, spd_all_means(:,c), spd_all_se(:,c), 'Color', col_spd(1,:));
    xlabel('Speed (cm/s)'); ylabel('\DeltaF/F');
    xlim([spd_edges(1) spd_edges(end)]);
    title(sprintf('Neuron %03d — Speed tuning (mean \x00B1 SEM)',c));
    exportgraphics(fig, fullfile(out_spd, sprintf('n%03d_speed.png',c)), 'Resolution',300);
    close(fig);
end

% (optional) stash arrays for later analysis
try
    save(fullfile(out_spd,'speed_tuning_arrays.mat'), ...
        'spd_edges','spd_centers','spd_all_means','spd_all_se','spd_all_n','-v7.3');
end

% ========================= F) Cue-onset PSTH (ipsi vs contra) =================
out_cue = fullfile(baseout,'cue_onset_ipsi_contra'); mkd(out_cue);
[left_onsets,right_onsets] = cue_onset_times(trials);

if isempty(left_onsets) && isempty(right_onsets)
    warning('No cue-onset events found; skipping cue PSTH.');
else
    switch upper(RecordedHemisphere)
        case 'L', ipsi = left_onsets;  contra = right_onsets;
        case 'R', ipsi = right_onsets; contra = left_onsets;
        otherwise, ipsi = left_onsets; contra = right_onsets;
    end
    ActI = align_events_all(A, behav_t, ipsi,   t_axis);
    ActC = align_events_all(A, behav_t, contra, t_axis);

    for c = 1:N
        [mI,seI,~] = mean_sem(ActI(:,:,c)); [mC,seC,~] = mean_sem(ActC(:,:,c));
        fig = figure('Visible',VisibleFigures,'Color','w'); hold on
        shaded_err(t_axis,mI,seI,'Color',cols2(1,:));
        shaded_err(t_axis,mC,seC,'Color',cols2(2,:));
        xline(0,'k-'); xlabel('Time from cue onset (s)'); ylabel('\DeltaF/F');
        title(sprintf('Neuron %03d — Cue-onset: Ipsi vs Contra',c));
        legend({'Ipsi','Contra'},'Location','best');
        exportgraphics(fig, fullfile(out_cue, sprintf('n%03d_cue_ipsi_contra.png',c)), 'Resolution',300);
        close(fig);
    end
end

fprintf('\nDone. Outputs in: %s\n', baseout);

   % ========================= G) 6-panel figure per neuron =========================
    out_panels = fullfile(baseout,'panels'); mkd(out_panels);

    for c = 1:N
        [mR,seR,~] = mean_sem(ActR(:,:,c));
        [mN,seN,~] = mean_sem(ActN(:,:,c));

        P = struct( ...
            't_axis',      t_axis, ...
            'r_m',         mR(:),  'r_se',  seR(:), ...
            'n_m',         mN(:),  'n_se',  seN(:), ...
            'pos_centers', pos_centers(:), ...
            'prevSucc_m',  pos_prevTrue_means(:,c),  'prevSucc_se', pos_prevTrue_se(:,c), ...
            'prevFail_m',  pos_prevFalse_means(:,c), 'prevFail_se', pos_prevFalse_se(:,c), ...
            'currSucc_m',  pos_currTrue_means(:,c),  'currSucc_se', pos_currTrue_se(:,c), ...
            'currNot_m',   pos_currFalse_means(:,c), 'currNot_se',  pos_currFalse_se(:,c), ...
            'posTune_m',   pos_all_means(:,c),       'posTune_se',  pos_all_se(:,c), ...
            'spd_centers', spd_centers(:), ...
            'spd_m',       spd_all_means(:,c),       'spd_se',      spd_all_se(:,c) ...
        );

        if exist('ActI','var') && ~isempty(ActI) && exist('ActC','var') && ~isempty(ActC)
            [mI,seI,~] = mean_sem(ActI(:,:,c));
            [mC,seC,~] = mean_sem(ActC(:,:,c));
            P.cue_t_axis = t_axis;
            P.cueI_m     = mI(:);  P.cueI_se = seI(:);
            P.cueC_m     = mC(:);  P.cueC_se = seC(:);
        end

        save_neuron_panel(c, out_panels, P);
    end

    fprintf('\nDone. Outputs in: %s\n', baseout);
end

% ================= helpers =================
function x = must_load(file,varname)
assert(exist(file,'file')==2, 'Missing file: %s', file);
S = load(file,varname);
assert(isfield(S,varname),'Missing variable %s in %s',varname,file);
x = S.(varname);
end

function mkd(p), if ~exist(p,'dir'), mkdir(p); end, end
function y = ifelse(c,a,b), if c, y=a; else, y=b; end, end

function frames_2p_time_vec = try_load_2p_timevec(syncfolder)
frames_2p_time_vec = [];
cands = {'frames_2p_time_vec.mat','frames_2p_timevec.mat'};
for i=1:numel(cands)
    f = fullfile(syncfolder,'syncdata',cands{i});
    if exist(f,'file')
        S = load(f);
        if isfield(S,'frames_2p_time_vec'), frames_2p_time_vec = S.frames_2p_time_vec; return; end
        if isfield(S,'frames_2p_timevec'),   frames_2p_time_vec = S.frames_2p_timevec; return; end
    end
end
end

function [sT, eT_anchor, hasR, rtime_behav] = reward_labels_sync(trials, rw_times, behav_t, frames_2p_time_vec)
% sT: behavior-clock start times (sec)
% eT_anchor: behavior-clock NR anchor = end-of-position sample (matches older script)
% hasR: trial has reward pulse
% rtime_behav: first reward pulse mapped into behavior time (sec)
nT = numel(trials);
rw_times = rw_times(:)';

% Map 2p clock -> behavior clock if mapping exists
if ~isempty(frames_2p_time_vec)
    t2p_ds = frames_2p_time_vec(1:2:end);
    tbh_ds = behav_t(:);
    L = min(numel(t2p_ds), numel(tbh_ds));
    t2p_ds = t2p_ds(1:L); tbh_ds = tbh_ds(1:L);
    try
        rtime_behav_all = interp1(t2p_ds, tbh_ds, rw_times, 'linear', 'extrap');
    catch
        rtime_behav_all = rw_times; % fallback
    end
else
    rtime_behav_all = rw_times;
end

sT = arrayfun(@(t) double(t.start), trials);

% trial end on behavior clock: prefer trial.time(end)
eT_time = nan(nT,1);
for k=1:nT
    if isfield(trials(k),'time') && ~isempty(trials(k).time)
        eT_time(k) = sT(k) + double(trials(k).time(end));
    elseif isfield(trials(k),'duration') && ~isempty(trials(k).duration)
        eT_time(k) = sT(k) + double(trials(k).duration);
    end
end

% NR anchor: end-of-position sample time
eT_anchor = nan(nT,1);
for k=1:nT
    t_end = eT_time(k);
    if isfield(trials(k),'position') && ~isempty(trials(k).position) && ...
       isfield(trials(k),'time')     && ~isempty(trials(k).time)
        npos = size(trials(k).position,1);
        nt   = numel(trials(k).time);
        idx  = min(npos, nt); % "ind_reward" in your old code
        t_end = sT(k) + double(trials(k).time(idx));
    end
    eT_anchor(k) = t_end;
end

% bucket reward pulses into trials (first pulse within [sT, eT_time])
hasR = false(nT,1);
rtime_behav = nan(nT,1);
for k=1:nT
    if ~isfinite(sT(k)) || ~isfinite(eT_time(k)), continue; end
    in = rtime_behav_all >= sT(k) & rtime_behav_all <= eT_time(k);
    if any(in)
        hasR(k) = true;
        rtime_behav(k) = rtime_behav_all(find(in,1,'first'));
    end
end
end

function [ch,tt] = choice_and_type(trials)
nT = numel(trials); ch = strings(nT,1); tt = strings(nT,1);
for k=1:nT
    ck=""; tk="";
    if isfield(trials(k),'choice')    && ~isempty(trials(k).choice),    ck = string(trials(k).choice);    end
    if isfield(trials(k),'trialType') && ~isempty(trials(k).trialType), tk = string(trials(k).trialType); end
    ch(k)=ck; tt(k)=tk;
end
end

function [ActR,ActN] = align_reward_no_reward(A, behav_t, t_axis, rtime_behav, eT_anchor, hasR)
% Align reward trials to reward time; non-reward to per-trial anchor
N  = numel(A); nB = numel(t_axis);
nR = sum(hasR); nN = sum(~hasR);
ActR = nan(nR,nB,N); ActN = nan(nN,nB,N);
ir=1; inr=1;
for k=1:numel(hasR)
    if hasR(k) && isfinite(rtime_behav(k))
        tx = t_axis + rtime_behav(k);
        for c=1:N, ActR(ir,:,c) = interp1(behav_t, A{c}, tx, 'linear', NaN); end
        ir=ir+1;
    elseif ~hasR(k) && isfinite(eT_anchor(k))
        tx = t_axis + eT_anchor(k);
        for c=1:N, ActN(inr,:,c) = interp1(behav_t, A{c}, tx, 'linear', NaN); end
        inr=inr+1;
    end
end
end

function [pos_t, pos_u, pos_tid] = reconstruct_pos_with_ids(trials, trackDim)
% trackDim: 1=X or 2=Y (default 2). Returns absolute times.
if nargin<2 || isempty(trackDim), trackDim = 2; end
pos_t = []; pos_u = []; pos_tid = [];
for k=1:numel(trials)
    if ~isfield(trials(k),'position') || isempty(trials(k).position), continue; end
    s = double(trials(k).start);
    % prefer trial.time base if present
    if isfield(trials(k),'time') && ~isempty(trials(k).time)
        tvec = double(trials(k).time(:));
        nP   = size(trials(k).position,1);
        tloc = linspace(tvec(1), tvec(end), nP) + s;  % absolute time
    else
        if isfield(trials(k),'duration') && ~isempty(trials(k).duration)
            d = double(trials(k).duration);
        else, d = NaN; end
        if ~isfinite(d), continue; end
        nP   = size(trials(k).position,1);
        tloc = linspace(0, d, nP) + s;
    end
    P = double(trials(k).position(:,trackDim));   % axis choice (Y)
    pos_t  = [pos_t;  tloc(:)];
    pos_u  = [pos_u;  P(:)];
    pos_tid= [pos_tid; repmat(k,nP,1)];
end
end

function [spo_t, spo_u] = rescale_position_to_cm(spo_t, spo_u)
% Heuristic: if robust range looks like meters (e.g., 0–3), multiply by 100 to cm.
rngv = prctile(spo_u,95) - prctile(spo_u,5);
if isfinite(rngv) && rngv > 0 && rngv < 5
    spo_u = spo_u * 100;
    fprintf('NOTE: Position appears in meters. Rescaled to centimeters (x100).\n');
end
end

function [spd_t, spd_u, spd_tid] = reconstruct_speed_with_ids(trials, trackDim)
% Speed along chosen axis (or derived from position if velocity missing)
if nargin<2 || isempty(trackDim), trackDim = 2; end
spd_t = []; spd_u = []; spd_tid = [];
for k=1:numel(trials)
    s = double(trials(k).start);
    % local timebase
    if isfield(trials(k),'time') && ~isempty(trials(k).time)
        tvec = double(trials(k).time(:));
    else
        if isfield(trials(k),'duration') && ~isempty(trials(k).duration)
            d = double(trials(k).duration);
        else, d = NaN; end
        if ~isfinite(d), continue; end
        n = size(trials(k).position,1);
        tvec = linspace(0,d,n)'; 
    end
    if isfield(trials(k),'velocity') && ~isempty(trials(k).velocity)
        V = double(trials(k).velocity);
        comp = min(trackDim, size(V,2));
        vraw = V(:,comp);
        if numel(vraw) ~= numel(tvec)
            vraw = interp1(linspace(tvec(1),tvec(end),numel(vraw)), vraw, tvec, 'linear', 'extrap');
        end
        tloc = tvec + s;
    elseif isfield(trials(k),'position') && ~isempty(trials(k).position)
        P = double(trials(k).position(:,trackDim));
        if numel(P) ~= numel(tvec)
            P = interp1(linspace(tvec(1),tvec(end),numel(P)), P, tvec, 'linear', 'extrap');
        end
        dt = [NaN; diff(tvec)];
        vraw = [NaN; diff(P)]./dt;
        tloc = tvec + s;
    else
        continue;
    end
    spd_t   = [spd_t;   tloc(:)];
    spd_u   = [spd_u;   vraw(:)];
    spd_tid = [spd_tid; repmat(k, numel(tloc),1)];
end
end

function edges = ensure_edges_cover_data(vals, edges, label)
% If <10% of samples fall inside edges, expand to [1..99]% data range.
vals = vals(isfinite(vals));
if isempty(vals), return; end
bin = discretize(vals, edges);
coverage = mean(~isnan(bin));
if coverage < 0.10
    lo = prctile(vals, 1);
    hi = prctile(vals, 99);
    if hi <= lo, hi = lo + 1; end
    edges = linspace(lo, hi, max(numel(edges), 6));
    fprintf('NOTE: Adjusted %s edges to cover data: [%.2f .. %.2f]\n', label, lo, hi);
end
end

function [means, sems, ns] = binned_means_over_signal(A, behav_t, sample_t, feature_vals, edges, sample_mask)
% Mean ± SEM per bin of feature_vals (true edges).
% Interpolates each neuron trace A{c}(behav_t) onto sample_t (within range).
edges = edges(:)'; assert(numel(edges)>=2,'edges must be true edges');
if nargin<6 || isempty(sample_mask), sample_mask = true(size(sample_t)); end
% in-range mask to avoid NaNs from extrapolation
inrange = sample_t>=behav_t(1) & sample_t<=behav_t(end);
valid   = sample_mask(:) & inrange(:) & isfinite(feature_vals(:));
tv      = sample_t(valid);
fv      = feature_vals(valid);
[~,~,binIdx] = histcounts(fv, edges);
nBins = numel(edges)-1;
N = numel(A);
means = nan(nBins,N); sems = nan(nBins,N); ns = nan(nBins,N);
if isempty(tv), return, end
% Precompute interpolated neural values at tv
Y = nan(numel(tv), N);
for c = 1:N
    Y(:,c) = interp1(behav_t, A{c}, tv, 'linear', NaN);
end
for b = 1:nBins
    inb = (binIdx == b);
    if any(inb)
        Yb = Y(inb,:);
        ns(b,:)    = sum(isfinite(Yb),1);
        means(b,:) = mean(Yb,1,'omitnan');
        sd         = std(Yb,0,1,'omitnan');
        sems(b,:)  = sd ./ sqrt(max(ns(b,:),1));
    end
end
end

function Act = align_events_all(A, behav_t, evt_times, t_axis)
nE = numel(evt_times); nB = numel(t_axis); N = numel(A);
Act = nan(nE,nB,N);
for i=1:nE
    if ~isfinite(evt_times(i)), continue; end
    tx = t_axis + evt_times(i);
    for c=1:N, Act(i,:,c) = interp1(behav_t, A{c}, tx, 'linear', NaN); end
end
end

function [m,se,n] = mean_sem(X)
if isempty(X) || all(isnan(X(:))), m = nan(1,size(X,2)); se = m; n = 0; return, end
valid_rows = any(isfinite(X),2); n = sum(valid_rows);
if n==0, m = nan(1,size(X,2)); se = m; return, end
m  = mean(X(valid_rows,:),1,'omitnan');
sd = std(X(valid_rows,:),0,1,'omitnan');
se = sd ./ sqrt(n);
end

function shaded_err(x,y,se,varargin)
x = x(:)'; y=y(:)'; se=se(:)';  % ensure shapes for fill
h = plot(x,y,'LineWidth',1.6,varargin{:}); hold on
col = get(h,'Color');
fill([x fliplr(x)], [y-se fliplr(y+se)], col, 'FaceAlpha',0.18,'EdgeColor','none');
end

function [left_onsets, right_onsets] = cue_onset_times(trials)
L = []; R = [];
for k=1:numel(trials)
    s = double(trials(k).start);
    if ~isfield(trials(k),'time') || isempty(trials(k).time), continue; end
    tvec = double(trials(k).time(:));
    if isfield(trials(k),'cueOnset') && ~isempty(trials(k).cueOnset)
        cc = trials(k).cueOnset;
        if iscell(cc)
            if numel(cc)>=1 && ~isempty(cc{1}), L = [L; s + tvec(cc{1}(:))]; end
            if numel(cc)>=2 && ~isempty(cc{2}), R = [R; s + tvec(cc{2}(:))]; end
        elseif isnumeric(cc) && size(cc,1)>=2
            li = cc(1, cc(1,:)~=0); ri = cc(2, cc(2,:)~=0);
            if ~isempty(li), L = [L; s + tvec(li(:))]; end
            if ~isempty(ri), R = [R; s + tvec(ri(:))]; end
        end
    end
end
left_onsets  = L(:)'; 
right_onsets = R(:)';
end
function save_neuron_panel(c, outdir, P)
    f = figure('Visible','off','Color','w','Renderer','opengl', ...
               'Units','pixels','Position',[100 100 1400 800]);
    tl = tiledlayout(f,2,3,'TileSpacing','compact','Padding','compact');
    cols2 = lines(2); col1 = lines(1); col1 = col1(1,:);

    % 1) Reward vs No-reward PSTH
    nexttile; hold on
    shaded_err(P.t_axis, P.r_m, P.r_se, 'Color', cols2(1,:));
    shaded_err(P.t_axis, P.n_m, P.n_se, 'Color', cols2(2,:));
    xline(0,'k-'); xlabel('Time (s)'); ylabel('\DeltaF/F');
    title(sprintf('Reward vs No-reward — n%03d', c));
    legend({'Reward','No-reward'},'Location','best'); box off

    % 2) Prev Success vs Failure (by Position)
    nexttile; hold on
    shaded_err(P.pos_centers, P.prevSucc_m, P.prevSucc_se, 'Color', cols2(1,:));
    shaded_err(P.pos_centers, P.prevFail_m, P.prevFail_se, 'Color', cols2(2,:));
    xlabel('Position (cm)'); ylabel('\DeltaF/F');
    xlim([min(P.pos_centers) max(P.pos_centers)]);
    title('Prev: Success vs Failure (pos)'); box off

    % 3) Current Success vs Not (by Position)
    nexttile; hold on
    shaded_err(P.pos_centers, P.currSucc_m, P.currSucc_se, 'Color', cols2(1,:));
    shaded_err(P.pos_centers, P.currNot_m,  P.currNot_se,  'Color', cols2(2,:));
    xlabel('Position (cm)'); ylabel('\DeltaF/F');
    xlim([min(P.pos_centers) max(P.pos_centers)]);
    title('Current: Success vs Not (pos)'); box off

    % 4) Position tuning (overall)
    nexttile; hold on
    shaded_err(P.pos_centers, P.posTune_m, P.posTune_se, 'Color', col1);
    xlabel('Position (cm)'); ylabel('\DeltaF/F');
    xlim([min(P.pos_centers) max(P.pos_centers)]);
    title('Position tuning'); box off

    % 5) Speed tuning (overall)
    nexttile; hold on
    shaded_err(P.spd_centers, P.spd_m, P.spd_se, 'Color', col1);
    xlabel('Speed (cm/s)'); ylabel('\DeltaF/F');
    xlim([min(P.spd_centers) max(P.spd_centers)]);
    title('Speed tuning'); box off

    % 6) Cue: Ipsi vs Contra (or placeholder)
    nexttile; hold on
    if isfield(P,'cue_t_axis') && ~isempty(P.cue_t_axis)
        shaded_err(P.cue_t_axis, P.cueI_m, P.cueI_se, 'Color', cols2(1,:));
        shaded_err(P.cue_t_axis, P.cueC_m, P.cueC_se, 'Color', cols2(2,:));
        xline(0,'k-'); xlabel('Time (s)'); ylabel('\DeltaF/F');
        title('Cue: Ipsi vs Contra'); legend({'Ipsi','Contra'},'Location','best'); box off
    else
        axis off
        text(0.5,0.5,'No cue events','HorizontalAlignment','center', ...
             'VerticalAlignment','middle','FontSize',12);
    end

    title(tl, sprintf('Neuron %03d — Session Panel', c));
    exportgraphics(f, fullfile(outdir, sprintf('n%03d_panel.png', c)), 'Resolution', 300);
    close(f);
end

