terraform {
   backend "s3" {
   bucket = "lr-s3-backend"
   key = "terraform.tfstate"
   region = "us-east-2"
  }
}

  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.19.0"
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
                identifier: Manifests
                type: K8sManifest
                spec:
                  store:
                    type: Harness
                    spec:
                      files:
                        - account:/k8sManifests/namespace.yaml
                        - account:/k8sManifests/deployment.yaml
                        - account:/k8sManifests/service.yaml
                  valuesPaths:
                    - account:/k8sManifests/values.yaml
                  skipResourceVersioning: false
                  enableDeclarativeRollback: false
          variables:
            - name: var1
              type: String
              value: val1
            - name: var2
              type: String
              value: val2
          artifacts:
            primary:
              primaryArtifactRef: Dockerhub
              sources:
                - spec:
                    connectorRef: account.LRDockerHub
                    imagePath: luisredda/harness-java-demo-k8s
                    tag: latest
                  identifier: Dockerhub
                  type: DockerRegistry         
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
         tags:
           type: autoprovisioned
           terraform: "true"  
         orgIdentifier: ${var.org_id}
         projectIdentifier: ${harness_platform_project.my_project.id}
         type: PreProduction
         variables:
           - name: envVar1
             type: String
             value: v1
             description: ""
           - name: envVar2
             type: String
             value: v2
             description: ""          
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
           terraform: "true"
         orgIdentifier: ${var.org_id}
         projectIdentifier: ${var.project_identifier}
         environmentRef: ${var.environment_id}
         deploymentType: Kubernetes
         type: KubernetesDirect
         spec:
          connectorRef: account.cddemose
          namespace: temp-${var.project_identifier}
          releaseName: release-<+INFRA_KEY>
          allowSimultaneousDeployments: false
      EOT
}

resource "harness_platform_ff_api_key" "testserverapikey" {
  depends_on = [harness_platform_environment.example]
  identifier  = "testserver"
  name        = "TestServer"
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

resource "harness_platform_pipeline" "example" {
  depends_on = [harness_platform_feature_flag.enablecimodule]
  identifier = "Build_and_Deploy_Java_App"
  org_id     =  var.org_id
  project_id =  var.project_identifier
  name       = "Build and Deploy Java App"
  yaml = <<-EOT
    pipeline:
      name: Build and Deploy Java App
      identifier: Build_and_Deploy_Java_App
      template:
        templateRef: account.Java_Pipeline
        versionLabel: v1
        templateInputs:
          properties:
            ci:
              codebase:
                build: <+input>
                repoName: luisredda/harness-onboarding-demo
          stages:
            - stage:
                identifier: Build_App
                type: CI
                variables:
                  - name: ff_key
                    type: String
                    value: ${harness_platform_ff_api_key.testserverapikey.api_key}
            - stage:
                identifier: K8s_Deployment
                type: Deployment
                spec:
                  service:
                    serviceRef: javaapp
                  environment:
                    environmentRef: dev
                    infrastructureDefinitions:
                      - identifier: k8sdev
      tags: {}
      projectIdentifier: ${var.project_identifier}
      orgIdentifier: ${var.org_id}

  EOT
}

resource "harness_platform_pipeline" "ffpipeline" {
  depends_on = [harness_platform_pipeline.example]
  identifier = "Configure_Feature_Flags"
  org_id     =  var.org_id
  project_id =  var.project_identifier
  name       = "Configure Feature Flags"
  yaml = <<-EOT
    pipeline:
      name: Configure Feature Flags
      identifier: Configure_Feature_Flags
      projectIdentifier: ${var.project_identifier}
      orgIdentifier: ${var.org_id}
      tags: {}
      stages:
        - stage:
            name: Enable FF
            identifier: Enable_FF
            description: ""
            type: FeatureFlag
            spec:
              execution:
                steps:
                  - step:
                      type: FlagConfiguration
                      name: CI Module ON
                      identifier: CI_Module_ON
                      spec:
                        feature: Enable_CI_Module
                        environment: dev
                        instructions:
                          - identifier: SetFeatureFlagStateIdentifier
                            type: SetFeatureFlagState
                            spec:
                              state: "on"
                      timeout: 10m
                  - step:
                      type: FlagConfiguration
                      name: CD Module ON
                      identifier: CD_Module_ON
                      spec:
                        feature: Enable_CD_Module
                        environment: dev
                        instructions:
                          - identifier: SetFeatureFlagStateIdentifier
                            type: SetFeatureFlagState
                            spec:
                              state: "on"
                      timeout: 10m
                  - step:
                      type: FlagConfiguration
                      name: FF Module ON
                      identifier: FF_Module_ON
                      spec:
                        feature: Enable_FF_Module
                        environment: dev
                        instructions:
                          - identifier: SetFeatureFlagStateIdentifier
                            type: SetFeatureFlagState
                            spec:
                              state: "on"
                      timeout: 10m
                  - step:
                      type: FlagConfiguration
                      name: SRM Module ON
                      identifier: SRM_Module_ON
                      spec:
                        feature: Enable_SRM_Module
                        environment: dev
                        instructions:
                          - identifier: SetFeatureFlagStateIdentifier
                            type: SetFeatureFlagState
                            spec:
                              state: "on"
                      timeout: 10m
                  - step:
                      type: FlagConfiguration
                      name: CCM Module ON
                      identifier: CCM_Module_ON
                      spec:
                        feature: Enable_CCM_Module
                        environment: dev
                        instructions:
                          - identifier: SetFeatureFlagStateIdentifier
                            type: SetFeatureFlagState
                            spec:
                              state: "on"
                      timeout: 10m
                  - step:
                      type: FlagConfiguration
                      name: STO Module ON
                      identifier: STO_Module_ON
                      spec:
                        feature: Enable_STO_Module
                        environment: dev
                        instructions:
                          - identifier: SetFeatureFlagStateIdentifier
                            type: SetFeatureFlagState
                            spec:
                              state: "on"
                      timeout: 10m
                  - step:
                      type: FlagConfiguration
                      name: CE Module ON
                      identifier: CE_Module_ON
                      spec:
                        feature: Enable_CE_Module
                        environment: dev
                        instructions:
                          - identifier: SetFeatureFlagStateIdentifier
                            type: SetFeatureFlagState
                            spec:
                              state: "on"
                      timeout: 10m

  EOT
}
