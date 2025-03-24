# Google Service Account Module

This module allows simplified creation and management of one a service account and its IAM bindings.

A key can optionally be generated and will be stored in Terraform state. To use it create a sensitive output in your root modules referencing the `key` output, then extract the private key from the JSON formatted outputs.

Alternatively, the `key` can be generated with `openssl` library and only the public part uploaded to the Service Account, for more refer to the [Onprem SA Key Management](../../blueprints/cloud-operations/onprem-sa-key-management/) example.

Note that outputs have no dependencies on IAM bindings to prevent resource cycles.

## Example

```hcl
module "myproject-default-service-accounts" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "vm-default"
  # authoritative roles granted *on* the service accounts to other identities
  iam = {
    "roles/iam.serviceAccountUser" = ["group:${var.group_email}"]
  }
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
# tftest modules=1 resources=4 inventory=basic.yaml e2e
```
<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [iam.tf](./iam.tf) | IAM bindings. | <code>google_billing_account_iam_member</code> · <code>google_folder_iam_member</code> · <code>google_organization_iam_member</code> · <code>google_project_iam_member</code> · <code>google_service_account_iam_binding</code> · <code>google_service_account_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_service_account</code> · <code>google_service_account_key</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L114) | Name of the service account to create. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L129) | Project id where service account will be created. | <code>string</code> | ✓ |  |
| [description](variables.tf#L17) | Optional description. | <code>string</code> |  | <code>null</code> |
| [display_name](variables.tf#L23) | Display name of the service account to create. | <code>string</code> |  | <code>&#34;Terraform-managed.&#34;</code> |
| [generate_key](variables.tf#L29) | Generate a key for service account. | <code>bool</code> |  | <code>false</code> |
| [iam](variables.tf#L35) | IAM bindings on the service account in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_billing_roles](variables.tf#L42) | Billing account roles granted to this service account, by billing account id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L49) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L64) | Individual additive IAM bindings on the service account. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_folder_roles](variables.tf#L79) | Folder roles granted to this service account, by folder id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_organization_roles](variables.tf#L86) | Organization roles granted to this service account, by organization id. Non-authoritative. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_project_roles](variables.tf#L93) | Project roles granted to this service account, by project id. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_sa_roles](variables.tf#L100) | Service account roles granted to this service account, by service account name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_storage_roles](variables.tf#L107) | Storage roles granted to this service account, by bucket name. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L119) | Prefix applied to service account names. | <code>string</code> |  | <code>null</code> |
| [public_keys_directory](variables.tf#L134) | Path to public keys data files to upload to the service account (should have `.pem` extension). | <code>string</code> |  | <code>&#34;&#34;</code> |
| [service_account_create](variables.tf#L140) | Create service account. When set to false, uses a data source to reference an existing service account. | <code>bool</code> |  | <code>true</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [email](outputs.tf#L17) | Service account email. |  |
| [iam_email](outputs.tf#L25) | IAM-format service account email. |  |
| [id](outputs.tf#L33) | Fully qualified service account id. |  |
| [key](outputs.tf#L42) | Service account key. | ✓ |
| [name](outputs.tf#L48) | Service account name. |  |
| [service_account](outputs.tf#L57) | Service account resource. |  |
| [service_account_credentials](outputs.tf#L62) | Service account json credential templates for uploaded public keys data. |  |
<!-- END TFDOC -->

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | Optional description. | `string` | `null` | no |
| display\_name | Display name of the service account to create. | `string` | `"Terraform-managed."` | no |
| generate\_key | Generate a key for service account. | `bool` | `false` | no |
| iam | IAM bindings on the service account in {ROLE => [MEMBERS]} format. | `map(list(string))` | `{}` | no |
| iam\_billing\_roles | Billing account roles granted to this service account, by billing account id. Non-authoritative. | `map(list(string))` | `{}` | no |
| iam\_bindings | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <pre>map(object({<br>    members = list(string)<br>    role    = string<br>    condition = optional(object({<br>      expression  = string<br>      title       = string<br>      description = optional(string)<br>    }))<br>  }))</pre> | `{}` | no |
| iam\_bindings\_additive | Individual additive IAM bindings on the service account. Keys are arbitrary. | <pre>map(object({<br>    member = string<br>    role   = string<br>    condition = optional(object({<br>      expression  = string<br>      title       = string<br>      description = optional(string)<br>    }))<br>  }))</pre> | `{}` | no |
| iam\_folder\_roles | Folder roles granted to this service account, by folder id. Non-authoritative. | `map(list(string))` | `{}` | no |
| iam\_organization\_roles | Organization roles granted to this service account, by organization id. Non-authoritative. | `map(list(string))` | `{}` | no |
| iam\_project\_roles | Project roles granted to this service account, by project id. | `map(list(string))` | `{}` | no |
| iam\_sa\_roles | Service account roles granted to this service account, by service account name. | `map(list(string))` | `{}` | no |
| iam\_storage\_roles | Storage roles granted to this service account, by bucket name. | `map(list(string))` | `{}` | no |
| name | Name of the service account to create. | `string` | n/a | yes |
| prefix | Prefix applied to service account names. | `string` | `null` | no |
| project\_id | Project id where service account will be created. | `string` | n/a | yes |
| public\_keys\_directory | Path to public keys data files to upload to the service account (should have `.pem` extension). | `string` | `""` | no |
| service\_account\_create | Create service account. When set to false, uses a data source to reference an existing service account. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| email | Service account email. |
| iam\_email | IAM-format service account email. |
| id | Fully qualified service account id. |
| key | Service account key. |
| name | Service account name. |
| service\_account | Service account resource. |
| service\_account\_credentials | Service account json credential templates for uploaded public keys data. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->