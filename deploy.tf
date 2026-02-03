data "intersight_organization_organization" "myorg" {
  name = var.org_name
}

data "intersight_compute_blade" "myblade" {
  serial  = var.server_serial
}


resource "intersight_server_profile" "srv_prof" {
    name = var.server_profile
    organization {
    object_type = "organization.Organization"
    moid        = data.intersight_organization_organization.myorg.results[0].moid
  }
    target_platform = "FIAttached"
    action = "Deploy"
  
  #### Activate will cause a reboot ###
  ##  scheduled_actions  {
  ##  action = "Activate"
  ##  }
}
