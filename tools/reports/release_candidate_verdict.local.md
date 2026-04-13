# Release Candidate Verdict

- GeneratedAtUtc: 2026-04-13T18:40:43.3184601Z
- GitRef: 
- GitSha: 
- Verdict: PASS
- ConfidenceScore: 100
- ConfidenceBand: very_high

## Gate Summary

| Gate | Pass | TotalRuns | PassedRuns | FailedRuns | Score | DriftScore | AvgVariability | MaxVariability | SourceReport |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| tier0 | True | 60 | 60 | 0 | 100 | 100 | 0 | 0 | tier0_burn_in_20260413_070720.json |
| tier1 | True | 50 | 50 | 0 | 100 | 100 | 0 | 0 | tier1_burn_in_20260413_073955.json |

## Top Drift Cases

### Tier 0
| Case | MinMs | AvgMs | MaxMs | Variability |
|---|---:|---:|---:|---:|
| PS-2 | 4600 | 4600 | 4600 | 0 |
| MC-2 | 7914 | 7914 | 7914 | 0 |
| MC-4 | 6488 | 6488 | 6488 | 0 |

### Tier 1
| Case | MinMs | AvgMs | MaxMs | Variability |
|---|---:|---:|---:|---:|
| NR-4 | 6249 | 6249 | 6249 | 0 |
| NR-1 | 6066 | 6066 | 6066 | 0 |
| NR-2 | 9971 | 9971 | 9971 | 0 |

## Notes
- Decision policy: releaseCandidateVerdict must be PASS to release.
- Confidence policy: higher score indicates lower timing variance under burn-in.
- Model: rc_confidence_v1
