##### 1 - Get Org moid based on name #### 
data "intersight_organization_organization" "myorg" {
  name = var.org_name
}

##### 2 - Get blade moid based on Serial #### 
data "intersight_compute_blade" "myblade" {
  serial  = var.server_serial
  ## asset_tag = var.server_tag ### Asset tag assigned to Server can also be used to identify blade where SP will be assigned ###
}

##### 3 - Get existing mac-pool based on name #### 
data "intersight_macpool_pool" "mymac_pool" {
  name = var.mac_pool
}

### 4 - Create new IP pool for CIMC mgmt access ###
resource "intersight_ippool_pool" "myIP_pool" {
  name             = var.ip_pool
  assignment_order = "sequential"
  
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }

  ip_v4_config {
    object_type = "ippool.IpV4Config"
    gateway     = "1.1.1.1"
    netmask     = "255.255.255.128"
    primary_dns = "1.1.1.100"
  }

  ip_v4_blocks {
    from = var.first_IP
    to   = var.last_IP
   ## size = 1 ## size not needed if you provide end address
  }
}

##### 5 - Create new IMC Access Policy consuming IP pool #### 
resource "intersight_access_policy" "myIMC_pol" {
  name        = "var.imc_pol"
  description = "demo imc access policy"
  inband_vlan = var.inband_vlan
  
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
  inband_ip_pool {
    object_type = "ippool.Pool"
    moid        = intersight_ippool_pool.myIP_pool.moid
  }
}


##### 6 - Create new boot policy  #### 
resource "intersight_boot_precision_policy" "myboot_pol"{
  name = var.boot_pol
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
  configured_boot_mode     = "Uefi"
  boot_devices {
    name = "local-SSD"
    enabled     = true
    object_type = "boot.LocalDisk"
    additional_properties = jsonencode({
      Slot = "MSTOR-RAID"
    })
  }
}

##### 7 - Create new LAN Policy #### 
 resource "intersight_vnic_lan_connectivity_policy" "mylan_pol" {
  name = var.lan_pol
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
  target_platform = "FIAttached"
  placement_mode  = "auto"
}

##### 8 - Create new Eth Network Group Policy #### 
  resource "intersight_fabric_eth_network_group_policy" "mynet_group_pol" {
  name = var.netGroup_pol
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
  vlan_settings {
    object_type  = "fabric.VlanSettings"
    allowed_vlans = var.vlan_range
    native_vlan = "1"
  }
}

##### 9 - Create new QoS Policy #### 
resource "intersight_vnic_eth_qos_policy" "myqos_pol" {
  name = var.qos_pol
   mtu  = "9000"
   priority       = "Best Effort"
   organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
}

##### 10 - Create new Eth Network Control Policy #### 
resource "intersight_fabric_eth_network_control_policy" "mynetControl_pol" {
  name = var.netControl_pol
  cdp_enabled = false
  lldp_settings {
    receive_enabled  = true
    transmit_enabled = true
  }
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
}

##### 11 - Create new Eth Adapter Policy #### 
resource "intersight_vnic_eth_adapter_policy" "mynetAdapter_pol" {
  name = var.netAdapter_pol
  organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }    
}

##### 12 - Create new vnic under LAN policy #### 
resource "intersight_vnic_eth_if" "vnic-A" {
  name = "vnic-A"
  order = 0
  placement {
    id          = "1"
    switch_id   = "A"
    pci_link    = 0
    uplink      = 0
    object_type = "vnic.PlacementSettings"
  }
  
  mac_pool {
    moid = data.intersight_macpool_pool.mymac_pool.results[0].moid
  }

  lan_connectivity_policy {
    moid        = intersight_vnic_lan_connectivity_policy.mylan_pol.moid
    object_type = "vnic.LanConnectivityPolicy"
  }

  fabric_eth_network_group_policy {
    moid = intersight_fabric_eth_network_group_policy.mynet_group_pol.moid
    #object_type = "vnic.EthNetworkGroupPolicy"
  }

  fabric_eth_network_control_policy {
    moid = intersight_fabric_eth_network_control_policy.mynetControl_pol.moid
    #object_type = "vnic.EthNetworkControlPolicy"
  }

  eth_qos_policy {
    moid = intersight_vnic_eth_qos_policy.myqos_pol.moid
    object_type = "vnic.EthQosPolicy"
  }

  eth_adapter_policy {
    moid = intersight_vnic_eth_adapter_policy.mynetAdapter_pol.moid
    object_type = "vnic.EthAdapterPolicy"
  }
}

##### 11 - Create Server Profile with defined policies #### 
##### Assign SP to Blade Server with specific Serial ####
resource "intersight_server_profile" "srv_prof" {
    name = var.server_profile
    target_platform = "FIAttached"

    organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
  
    policy_bucket {
    moid        = intersight_boot_precision_policy.myboot_pol.moid
    object_type = "boot.PrecisionPolicy"
    }

    policy_bucket {
    moid        = intersight_vnic_lan_connectivity_policy.mylan_pol.moid
    object_type = "vnic.LanConnectivityPolicy"
    }
  
  ### Assign SP to selected Blade server ###
    assigned_server {
        moid = data.intersight_compute_blade.myblade.results[0].moid
        object_type = "compute.Blade"
    }
    
  }

