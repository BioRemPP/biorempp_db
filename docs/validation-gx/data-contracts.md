# Data Contracts

The validation module enforces explicit contracts on the BioRemPP CSV, the
analysis JSON artifacts, and the KEGG metadata.

## CSV Schema Contract

The current shipped contract expects `database/biorempp_database_v1.1.0.csv`
with this ordered column list:

1. `cpd`
2. `compoundclass`
3. `ko`
4. `ec`
5. `reaction`
6. `reaction_description`
7. `referenceAG`
8. `compoundname`
9. `genesymbol`
10. `genename`
11. `enzyme_activity`

### Critical checks

`database_critical` enforces:

- exact ordered column list
- row count >= 1
- composite uniqueness across the full configured column list
- non-null values for the core identifier and annotation columns:
  `cpd`, `compoundclass`, `ko`, `referenceAG`, `compoundname`,
  `genesymbol`, `genename`, `enzyme_activity`
- regex conformance for `cpd` (`^C\d{5}$`) and `ko` (`^K\d{5}$`)

`ec`, `reaction`, and `reaction_description` are part of the ordered schema,
but they are not globally non-null fields.

### Analysis consistency check

`analysis_json_critical` also verifies that:

- `basic_statistics.json` reports the expected column count
- `basic_statistics.json` lists the expected columns
- `reaction_description_consistent_with_reaction` is true

## Vocabulary Contract

`database_warning` enforces the configured closed vocabularies for:

- `referenceAG`
- `compoundclass`

Those value sets come from `database_contract` in `validation.yaml` and are
injected into the GX suite at runtime.

## Required Artifact Contract

The current run must provide:

- `database/biorempp_database_v1.1.0.csv`
- `analysis/basic_statistics.json`
- `analysis/compound_statistics.json`
- `analysis/ko_statistics.json`
- `analysis/enzyme_statistics.json`
- `analysis/gene_statistics.json`
- `analysis/crosstab_statistics.json`
- `analysis/database_metadata.json`
- `analysis/executive_summary.json`
- `analysis/complete_analysis.json`
- `metadata/kegg_release.json`

When `internal_consistency: false`, the validator still requires the current
CSV and current `metadata/kegg_release.json`, but it skips loading the current
analysis payloads.

When `regression_detection: true`, the validator also requires the baseline
analysis JSON files and baseline `metadata/kegg_release.json` under
`paths.regression_baseline_root`.

## KEGG Metadata Contract

`metadata_kegg_critical` validates the current `metadata/kegg_release.json`
with checks for:

- non-null `release_text`
- non-null `parsed_version`
- non-null `retrieved_at_utc`
- non-null `source_url`
- exact source URL `https://rest.kegg.jp/info/kegg`
- version format regex
- UTC timestamp regex
- non-empty `raw_response`

## Exact-Match Contract

The validator performs exact recomputation through `build_analysis_exact_df()`.
That exact contract covers:

- basic statistics
- compound summaries
- KO summaries
- enzyme summaries
- gene summaries
- cross-tab summaries
- executive summary
- KEGG metadata embedded in analysis output

This exact-match contract is reused in two modes:

- internal consistency against the current analysis JSON artifacts
- regression detection against the committed baseline snapshot

## Drift Contract

`database_warning` also applies bounded drift ranges from `drift_thresholds`:

| Metric | Shipped range |
|--------|---------------|
| `row_count` | `118000-130000` |
| `unique_compounds` | `360-410` |
| `unique_ko` | `1440-1650` |
| `unique_genesymbol` | `1410-1625` |
| `unique_genename` | `1320-1525` |
| `unique_enzyme_activity` | `185-230` |

These are warning-level ranges, not exact baselines.

## Updating the Contract

### Change a vocabulary

1. Update `database_contract.expected_reference_agencies` or
   `database_contract.expected_compound_classes` in `validation.yaml`.
2. Run validation via Docker:
   `docker compose -f biorempp_snakemake_version/env/docker-compose.yml run --rm validation`

### Change the CSV schema

1. Update `database_contract.expected_columns` in `validation.yaml`.
2. Review the expectation templates if a new critical field needs its own
   explicit null or regex check.
3. Run the test suite in Docker.

### Recalibrate drift thresholds

1. Update `drift_thresholds` in `validation.yaml`.
2. Keep the ranges close to the blessed release scale, but not exact.
3. Re-run the tests and validation in Docker.
