#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path

# Regions we care about
REGIONS = ["uksouth", "ukwest", "westeurope"]

# Your NOT allowed SKUs
DENY_SKUS = {
    # G / GS
    "Standard_G1",
    "Standard_G2",
    "Standard_G3",
    "Standard_G4",
    "Standard_G5",
    "Standard_GS1",
    "Standard_GS2",
    "Standard_GS3",
    "Standard_GS4",
    "Standard_GS4-4",
    "Standard_GS4-8",
    "Standard_GS5",
    "Standard_GS5-16",
    "Standard_GS5-8",

    # H / HB / HC / HX
    "Standard_HB120-16rs_v2",
    "Standard_HB120-16rs_v3",
    "Standard_HB120-32rs_v2",
    "Standard_HB120-32rs_v3",
    "Standard_HB120-64rs_v2",
    "Standard_HB120-64rs_v3",
    "Standard_HB120-96rs_v2",
    "Standard_HB120-96rs_v3",
    "Standard_HB120rs_v2",
    "Standard_HB120rs_v3",
    "Standard_HB176-144rs_v4",
    "Standard_HB176-24rs_v4",
    "Standard_HB176-48rs_v4",
    "Standard_HB176-96rs_v4",
    "Standard_HB176rs_v4",
    "Standard_HB60-15rs",
    "Standard_HB60-30rs",
    "Standard_HB60-45rs",
    "Standard_HB60rs",
    "Standard_HC44-16rs",
    "Standard_HC44-32rs",
    "Standard_HC44rs",
    "Standard_HX176-144rs",
    "Standard_HX176-24rs",
    "Standard_HX176-48rs",
    "Standard_HX176-96rs",
    "Standard_HX176rs",

    # L
    "Standard_L16as_v3",
    "Standard_L16s",
    "Standard_L16_v2",
    "Standard_L16_v3",
    "Standard_L32as_v3",
    "Standard_L32s",
    "Standard_L32s_v2",
    "Standard_L32s_v3",
    "Standard_L48as_v3",
    "Standard_L48s_v2",
    "Standard_L48s_v3",
    "Standard_L4s",
    "Standard_L64as_v3",
    "Standard_L64s_v2",
    "Standard_L64s_v3",
    "Standard_L80as_v3",
    "Standard_L80s_v2",
    "Standard_L80s_v3",
    "Standard_L8as_v3",
    "Standard_L8s",
    "Standard_L8s_v2",
    "Standard_L8s_v3",

    # N* (GPU)
    "Standard_NC12s_v3",
    "Standard_NC16ads_A10_v4",
    "Standard_NC16as_T4_v3",
    "Standard_NC24ads_A100_v4",
    "Standard_NC24rs_v3",
    "Standard_NC24s_v3",
    "Standard_NC32ads_A10_v4",
    "Standard_NC40ads_H100_v5",
    "Standard_NC48ads_A100_v4",
    "Standard_NC4as_T4_v3",
    "Standard_NC64as_T4_v3",
    "Standard_NC6s_v3",
    "Standard_NC80adis_H100_v5",
    "Standard_NC8ads_A10_v4",
    "Standard_NC8as_T4_v3",
    "Standard_NC96ads_A100_v4",
    "Standard_NCC40ads_H100_v5",
    "Standard_ND40rs_v2",
    "Standard_ND40s_v3",
    "Standard_ND96amsr_A100_v4",
    "Standard_ND96asr_v4",
    "Standard_ND96is_MI300X_v5",
    "Standard_ND96isr_H100_v5",
    "Standard_ND96isr_H200_v5",
    "Standard_ND96isr_M1300X_v5",
    "Standard_NG16ads_V620_v1",
    "Standard_NG32adms_V620_v1",
    "Standard_NG32ads_V620_v1",
    "Standard_NG8ads_V620_v1",
    "Standard_NP10s",
    "Standard_NP20s",
    "Standard_NP40s",
    "Standard_NV12ads_A10_v5",
    "Standard_NV12ads_V710_v5",
    "Standard_NV12s_v2",
    "Standard_NV12s_v3",
    "Standard_NV16as_v4",
    "Standard_NV18ads_A10_v5",
    "Standard_NV24ads_V710_v5",
    "Standard_NV24s_v2",
    "Standard_NV24s_v3",
    "Standard_NV28adms_V710_v5",
    "Standard_NV32as_v4",
    "Standard_NV36adms_A10_v5",
    "Standard_NV36ads_A10_v5",
    "Standard_NV48s_v3",
    "Standard_NV4ads_V710_v5",
    "Standard_NVas_v4",
    "Standard_NV6ads_A10_v5",
    "Standard_NV6s_v2",
    "Standard_NV72ads_A10_v5",
    "Standard_NV8ads_V710_v5",
    "Standard_NV8as_v4",

    # P
    "Standard_P86s",
}


def get_region_skus(region: str) -> set[str]:
    """
    Call `az vm list-sizes` for a region and return current deployable SKU names as a set.
    """
    print(f"Fetching SKUs for region: {region} ...")
    result = subprocess.run(
        [
            "az", "vm", "list-sizes",
            "--location", region,
            "--query", "[].name",
            "-o", "tsv",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    skus = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    print(f"  -> {len(skus)} SKUs found in {region}")
    return skus


def main():
    allowed_by_region = {}

    for region in REGIONS:
        all_skus = get_region_skus(region)
        allowed = sorted(s for s in all_skus if s not in DENY_SKUS)
        allowed_by_region[region] = allowed
        print(f"  -> {len(allowed)} allowed SKUs in {region} after deny-list")

    # Write JSON file with per-region allowed SKUs
    out_json = Path("all_skus_by_region.json")
    out_json.write_text(json.dumps(allowed_by_region, indent=2))
    print(f"\nWrote per-region allowed SKUs to {out_json}")

    # Also build a combined union list for HCL snippet
    union_allowed = sorted({sku for skus in allowed_by_region.values() for sku in skus})

    hcl_lines = []
    hcl_lines.append("            listOfAllowedSKUs = [")
    for sku in union_allowed:
        hcl_lines.append(f'              "{sku}",')
    hcl_lines.append("            ]")

    out_hcl = Path("allowed_skus_union.hcl")
    out_hcl.write_text("\n".join(hcl_lines))
    print(f"Wrote union HCL snippet to {out_hcl}\n")

    print("HCL snippet preview:\n")
    print("\n".join(hcl_lines[:15]))
    if len(hcl_lines) > 15:
        print("              ...")
        print("            ]")


if __name__ == "__main__":
    main()
