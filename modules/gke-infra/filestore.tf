/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_filestore_instance" "instance" {
  for_each = var.filestore_storage
  name     = each.value.name

  project = module.project.project_id

  location = var.gke_location
  tier     = each.value.tier

  file_shares {
    capacity_gb = each.value.capacity_gb
    name        = "filestore_share"
  }

  networks {
    network      = local.cluster_vpc.network
    modes        = ["MODE_IPV4"]
    connect_mode = "DIRECT_PEERING"
  }
}