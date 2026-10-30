// CI/CD status of a project's GitHub repo, fetched once at build time
// (DECISIONS.md #28). Visitors never contact GitHub: the result is baked into
// the static page. Never throws: anything that goes wrong is 'unknown'.

export type CiState = 'passing' | 'failing' | 'running' | 'unknown';
export type DeployState = 'live' | 'failed' | 'deploying' | 'unknown';

export interface CiStatus {
	repoUrl: string;
	// Absent when the repo has no check runs / no Production deployments.
	ci?: CiState;
	deploy?: DeployState;
	asOf: Date;
}

const API = 'https://api.github.com';
const BUILT_AT = new Date();
const cache = new Map<string, Promise<CiStatus>>();

async function gh(path: string): Promise<any> {
	const headers: Record<string, string> = {
		Accept: 'application/vnd.github+json',
		'X-GitHub-Api-Version': '2022-11-28',
	};
	if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
	const res = await fetch(`${API}${path}`, { headers, signal: AbortSignal.timeout(5000) });
	if (!res.ok) throw new Error(`GitHub ${res.status} for ${path}`);
	return res.json();
}

const FAILED = new Set(['failure', 'timed_out', 'cancelled', 'action_required', 'startup_failure']);

/**
 * Combine the check runs on a commit into one state
 */
export function ciStateOf(runs: Array<{ status: string; conclusion: string | null }>): CiState | undefined {
	if (runs.length === 0) return undefined;
	if (runs.some(r => r.conclusion && FAILED.has(r.conclusion))) return 'failing';
	if (runs.some(r => r.status !== 'completed')) return 'running';
	return runs.some(r => r.conclusion === 'success') ? 'passing' : undefined;
}

/**
 * Map a GitHub deployment status to what the card shows
 */
export function deployStateOf(state: string | undefined): DeployState {
	if (state === 'success') return 'live';
	if (state === 'failure' || state === 'error') return 'failed';
	if (state === 'pending' || state === 'queued' || state === 'in_progress') return 'deploying';
	return 'unknown';
}

async function fetchStatus(repoUrl: string, owner: string, repo: string): Promise<CiStatus> {
	const status: CiStatus = { repoUrl, asOf: BUILT_AT };
	if (process.env.CI_STATUS === 'off') return { ...status, ci: 'unknown' };

	try {
		const { default_branch } = await gh(`/repos/${owner}/${repo}`);
		const { check_runs } = await gh(`/repos/${owner}/${repo}/commits/${default_branch}/check-runs?per_page=100`);
		status.ci = ciStateOf(check_runs);
	} catch (e) {
		console.warn(`[ci-status] ${owner}/${repo}: ${(e as Error).message}`);
		return { ...status, ci: 'unknown' };
	}

	try {
		const [latest] = await gh(`/repos/${owner}/${repo}/deployments?environment=Production&per_page=1`);
		if (latest) {
			const [newest] = await gh(`/repos/${owner}/${repo}/deployments/${latest.id}/statuses?per_page=1`);
			status.deploy = deployStateOf(newest?.state);
		}
	} catch (e) {
		console.warn(`[ci-status] ${owner}/${repo} deployments: ${(e as Error).message}`);
		status.deploy = 'unknown';
	}
	return status;
}

/**
 * CI/CD status for a github.com repo URL; null for anything else
 */
export function getCiStatus(githubUrl: string): Promise<CiStatus> | null {
	const m = githubUrl.match(/^https:\/\/github\.com\/([\w.-]+)\/([\w.-]+?)(?:\.git)?\/?$/);
	if (!m) return null;
	const key = `${m[1]}/${m[2]}`;
	if (!cache.has(key)) cache.set(key, fetchStatus(`https://github.com/${key}`, m[1], m[2]));
	return cache.get(key)!;
}
