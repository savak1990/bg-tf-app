# Terragrunt configuration for EU-WEST-1 region
# Inherits from parent networking terragrunt.hcl

include "networking" {
  path = find_in_parent_folders("terragrunt.hcl")
}

# Region-specific overrides (if any)
# You can add region-specific configurations here