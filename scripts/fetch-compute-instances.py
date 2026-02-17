#!/usr/bin/env python3
"""
fetch-compute-instances.py
Retrieves GCE compute instances for the GCP project.
Requires: google-cloud-compute, google-auth
"""
import json
import sys
import os

try:
    from google.cloud import compute_v1
    from google.api_core.exceptions import NotFound, PermissionDenied
    from google.auth import default
    from google.auth.exceptions import DefaultCredentialsError
except ImportError:
    print(json.dumps({
        "error": "Required packages not installed",
        "message": "Please install: pip install google-cloud-compute google-auth"
    }))
    sys.exit(1)


def get_project_id():
    """Get the GCP project ID from environment or default credentials."""
    project_id = os.environ.get('GCP_PROJECT_ID') or os.environ.get('GOOGLE_CLOUD_PROJECT')
    
    if not project_id:
        try:
            _, project_id = default()
        except DefaultCredentialsError:
            # Fallback to terraform variable default
            project_id = "gke-cluster-458701"
    
    return project_id


def get_compute_instances(project_id, zone=None):
    """
    Fetch compute instances from GCP.
    
    Args:
        project_id: GCP project ID
        zone: Optional specific zone to query. If None, queries all zones.
    
    Returns:
        dict: JSON-serializable dictionary with instances data
    """
    try:
        credentials, _ = default()
        instances_client = compute_v1.InstancesClient(credentials=credentials)
        
        instances_data = []
        
        if zone:
            # Query specific zone
            zones_to_check = [zone]
        else:
            # Query all zones
            zones_client = compute_v1.ZonesClient(credentials=credentials)
            zones_request = compute_v1.ListZonesRequest(project=project_id)
            zones_to_check = [z.name for z in zones_client.list(request=zones_request)]
        
        for zone_name in zones_to_check:
            try:
                request = compute_v1.ListInstancesRequest(
                    project=project_id,
                    zone=zone_name
                )
                
                for instance in instances_client.list(request=request):
                    # Extract network interfaces and IPs
                    network_interfaces = []
                    for interface in instance.network_interfaces:
                        interface_data = {
                            "network": interface.network.split('/')[-1] if interface.network else None,
                            "subnetwork": interface.subnetwork.split('/')[-1] if interface.subnetwork else None,
                            "internal_ip": interface.network_i_p if hasattr(interface, 'network_i_p') else None,
                        }
                        
                        # Extract external IPs
                        external_ips = []
                        if interface.access_configs:
                            for access_config in interface.access_configs:
                                if access_config.nat_i_p:
                                    external_ips.append(access_config.nat_i_p)
                        
                        if external_ips:
                            interface_data["external_ips"] = external_ips
                        
                        network_interfaces.append(interface_data)
                    
                    # Extract disk information
                    disks = []
                    for disk in instance.disks:
                        disk_data = {
                            "source": disk.source.split('/')[-1] if disk.source else None,
                            "boot": disk.boot,
                            "auto_delete": disk.auto_delete,
                        }
                        disks.append(disk_data)
                    
                    # Build instance data
                    instance_info = {
                        "name": instance.name,
                        "zone": zone_name,
                        "machine_type": instance.machine_type.split('/')[-1] if instance.machine_type else None,
                        "status": instance.status,
                        "network_interfaces": network_interfaces,
                        "disks": disks,
                        "creation_timestamp": instance.creation_timestamp,
                        "tags": list(instance.tags.items) if instance.tags and instance.tags.items else [],
                        "labels": dict(instance.labels) if instance.labels else {},
                    }
                    
                    # Add service account if present
                    if instance.service_accounts:
                        instance_info["service_accounts"] = [
                            {
                                "email": sa.email,
                                "scopes": list(sa.scopes) if sa.scopes else []
                            }
                            for sa in instance.service_accounts
                        ]
                    
                    instances_data.append(instance_info)
                    
            except (NotFound, PermissionDenied, ValueError):
                # Skip zones that don't exist, aren't accessible, or have invalid names
                continue
        
        return {
            "project_id": project_id,
            "total_instances": len(instances_data),
            "instances": instances_data
        }
        
    except Exception as e:
        return {
            "error": str(e),
            "error_type": type(e).__name__,
            "project_id": project_id
        }


def main():
    project_id = get_project_id()
    
    # Allow zone to be passed as argument
    zone = sys.argv[1] if len(sys.argv) > 1 else None
    
    instances_data = get_compute_instances(project_id, zone)
    print(json.dumps(instances_data, indent=2))
    
    # Exit with error code if there was an error
    if "error" in instances_data:
        sys.exit(1)


if __name__ == "__main__":
    main()
