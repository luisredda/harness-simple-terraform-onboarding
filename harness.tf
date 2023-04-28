terraform {
  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.19.0"
    }
  }
}

provider "harness" {
  platform_api_key = var.api_key
  account_id = var.account_id
}

resource "harness_platform_project" "my_project" {
  identifier = var.project_identifier
  name       = var.project_name
  org_id     = var.org_id
  color      = var.project_color
}

resource "harness_platform_service" "my_service" {
  depends_on = [harness_platform_project.my_project]
  identifier  = var.service_identifier
  name        = var.service_name
  description = var.service_description
  org_id      = var.org_id
  project_id  = harness_platform_project.my_project.id
    
  yaml = <<-EOT
    service:
      name: ${var.service_name}
      identifier: ${var.service_identifier}
      serviceDefinition:
        spec:
          manifests:
            - manifest:
                identifier: manifest1
                type: K8sManifest
                spec:
                  store:
                    type: Github
                    spec:
                      connectorRef: <+input>
                      gitFetchType: Branch
                      paths:
                        - files1
                      repoName: <+input>
                      branch: master
                  skipResourceVersioning: false
          configFiles:
            - configFile:
                identifier: configFile1
                spec:
                  store:
                    type: Harness
                    spec:
                      files:
                        - <+org.description>
          variables:
            - name: var1
              type: String
              value: val1
            - name: var2
              type: String
              value: val2
        type: Kubernetes
      gitOpsEnabled: false
  EOT
}

resource "harness_platform_environment" "example" {
  depends_on = [harness_platform_service.my_service]
  identifier = var.environment_id
  name       = var.environment_name
  org_id     = var.org_id
  project_id = var.project_identifier
  tags       = ["foo:bar", "baz"]
  type       = "PreProduction"

  ## ENVIRONMENT V2 Update
  ## The YAML is needed if you want to define the Environment Variables and Overrides for the environment
  ## Not Mandatory for Environment Creation nor Pipeline Usage

  yaml = <<-EOT
       environment:
         name: ${var.environment_name}
         identifier: ${var.environment_id}
         orgIdentifier: ${var.org_id}
         projectIdentifier: ${harness_platform_project.my_project.id}
         type: PreProduction
         tags:
           foo: bar
           baz: ""
         variables:
           - name: envVar1
             type: String
             value: v1
             description: ""
           - name: envVar2
             type: String
             value: v2
             description: ""
         overrides:
           manifests:
             - manifest:
                 identifier: manifestEnv
                 type: Values
                 spec:
                   store:
                     type: Git
                     spec:
                       connectorRef: <+input>
                       gitFetchType: Branch
                       paths:
                         - file1
                       repoName: <+input>
                       branch: master
           configFiles:
             - configFile:
                 identifier: configFileEnv
                 spec:
                   store:
                     type: Harness
                     spec:
                       files:
                         - account:/Add-ons/svcOverrideTest
                       secretFiles: []
      EOT
}

resource "harness_platform_infrastructure" "example" {
  depends_on = [harness_platform_environment.example]
  identifier      = var.infra_id
  name            = var.infra_name
  org_id          = var.org_id
  project_id      = var.project_identifier
  env_id          = var.environment_id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<-EOT
        infrastructureDefinition:
         name: ${var.infra_name}
         identifier: ${var.infra_id}
         description: ""
         tags:
           asda: ""
         orgIdentifier: ${var.org_id}
         projectIdentifier: ${var.project_identifier}
         environmentRef: ${var.environment_id}
         deploymentType: Kubernetes
         type: KubernetesDirect
         spec:
          connectorRef: account.default
          namespace: asdasdsa
          releaseName: release-<+INFRA_KEY>
          allowSimultaneousDeployments: false
      EOT
}

resource "harness_platform_ff_api_key" "testserverapikey" {
  depends_on = [harness_platform_environment.example]
  identifier  = "testserverapikey"
  name        = "testserverapikey"
  description = "this is a server SDK key"
  org_id      = var.org_id
  project_id  = var.project_identifier
  env_id      = var.environment_id
  expired_at  = 1714273200000
  type        = "Client"
}

output "serversdkkey" {
  value     = harness_platform_ff_api_key.testserverapikey.api_key
  sensitive = true
}

resource "harness_platform_feature_flag" "enable_ce_module" {
  depends_on = [harness_platform_ff_api_key.testserverapikey]
  org_id          = var.org_id
  project_id      = var.project_identifier

  kind       = "boolean"
  name       = "Enable CE Module"
  identifier = "Enable_CE_Module"
  permanent  = false

  default_on_variation  = "Enabled"
  default_off_variation = "Disabled"

  variation {
    identifier  = "Enabled"
    name        = "Enabled"
    description = "The feature is enabled"
    value       = "true"
  }

  variation {
    identifier  = "Disabled"
    name        = "Disabled"
    description = "The feature is disabled"
    value       = "false"
  }
}

resource "harness_platform_feature_flag" "enable_sto_module" {
  depends_on = [harness_platform_feature_flag.enable_ce_module]
  org_id          = var.org_id
  project_id      = var.project_identifier

  kind       = "boolean"
  name       = "Enable STO Module"
  identifier = "Enable_STO_Module"
  permanent  = false

  default_on_variation  = "Enabled"
  default_off_variation = "Disabled"

  variation {
    identifier  = "Enabled"
    name        = "Enabled"
    description = "The feature is enabled"
    value       = "true"
  }

  variation {
    identifier  = "Disabled"
    name        = "Disabled"
    description = "The feature is disabled"
    value       = "false"
  }
}

resource "harness_platform_feature_flag" "enable_ccm_module" {
  depends_on = [harness_platform_feature_flag.enable_sto_module]
  org_id          = var.org_id
  project_id      = var.project_identifier

  kind       = "boolean"
  name       = "Enable CCM Module"
  identifier = "Enable_CCM_Module"
  permanent  = false

  default_on_variation  = "Enabled"
  default_off_variation = "Disabled"

  variation {
    identifier  = "Enabled"
    name        = "Enabled"
    description = "The feature is enabled"
    value       = "true"
  }

  variation {
    identifier  = "Disabled"
    name        = "Disabled"
    description = "The feature is disabled"
    value       = "false"
  }
}

resource "harness_platform_feature_flag" "enable_srm_module" {
  depends_on = [harness_platform_feature_flag.enable_ccm_module]
  org_id          = var.org_id
  project_id      = var.project_identifier

  kind       = "boolean"
  name       = "Enable SRM Module"
  identifier = "Enable_SRM_Module"
  permanent  = false

  default_on_variation  = "Enabled"
  default_off_variation = "Disabled"

  variation {
    identifier  = "Enabled"
    name        = "Enabled"
    description = "The feature is enabled"
    value       = "true"
  }

  variation {
    identifier  = "Disabled"
    name        = "Disabled"
    description = "The feature is disabled"
    value       = "false"
  }
}


resource "harness_platform_feature_flag" "enable_ff_module" {
  depends_on = [harness_platform_feature_flag.enable_srm_module]
  org_id          = var.org_id
  project_id      = var.project_identifier

  kind       = "boolean"
  name       = "Enable FF Module"
  identifier = "Enable_FF_Module"
  permanent  = false

  default_on_variation  = "Enabled"
  default_off_variation = "Disabled"

  variation {
    identifier  = "Enabled"
    name        = "Enabled"
    description = "The feature is enabled"
    value       = "true"
  }

  variation {
    identifier  = "Disabled"
    name        = "Disabled"
    description = "The feature is disabled"
    value       = "false"
  }
}

resource "harness_platform_feature_flag" "enable_cd_module" {
  depends_on = [harness_platform_feature_flag.enable_ff_module]
  org_id          = var.org_id
  project_id      = var.project_identifier

  kind       = "boolean"
  name       = "Enable CD Module"
  identifier = "Enable_CD_Module"
  permanent  = false

  default_on_variation  = "Enabled"
  default_off_variation = "Disabled"

  variation {
    identifier  = "Enabled"
    name        = "Enabled"
    description = "The feature is enabled"
    value       = "true"
  }

  variation {
    identifier  = "Disabled"
    name        = "Disabled"
    description = "The feature is disabled"
    value       = "false"
  }
}

resource "harness_platform_feature_flag" "enablecimodule" {
  depends_on = [harness_platform_feature_flag.enable_cd_module]
  org_id          = var.org_id
  project_id      = var.project_identifier

  kind       = "boolean"
  name       = "Enable CI Module"
  identifier = "Enable_CI_Module"
  permanent  = false

  default_on_variation  = "Enabled"
  default_off_variation = "Disabled"

  variation {
    identifier  = "Enabled"
    name        = "Enabled"
    description = "The feature is enabled"
    value       = "true"
  }

  variation {
    identifier  = "Disabled"
    name        = "Disabled"
    description = "The feature is disabled"
    value       = "false"
  }
}
