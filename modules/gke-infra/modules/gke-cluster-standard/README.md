# GKE Standard cluster module

This module offers a way to create and manage Google Kubernetes Engine (GKE) [Standard clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode#why-standard). With its sensible default settings based on best practices and authors' experience as Google Cloud practitioners, the module accommodates for many common use cases out-of-the-box, without having to rely on verbose configuration.

> [!IMPORTANT]
> This module should be used together with the [`gke-nodepool`](../gke-nodepool/) module because the default node pool is deleted upon cluster creation and cannot be re-created.

<!-- BEGIN TOC -->
- [Example](#example)
  - [GKE Standard cluster](#gke-standard-cluster)
  - [Enable Dataplane V2](#enable-dataplane-v2)
  - [Managing GKE logs](#managing-gke-logs)
  - [Monitoring configuration](#monitoring-configuration)
  - [Disable GKE logs or metrics collection](#disable-gke-logs-or-metrics-collection)
  - [Cloud DNS](#cloud-dns)
  - [Backup for GKE](#backup-for-gke)
  - [Automatic creation of new secondary ranges](#automatic-creation-of-new-secondary-ranges)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Example

### GKE Standard cluster

This example shows how to [create a zonal GKE cluster in Standard mode](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster).

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
    master_authorized_ranges = {
      internal-vms = "10.0.0.0/8"
    }
    master_ipv4_cidr_block = "192.168.0.0/28"
  }
  max_pods_per_node = 32
  private_cluster_config = {
    enable_private_endpoint = true
    master_global_access    = false
  }
  labels = {
    environment = "dev"
  }
}
# tftest modules=1 resources=1 inventory=basic.yaml
```

### Enable Dataplane V2

This example shows how to [create a zonal GKE Cluster with Dataplane V2 enabled](https://cloud.google.com/kubernetes-engine/docs/how-to/dataplane-v2).

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = "myproject"
  name       = "cluster-dataplane-v2"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
    master_authorized_ranges = {
      internal-vms = "10.0.0.0/8"
    }
    master_ipv4_cidr_block = "192.168.0.0/28"
  }
  private_cluster_config = {
    enable_private_endpoint = true
    master_global_access    = false
  }
  enable_features = {
    dataplane_v2        = true
    fqdn_network_policy = true
    workload_identity   = true
  }
  labels = {
    environment = "dev"
  }
}
# tftest modules=1 resources=1 inventory=dataplane-v2.yaml
```

### Managing GKE logs

This example shows you how to [control which logs are sent from your GKE cluster to Cloud Logging](https://cloud.google.com/stackdriver/docs/solutions/gke/installing). 

When you create a new GKE cluster, [Cloud Operations for GKE](https://cloud.google.com/stackdriver/docs/solutions/gke) integration with Cloud Logging is enabled by default and [System logs](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-logs#what_logs) are collected. You can enable collection of several other [types of logs](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-logs#what_logs). The following example enables collection of *all* optional logs.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {}
  }
  logging_config = {
    enable_workloads_logs          = true
    enable_api_server_logs         = true
    enable_scheduler_logs          = true
    enable_controller_manager_logs = true
  }
}
# tftest modules=1 resources=1 inventory=logging-config-enable-all.yaml
```

### Monitoring configuration

This example shows how to [configure collection of Kubernetes control plane metrics](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-metrics#enable-control-plane-metrics). These metrics are optional and are not collected by default.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
  }
  monitoring_config = {
    enable_api_server_metrics         = true
    enable_controller_manager_metrics = true
    enable_scheduler_metrics          = true
  }
}
# tftest modules=1 resources=1 inventory=monitoring-config-control-plane.yaml
```

The next example shows how to [configure collection of kube state metrics](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-metrics#enable-ksm). These metrics are optional and are not collected by default.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {} # use default names "pods" and "services"
  }
  monitoring_config = {
    enable_daemonset_metrics   = true
    enable_deployment_metrics  = true
    enable_hpa_metrics         = true
    enable_pod_metrics         = true
    enable_statefulset_metrics = true
    enable_storage_metrics     = true
    # Kube state metrics collection requires Google Cloud Managed Service for Prometheus,
    # which is enabled by default.
    # enable_managed_prometheus = true  
  }
}
# tftest modules=1 resources=1 inventory=monitoring-config-kube-state.yaml
```

The *control plane metrics* and *kube state metrics* collection can be configured in a single `monitoring_config` block.

### Disable GKE logs or metrics collection

> [!WARNING]
> If you've disabled Cloud Logging or Cloud Monitoring, GKE customer support
> is offered on a best-effort basis and might require additional effort
> from your engineering team.

This example shows how to fully disable logs collection on a zonal GKE Standard cluster. This is not recommended.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {}
  }
  logging_config = {
    enable_system_logs = false
  }
}
# tftest modules=1 resources=1 inventory=logging-config-disable-all.yaml
```

The next example shows how to fully disable metrics collection on a zonal GKE Standard cluster. This is not recommended.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = "myproject"
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {}
  }
  monitoring_config = {
    enable_system_metrics     = false
    enable_managed_prometheus = false
  }
}
# tftest modules=1 resources=1 inventory=monitoring-config-disable-all.yaml
```

### Cloud DNS

This example shows how to [use Cloud DNS as a Kubernetes DNS provider](https://cloud.google.com/kubernetes-engine/docs/how-to/cloud-dns) for GKE Standard clusters.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {}
  }
  enable_features = {
    dns = {
      provider = "CLOUD_DNS"
      scope    = "CLUSTER_SCOPE"
      domain   = "gke.local"
    }
  }
}
# tftest modules=1 resources=1 inventory=dns.yaml
```

### Backup for GKE

> [!NOTE]
> Although Backup for GKE can be enabled as an add-on when configuring your GKE clusters, it is a separate service from GKE.

[Backup for GKE](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/backup-for-gke) is a service for backing up and restoring workloads in GKE clusters. It has two components:

* A [Google Cloud API](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/reference/rest) that serves as the control plane for the service.
* A GKE add-on (the [Backup for GKE agent](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/concepts/backup-for-gke#agent_overview)) that must be enabled in each cluster for which you wish to perform backup and restore operations.

This example shows how to [enable Backup for GKE on a new zonal GKE Standard cluster](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/how-to/install#enable_on_a_new_cluster_optional) and [plan a set of backups](https://cloud.google.com/kubernetes-engine/docs/add-on/backup-for-gke/how-to/backup-plan).

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network               = var.vpc.self_link
    subnetwork            = var.subnet.self_link
    secondary_range_names = {}
  }
  backup_configs = {
    enable_backup_agent = true
    backup_plans = {
      "backup-1" = {
        region   = "europe-west2"
        schedule = "0 9 * * 1"
        applications = {
          namespace-1 = ["app-1", "app-2"]
        }
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=backup.yaml
```

### Automatic creation of new secondary ranges

You can use `var.vpc_config.secondary_range_blocks` to let GKE create new secondary ranges for the cluster. The example below reserves an available /14 block for pods and a /20 for services.

```hcl
module "cluster-1" {
  source     = "./fabric/modules/gke-cluster-standard"
  project_id = var.project_id
  name       = "cluster-1"
  location   = "europe-west1-b"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    secondary_range_blocks = {
      pods     = ""
      services = "/20" # can be an empty string as well
    }
  }
}
# tftest modules=1 resources=1
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [location](variables.tf#L214) | Cluster zone or region. | <code>string</code> | ✓ |  |
| [name](variables.tf#L325) | Cluster name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L361) | Cluster project id. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L372) | VPC-level configuration. | <code title="object&#40;&#123;&#10;  network                &#61; string&#10;  subnetwork             &#61; string&#10;  master_ipv4_cidr_block &#61; optional&#40;string&#41;&#10;  secondary_range_blocks &#61; optional&#40;object&#40;&#123;&#10;    pods     &#61; string&#10;    services &#61; string&#10;  &#125;&#41;&#41;&#10;  secondary_range_names &#61; optional&#40;object&#40;&#123;&#10;    pods     &#61; optional&#40;string, &#34;pods&#34;&#41;&#10;    services &#61; optional&#40;string, &#34;services&#34;&#41;&#10;  &#125;&#41;&#41;&#10;  master_authorized_ranges &#61; optional&#40;map&#40;string&#41;&#41;&#10;  stack_type               &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [backup_configs](variables.tf#L17) | Configuration for Backup for GKE. | <code title="object&#40;&#123;&#10;  enable_backup_agent &#61; optional&#40;bool, false&#41;&#10;  backup_plans &#61; optional&#40;map&#40;object&#40;&#123;&#10;    region                            &#61; string&#10;    applications                      &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;    encryption_key                    &#61; optional&#40;string&#41;&#10;    include_secrets                   &#61; optional&#40;bool, true&#41;&#10;    include_volume_data               &#61; optional&#40;bool, true&#41;&#10;    namespaces                        &#61; optional&#40;list&#40;string&#41;&#41;&#10;    schedule                          &#61; optional&#40;string&#41;&#10;    retention_policy_days             &#61; optional&#40;number&#41;&#10;    retention_policy_lock             &#61; optional&#40;bool, false&#41;&#10;    retention_policy_delete_lock_days &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [cluster_autoscaling](variables.tf#L38) | Enable and configure limits for Node Auto-Provisioning with Cluster Autoscaler. | <code title="object&#40;&#123;&#10;  autoscaling_profile &#61; optional&#40;string, &#34;BALANCED&#34;&#41;&#10;  auto_provisioning_defaults &#61; optional&#40;object&#40;&#123;&#10;    boot_disk_kms_key &#61; optional&#40;string&#41;&#10;    disk_size         &#61; optional&#40;number&#41;&#10;    disk_type         &#61; optional&#40;string, &#34;pd-standard&#34;&#41;&#10;    image_type        &#61; optional&#40;string&#41;&#10;    oauth_scopes      &#61; optional&#40;list&#40;string&#41;&#41;&#10;    service_account   &#61; optional&#40;string&#41;&#10;    management &#61; optional&#40;object&#40;&#123;&#10;      auto_repair  &#61; optional&#40;bool, true&#41;&#10;      auto_upgrade &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#10;    shielded_instance_config &#61; optional&#40;object&#40;&#123;&#10;      integrity_monitoring &#61; optional&#40;bool, true&#41;&#10;      secure_boot          &#61; optional&#40;bool, false&#41;&#10;    &#125;&#41;&#41;&#10;    upgrade_settings &#61; optional&#40;object&#40;&#123;&#10;      blue_green &#61; optional&#40;object&#40;&#123;&#10;        node_pool_soak_duration &#61; optional&#40;string&#41;&#10;        standard_rollout_policy &#61; optional&#40;object&#40;&#123;&#10;          batch_percentage    &#61; optional&#40;number&#41;&#10;          batch_node_count    &#61; optional&#40;number&#41;&#10;          batch_soak_duration &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      surge &#61; optional&#40;object&#40;&#123;&#10;        max         &#61; optional&#40;number&#41;&#10;        unavailable &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  cpu_limits &#61; optional&#40;object&#40;&#123;&#10;    min &#61; number&#10;    max &#61; number&#10;  &#125;&#41;&#41;&#10;  mem_limits &#61; optional&#40;object&#40;&#123;&#10;    min &#61; number&#10;    max &#61; number&#10;  &#125;&#41;&#41;&#10;  gpu_resources &#61; optional&#40;list&#40;object&#40;&#123;&#10;    resource_type &#61; string&#10;    min           &#61; number&#10;    max           &#61; number&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [deletion_protection](variables.tf#L116) | Whether or not to allow Terraform to destroy the cluster. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply that would delete the cluster will fail. | <code>bool</code> |  | <code>true</code> |
| [description](variables.tf#L123) | Cluster description. | <code>string</code> |  | <code>null</code> |
| [enable_addons](variables.tf#L129) | Addons enabled in the cluster (true means enabled). | <code title="object&#40;&#123;&#10;  cloudrun                       &#61; optional&#40;bool, false&#41;&#10;  config_connector               &#61; optional&#40;bool, false&#41;&#10;  dns_cache                      &#61; optional&#40;bool, false&#41;&#10;  gce_persistent_disk_csi_driver &#61; optional&#40;bool, false&#41;&#10;  gcp_filestore_csi_driver       &#61; optional&#40;bool, false&#41;&#10;  gcs_fuse_csi_driver            &#61; optional&#40;bool, false&#41;&#10;  horizontal_pod_autoscaling     &#61; optional&#40;bool, false&#41;&#10;  http_load_balancing            &#61; optional&#40;bool, false&#41;&#10;  istio &#61; optional&#40;object&#40;&#123;&#10;    enable_tls &#61; bool&#10;  &#125;&#41;&#41;&#10;  kalm           &#61; optional&#40;bool, false&#41;&#10;  network_policy &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  horizontal_pod_autoscaling &#61; true&#10;  http_load_balancing        &#61; true&#10;&#125;">&#123;&#8230;&#125;</code> |
| [enable_features](variables.tf#L153) | Enable cluster-level features. Certain features allow configuration. | <code title="object&#40;&#123;&#10;  beta_apis            &#61; optional&#40;list&#40;string&#41;&#41;&#10;  binary_authorization &#61; optional&#40;bool, false&#41;&#10;  cost_management      &#61; optional&#40;bool, false&#41;&#10;  dns &#61; optional&#40;object&#40;&#123;&#10;    provider &#61; optional&#40;string&#41;&#10;    scope    &#61; optional&#40;string&#41;&#10;    domain   &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  database_encryption &#61; optional&#40;object&#40;&#123;&#10;    state    &#61; string&#10;    key_name &#61; string&#10;  &#125;&#41;&#41;&#10;  dataplane_v2         &#61; optional&#40;bool, false&#41;&#10;  fqdn_network_policy  &#61; optional&#40;bool, false&#41;&#10;  gateway_api          &#61; optional&#40;bool, false&#41;&#10;  groups_for_rbac      &#61; optional&#40;string&#41;&#10;  image_streaming      &#61; optional&#40;bool, false&#41;&#10;  intranode_visibility &#61; optional&#40;bool, false&#41;&#10;  l4_ilb_subsetting    &#61; optional&#40;bool, false&#41;&#10;  mesh_certificates    &#61; optional&#40;bool&#41;&#10;  pod_security_policy  &#61; optional&#40;bool, false&#41;&#10;  resource_usage_export &#61; optional&#40;object&#40;&#123;&#10;    dataset                              &#61; string&#10;    enable_network_egress_metering       &#61; optional&#40;bool&#41;&#10;    enable_resource_consumption_metering &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  service_external_ips &#61; optional&#40;bool, true&#41;&#10;  shielded_nodes       &#61; optional&#40;bool, false&#41;&#10;  tpu                  &#61; optional&#40;bool, false&#41;&#10;  upgrade_notifications &#61; optional&#40;object&#40;&#123;&#10;    topic_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  vertical_pod_autoscaling &#61; optional&#40;bool, false&#41;&#10;  workload_identity        &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  workload_identity &#61; true&#10;&#125;">&#123;&#8230;&#125;</code> |
| [issue_client_certificate](variables.tf#L202) | Enable issuing client certificate. | <code>bool</code> |  | <code>false</code> |
| [labels](variables.tf#L208) | Cluster resource labels. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [logging_config](variables.tf#L219) | Logging configuration. | <code title="object&#40;&#123;&#10;  enable_system_logs             &#61; optional&#40;bool, true&#41;&#10;  enable_workloads_logs          &#61; optional&#40;bool, false&#41;&#10;  enable_api_server_logs         &#61; optional&#40;bool, false&#41;&#10;  enable_scheduler_logs          &#61; optional&#40;bool, false&#41;&#10;  enable_controller_manager_logs &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [maintenance_config](variables.tf#L240) | Maintenance window configuration. | <code title="object&#40;&#123;&#10;  daily_window_start_time &#61; optional&#40;string&#41;&#10;  recurring_window &#61; optional&#40;object&#40;&#123;&#10;    start_time &#61; string&#10;    end_time   &#61; string&#10;    recurrence &#61; string&#10;  &#125;&#41;&#41;&#10;  maintenance_exclusions &#61; optional&#40;list&#40;object&#40;&#123;&#10;    name       &#61; string&#10;    start_time &#61; string&#10;    end_time   &#61; string&#10;    scope      &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  daily_window_start_time &#61; &#34;03:00&#34;&#10;  recurring_window        &#61; null&#10;  maintenance_exclusion   &#61; &#91;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [max_pods_per_node](variables.tf#L263) | Maximum number of pods per node in this cluster. | <code>number</code> |  | <code>110</code> |
| [min_master_version](variables.tf#L269) | Minimum version of the master, defaults to the version of the most recent official release. | <code>string</code> |  | <code>null</code> |
| [monitoring_config](variables.tf#L275) | Monitoring configuration. Google Cloud Managed Service for Prometheus is enabled by default. | <code title="object&#40;&#123;&#10;  enable_system_metrics &#61; optional&#40;bool, true&#41;&#10;  enable_api_server_metrics         &#61; optional&#40;bool, false&#41;&#10;  enable_controller_manager_metrics &#61; optional&#40;bool, false&#41;&#10;  enable_scheduler_metrics          &#61; optional&#40;bool, false&#41;&#10;  enable_daemonset_metrics   &#61; optional&#40;bool, false&#41;&#10;  enable_deployment_metrics  &#61; optional&#40;bool, false&#41;&#10;  enable_hpa_metrics         &#61; optional&#40;bool, false&#41;&#10;  enable_pod_metrics         &#61; optional&#40;bool, false&#41;&#10;  enable_statefulset_metrics &#61; optional&#40;bool, false&#41;&#10;  enable_storage_metrics     &#61; optional&#40;bool, false&#41;&#10;  enable_managed_prometheus &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [node_config](variables.tf#L330) | Node-level configuration. | <code title="object&#40;&#123;&#10;  boot_disk_kms_key &#61; optional&#40;string&#41;&#10;  service_account   &#61; optional&#40;string&#41;&#10;  tags              &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [node_locations](variables.tf#L340) | Zones in which the cluster's nodes are located. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [private_cluster_config](variables.tf#L347) | Private cluster configuration. | <code title="object&#40;&#123;&#10;  enable_private_endpoint &#61; optional&#40;bool&#41;&#10;  master_global_access    &#61; optional&#40;bool&#41;&#10;  peering_config &#61; optional&#40;object&#40;&#123;&#10;    export_routes &#61; optional&#40;bool&#41;&#10;    import_routes &#61; optional&#40;bool&#41;&#10;    project_id    &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [release_channel](variables.tf#L366) | Release channel for GKE upgrades. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [ca_certificate](outputs.tf#L17) | Public certificate of the cluster (base64-encoded). | ✓ |
| [cluster](outputs.tf#L23) | Cluster resource. | ✓ |
| [endpoint](outputs.tf#L29) | Cluster endpoint. |  |
| [id](outputs.tf#L34) | FUlly qualified cluster id. |  |
| [location](outputs.tf#L39) | Cluster location. |  |
| [master_version](outputs.tf#L44) | Master version. |  |
| [name](outputs.tf#L49) | Cluster name. |  |
| [notifications](outputs.tf#L54) | GKE PubSub notifications topic. |  |
| [self_link](outputs.tf#L59) | Cluster self link. | ✓ |
| [workload_identity_pool](outputs.tf#L65) | Workload identity pool. |  |
<!-- END TFDOC -->

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| backup\_configs | Configuration for Backup for GKE. | <pre>object({<br>    enable_backup_agent = optional(bool, false)<br>    backup_plans = optional(map(object({<br>      region                            = string<br>      applications                      = optional(map(list(string)))<br>      encryption_key                    = optional(string)<br>      include_secrets                   = optional(bool, true)<br>      include_volume_data               = optional(bool, true)<br>      namespaces                        = optional(list(string))<br>      schedule                          = optional(string)<br>      retention_policy_days             = optional(number)<br>      retention_policy_lock             = optional(bool, false)<br>      retention_policy_delete_lock_days = optional(number)<br>    })), {})<br>  })</pre> | `{}` | no |
| cluster\_autoscaling | Enable and configure limits for Node Auto-Provisioning with Cluster Autoscaler. | <pre>object({<br>    autoscaling_profile = optional(string, "BALANCED")<br>    auto_provisioning_defaults = optional(object({<br>      boot_disk_kms_key = optional(string)<br>      disk_size         = optional(number)<br>      disk_type         = optional(string, "pd-standard")<br>      image_type        = optional(string)<br>      oauth_scopes      = optional(list(string))<br>      service_account   = optional(string)<br>      management = optional(object({<br>        auto_repair  = optional(bool, true)<br>        auto_upgrade = optional(bool, true)<br>      }))<br>      shielded_instance_config = optional(object({<br>        integrity_monitoring = optional(bool, true)<br>        secure_boot          = optional(bool, false)<br>      }))<br>      upgrade_settings = optional(object({<br>        blue_green = optional(object({<br>          node_pool_soak_duration = optional(string)<br>          standard_rollout_policy = optional(object({<br>            batch_percentage    = optional(number)<br>            batch_node_count    = optional(number)<br>            batch_soak_duration = optional(string)<br>          }))<br>        }))<br>        surge = optional(object({<br>          max         = optional(number)<br>          unavailable = optional(number)<br>        }))<br>      }))<br>      # add validation rule to ensure only one is present if upgrade settings is defined<br>    }))<br>    cpu_limits = optional(object({<br>      min = number<br>      max = number<br>    }))<br>    mem_limits = optional(object({<br>      min = number<br>      max = number<br>    }))<br>    gpu_resources = optional(list(object({<br>      resource_type = string<br>      min           = number<br>      max           = number<br>    })))<br>  })</pre> | `null` | no |
| deletion\_protection | Whether or not to allow Terraform to destroy the cluster. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply that would delete the cluster will fail. | `bool` | `true` | no |
| description | Cluster description. | `string` | `null` | no |
| enable\_addons | Addons enabled in the cluster (true means enabled). | <pre>object({<br>    cloudrun                       = optional(bool, false)<br>    config_connector               = optional(bool, false)<br>    dns_cache                      = optional(bool, false)<br>    gce_persistent_disk_csi_driver = optional(bool, false)<br>    gcp_filestore_csi_driver       = optional(bool, false)<br>    gcs_fuse_csi_driver            = optional(bool, false)<br>    horizontal_pod_autoscaling     = optional(bool, false)<br>    http_load_balancing            = optional(bool, false)<br>    istio = optional(object({<br>      enable_tls = bool<br>    }))<br>    kalm           = optional(bool, false)<br>    network_policy = optional(bool, false)<br>  })</pre> | <pre>{<br>  "horizontal_pod_autoscaling": true,<br>  "http_load_balancing": true<br>}</pre> | no |
| enable\_features | Enable cluster-level features. Certain features allow configuration. | <pre>object({<br>    beta_apis            = optional(list(string))<br>    binary_authorization = optional(bool, false)<br>    cost_management      = optional(bool, false)<br>    dns = optional(object({<br>      provider = optional(string)<br>      scope    = optional(string)<br>      domain   = optional(string)<br>    }))<br>    database_encryption = optional(object({<br>      state    = string<br>      key_name = string<br>    }))<br>    dataplane_v2         = optional(bool, false)<br>    fqdn_network_policy  = optional(bool, false)<br>    gateway_api          = optional(bool, false)<br>    groups_for_rbac      = optional(string)<br>    image_streaming      = optional(bool, false)<br>    intranode_visibility = optional(bool, false)<br>    l4_ilb_subsetting    = optional(bool, false)<br>    mesh_certificates    = optional(bool)<br>    pod_security_policy  = optional(bool, false)<br>    resource_usage_export = optional(object({<br>      dataset                              = string<br>      enable_network_egress_metering       = optional(bool)<br>      enable_resource_consumption_metering = optional(bool)<br>    }))<br>    service_external_ips = optional(bool, true)<br>    shielded_nodes       = optional(bool, false)<br>    tpu                  = optional(bool, false)<br>    upgrade_notifications = optional(object({<br>      topic_id = optional(string)<br>    }))<br>    vertical_pod_autoscaling = optional(bool, false)<br>    workload_identity        = optional(bool, true)<br>  })</pre> | <pre>{<br>  "workload_identity": true<br>}</pre> | no |
| issue\_client\_certificate | Enable issuing client certificate. | `bool` | `false` | no |
| labels | Cluster resource labels. | `map(string)` | `null` | no |
| location | Cluster zone or region. | `string` | n/a | yes |
| logging\_config | Logging configuration. | <pre>object({<br>    enable_system_logs             = optional(bool, true)<br>    enable_workloads_logs          = optional(bool, false)<br>    enable_api_server_logs         = optional(bool, false)<br>    enable_scheduler_logs          = optional(bool, false)<br>    enable_controller_manager_logs = optional(bool, false)<br>  })</pre> | `{}` | no |
| maintenance\_config | Maintenance window configuration. | <pre>object({<br>    daily_window_start_time = optional(string)<br>    recurring_window = optional(object({<br>      start_time = string<br>      end_time   = string<br>      recurrence = string<br>    }))<br>    maintenance_exclusions = optional(list(object({<br>      name       = string<br>      start_time = string<br>      end_time   = string<br>      scope      = optional(string)<br>    })))<br>  })</pre> | <pre>{<br>  "daily_window_start_time": "03:00",<br>  "maintenance_exclusion": [],<br>  "recurring_window": null<br>}</pre> | no |
| max\_pods\_per\_node | Maximum number of pods per node in this cluster. | `number` | `110` | no |
| min\_master\_version | Minimum version of the master, defaults to the version of the most recent official release. | `string` | `null` | no |
| monitoring\_config | Monitoring configuration. Google Cloud Managed Service for Prometheus is enabled by default. | <pre>object({<br>    enable_system_metrics = optional(bool, true)<br><br>    # Control plane metrics<br>    enable_api_server_metrics         = optional(bool, false)<br>    enable_controller_manager_metrics = optional(bool, false)<br>    enable_scheduler_metrics          = optional(bool, false)<br><br>    # Kube state metrics<br>    enable_daemonset_metrics   = optional(bool, false)<br>    enable_deployment_metrics  = optional(bool, false)<br>    enable_hpa_metrics         = optional(bool, false)<br>    enable_pod_metrics         = optional(bool, false)<br>    enable_statefulset_metrics = optional(bool, false)<br>    enable_storage_metrics     = optional(bool, false)<br><br>    # Google Cloud Managed Service for Prometheus<br>    enable_managed_prometheus = optional(bool, true)<br>  })</pre> | `{}` | no |
| name | Cluster name. | `string` | n/a | yes |
| node\_config | Node-level configuration. | <pre>object({<br>    boot_disk_kms_key = optional(string)<br>    service_account   = optional(string)<br>    tags              = optional(list(string))<br>  })</pre> | `{}` | no |
| node\_locations | Zones in which the cluster's nodes are located. | `list(string)` | `[]` | no |
| private\_cluster\_config | Private cluster configuration. | <pre>object({<br>    enable_private_endpoint = optional(bool)<br>    master_global_access    = optional(bool)<br>    peering_config = optional(object({<br>      export_routes = optional(bool)<br>      import_routes = optional(bool)<br>      project_id    = optional(string)<br>    }))<br>  })</pre> | `null` | no |
| project\_id | Cluster project id. | `string` | n/a | yes |
| release\_channel | Release channel for GKE upgrades. | `string` | `null` | no |
| vpc\_config | VPC-level configuration. | <pre>object({<br>    network                = string<br>    subnetwork             = string<br>    master_ipv4_cidr_block = optional(string)<br>    secondary_range_blocks = optional(object({<br>      pods     = string<br>      services = string<br>    }))<br>    secondary_range_names = optional(object({<br>      pods     = optional(string, "pods")<br>      services = optional(string, "services")<br>    }))<br>    master_authorized_ranges = optional(map(string))<br>    stack_type               = optional(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ca\_certificate | Public certificate of the cluster (base64-encoded). |
| cluster | Cluster resource. |
| endpoint | Cluster endpoint. |
| id | FUlly qualified cluster id. |
| location | Cluster location. |
| master\_version | Master version. |
| name | Cluster name. |
| notifications | GKE PubSub notifications topic. |
| self\_link | Cluster self link. |
| workload\_identity\_pool | Workload identity pool. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->