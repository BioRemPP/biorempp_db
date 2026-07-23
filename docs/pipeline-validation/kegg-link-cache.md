<!--
Page status: verified
Audience: operators, maintainers, reviewers
Applies to: Snakemake
Version scope: Snakemake output contract v1.1.0
Last verified on: 2026-06-24
Primary sources:
- biorempp_snakemake_version/workflow/rules/30_validation.smk
- biorempp_snakemake_version/workflow/scripts/validation/cache_kegg_links.py
- biorempp_snakemake_version/workflow/scripts/validation/kegg_api_client.py
- biorempp_snakemake_version/config/config.yaml
Observed artifacts:
- biorempp_snakemake_version/cache/kegg_link_cache/ko_ec.tsv
- biorempp_snakemake_version/cache/kegg_link_cache/ko_reaction.tsv
- biorempp_snakemake_version/cache/kegg_link_cache/cpd_ec.tsv
- biorempp_snakemake_version/cache/kegg_link_cache/cpd_reaction.tsv
- biorempp_snakemake_version/cache/kegg_link_cache/ec_reaction.tsv
-->

# KEGG Link Cache

`fetch_kegg_link_cache` creates the local KEGG cache reused by both pipeline validation reports. The cache is stored under `biorempp_snakemake_version/cache/kegg_link_cache/`.

## Cache Files

The rule produces exactly five TSV files:

- `cache/kegg_link_cache/ko_ec.tsv`
- `cache/kegg_link_cache/ko_reaction.tsv`
- `cache/kegg_link_cache/cpd_ec.tsv`
- `cache/kegg_link_cache/cpd_reaction.tsv`
- `cache/kegg_link_cache/ec_reaction.tsv`

Each file is a raw KEGG link payload saved to disk for later reuse by the report scripts.

## Endpoint Mapping

`30_validation.smk` maps config keys to cache files as follows:

| Config key | Endpoint | Cache file |
|---|---|---|
| `kegg.endpoints.ko_ec_links` | `link/ko/ec` | `cache/kegg_link_cache/ko_ec.tsv` |
| `kegg.endpoints.ko_reaction_links` | `link/ko/reaction` | `cache/kegg_link_cache/ko_reaction.tsv` |
| `kegg.endpoints.compound_ec_links` | `link/compound/ec` | `cache/kegg_link_cache/cpd_ec.tsv` |
| `kegg.endpoints.compound_reaction_links` | `link/compound/reaction` | `cache/kegg_link_cache/cpd_reaction.tsv` |
| `kegg.endpoints.ec_reaction_links` | `link/enzyme/reaction` | `cache/kegg_link_cache/ec_reaction.tsv` |

## Acquisition Behavior

`workflow/scripts/validation/cache_kegg_links.py` does not normalize or reinterpret the payloads. It:

- fetches each endpoint with `fetch_text()` from `kegg_api_client.py`
- writes the returned text directly to the matching `.tsv` file
- prints simple progress messages to the rule log

The retry and timeout behavior comes from `kegg_api_client.py` and can be influenced by these environment variables:

- `BIOREMPP_API_MAX_RETRIES`
- `BIOREMPP_API_TIMEOUT_SECONDS`
- `BIOREMPP_API_BACKOFF_BASE_SECONDS`
- `BIOREMPP_API_BACKOFF_MAX_SECONDS`
- `BIOREMPP_API_BACKOFF_JITTER_RATIO`

## Why Orientation Is Deferred

The cached files preserve the raw KEGG orientation. For example, the observed `ko_ec.tsv` begins with lines like:

```text
ec:1.1.1.1	ko:K00001
ec:1.1.1.2	ko:K00002
```

The downstream parser in `kegg_api_client.py` detects whether a line matches the expected left-right orientation directly or in swapped form. That is why the validation reports expose `swapped_orientation_lines` in `api_parse_stats`.

## Role In Downstream Validation

Both report scripts read these cache files through `read_link_cache()` and then pass the payloads into `parse_link_payload()`. The cache therefore separates:

- network acquisition
- payload parsing and normalization
- report generation

This keeps the report rules deterministic with respect to the cached input files they read.

## Related Pages

- [Overview](overview.md)
- [Keys Consistency Report](keys-consistency.md)
- [Links Groundtruth Policy Report](links-groundtruth-policy.md)
