# Extending a DA 

This tutorial customizes an existing deployable architecture with an extension that deploys a virtual server that is running an Apache webserver.  This is to illustrate deploying a simple workload(Apache webserver) into an existing 
landscape.  

Key points of this scenario are as follows:
1.  a deployable architecture is deployed as a dependency.  It provides a basis for additional building blocks to be deployed.
2.  an "extension" deployable architecture deploys a workload onto the dependent landscape.

Illustrated here are simple practices for developing the deployable architectures that will allow an extension to leverage a dependency.

A design point for the extension is that it is to be implemented such that it requires minimal inputs from the consumer and that it integrates with its dependency.  More specifically with this example, it is desired that the 
Apache webserver workload virtual server be deployed within a virtual private cloud (VPC) created by the Custom SLZ.  Doing requires specific information such as the id of the VPC, information about its subnets, an ssh key, etc.  
Additionally, the resources deployed by Custom SLZ used a string prefix so that the names of the deployed resources would be named similiarly.  They are also in the same resource group.  It is desireable that any new resources 
deployed on the Custom SLZ landscape follow the same naming conventions and use the same resource group.

Much of the information mentioned so far has already been given to the Custom SLZ deployment.  It just needs to be made available to an extension.  The way to do this is for the Custom SLZ deployable architecture to 
enable extensions by recording information for later use by using the terraform output directive.  Output values are then emitted and saved in the IBM Cloud Schematics workspace.  The extension is implemented with 
code that reads the workspace and retrieves the values.  With this technique, the two parts are deployed separately and as long as the workspace from the deployment of the Custom SLZ deployable architecture is still 
accessible, then this works.  In a different tutorial additional methods will be illustrated.

# Utilizing output from the dependent landscape

Below is an example of the full set of output values that are emitted from the deployment of the dependent base layer.  The output is decoded json.  To get the output from an IBM Schematics 
workspace utilize the `ibm_schematics_workspace` and the `ibm_schematics_output` resources.

```
data "ibm_schematics_workspace" "schematics_workspace" {
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
}

data "ibm_schematics_output" "schematics_output" {
  workspace_id = var.prerequisite_workspace_id
  location     = local.location
  template_id  = data.ibm_schematics_workspace.schematics_workspace.runtime_data[0].id
}

workspace_outputs = jsondecode(data.ibm_schematics_output.schematics_output.output_json)
```


When accessing one of the output values, its important to note 
whether or not the value is an entry within an array, list, map or a simple value.  All of the data within the decoded output is a list where each output has a property of a `type` and a `value`.  Using the example 
below, if we wanted to access the value for the `prefix`, then we just need to get the `value` property's value so access it by 
```
prefix.value
```
but also add the location of the all of the outputs which is the `workspace_outputs` array.  The complete way to access the value of the `prefix` is 
```
workspace_outputs[0].prefix.value
```

Looking at a slightly more complicated example, look at retrieving the value of the `resource_group_data` output.  Specifically we are interested in the resource group's id.  The value is a map where the key is 
the resource group's name and key's value is the resource group id.  Terraform provides the function `values` to assist with doing that.  This is done like this
```
resource_group_data.value <-- which is a list and we want the first entry
(resource_group_data.value)[0]  <-- add in the workspace_outputs
values((workspace_outputs[0].resource_group_data).value)[0]
```

Outputs:

```
 workspace_outputs = [
      + {
          + fip_vsi                 = {
              + type  = [
                  + "tuple",
                  + [
                      + [
                          + "object",
                          + {
                              + floating_ip  = "string"
                              + id           = "string"
                              + ipv4_address = "string"
                              + name         = "string"
                              + vpc_id       = "string"
                              + vpc_name     = "string"
                              + zone         = "string"
                            },
                        ],
                    ],
                ]
              + value = [
                  + {
                      + floating_ip  = "150.239.85.83"
                      + id           = "0757_7595f751-c743-4b8f-ae9c-d71b613348c8"
                      + ipv4_address = "10.10.10.4"
                      + name         = "kb-test-0607a-jump-box-1"
                      + vpc_id       = "r014-e41c3226-8d2b-473f-ac41-6516f629984d"
                      + vpc_name     = "kb-test-0607a-workload-vpc"
                      + zone         = "us-east-1"
                    },
                ]
            }
          + prefix                  = {
              + type  = "string"
              + value = "kb-test-0607a"
            }
          + resource_group_data     = {
              + type  = [
                  + "object",
                  + {
                      + Default = "string"
                    },
                ]
              + value = {
                  + Default = "e125a8a72fe6439ca0b4bfa423048dbd"
                }
            }
          + schematics_workspace_id = {
              + type  = "string"
              + value = "us-south.workspace.globalcatalog-collection.8c0d4826"
            }
          + ssh_key_data            = {
              + type  = [
                  + "tuple",
                  + [
                      + [
                          + "object",
                          + {
                              + create = "bool"
                              + id     = "string"
                              + name   = "string"
                            },
                        ],
                    ],
                ]
              + value = [
                  + {
                      + create = true
                      + id     = "r014-1d595ba5-8fa5-48b2-9f90-e74292eb7175"
                      + name   = "ssh-key"
                    },
                ]
            }
          + subnet_data             = {
              + type  = [
                  + "tuple",
                  + [
                      + [
                          + "object",
                          + {
                              + cidr = "string"
                              + id   = "string"
                              + name = "string"
                              + zone = "string"
                            },
                        ],
                    ],
                ]
              + value = [
                  + {
                      + cidr = "10.10.10.0/24"
                      + id   = "0757-12e3c648-4973-4f3b-957e-672925915549"
                      + name = "kb-test-0607a-workload-vsi-zone-1"
                      + zone = "us-east-1"
                    },
                ]
            }
          + vpc_data                = {
              + type  = [
                  + "tuple",
                  + [
                      + [
                          + "object",
                          + {
                              + network_acls       = [
                                  + "tuple",
                                  + [
                                      + [
                                          + "object",
                                          + {
                                              + id        = "string"
                                              + shortname = "string"
                                            },
                                        ],
                                    ],
                                ]
                              + public_gateways    = [
                                  + "object",
                                  + {
                                      + zone-1 = "dynamic"
                                      + zone-2 = "dynamic"
                                      + zone-3 = "dynamic"
                                    },
                                ]
                              + subnet_detail_list = [
                                  + "object",
                                  + {
                                      + us-east-1 = [
                                          + "object",
                                          + {
                                              + kb-test-0607a-workload-vsi-zone-1 = [
                                                  + "object",
                                                  + {
                                                      + cidr = "string"
                                                      + id   = "string"
                                                    },
                                                ]
                                            },
                                        ]
                                    },
                                ]
                              + subnet_detail_map  = [
                                  + "object",
                                  + {
                                      + zone-1 = [
                                          + "tuple",
                                          + [
                                              + [
                                                  + "object",
                                                  + {
                                                      + cidr_block = "string"
                                                      + id         = "string"
                                                      + zone       = "string"
                                                    },
                                                ],
                                            ],
                                        ]
                                    },
                                ]
                              + subnet_ids         = [
                                  + "tuple",
                                  + [
                                      + "string",
                                    ],
                                ]
                              + subnet_zone_list   = [
                                  + "tuple",
                                  + [
                                      + [
                                          + "object",
                                          + {
                                              + cidr = "string"
                                              + id   = "string"
                                              + name = "string"
                                              + zone = "string"
                                            },
                                        ],
                                    ],
                                ]
                              + vpc_crn            = "string"
                              + vpc_flow_logs      = [
                                  + "tuple",
                                  + [],
                                ]
                              + vpc_id             = "string"
                              + vpc_name           = "string"
                            },
                        ],
                    ],
                ]
              + value = [
                  + {
                      + network_acls       = [
                          + {
                              + id        = "r014-3592be46-50bc-499c-9e9c-9fdceddee80e"
                              + shortname = "workload-acl"
                            },
                        ]
                      + public_gateways    = {
                          + zone-1 = null
                          + zone-2 = null
                          + zone-3 = null
                        }
                      + subnet_detail_list = {
                          + us-east-1 = {
                              + kb-test-0607a-workload-vsi-zone-1 = {
                                  + cidr = "10.10.10.0/24"
                                  + id   = "0757-12e3c648-4973-4f3b-957e-672925915549"
                                }
                            }
                        }
                      + subnet_detail_map  = {
                          + zone-1 = [
                              + {
                                  + cidr_block = "10.10.10.0/24"
                                  + id         = "0757-12e3c648-4973-4f3b-957e-672925915549"
                                  + zone       = "us-east-1"
                                },
                            ]
                        }
                      + subnet_ids         = [
                          + "0757-12e3c648-4973-4f3b-957e-672925915549",
                        ]
                      + subnet_zone_list   = [
                          + {
                              + cidr = "10.10.10.0/24"
                              + id   = "0757-12e3c648-4973-4f3b-957e-672925915549"
                              + name = "kb-test-0607a-workload-vsi-zone-1"
                              + zone = "us-east-1"
                            },
                        ]
                      + vpc_crn            = "crn:v1:bluemix:public:is:us-east:a/d86af7367f70fba4f306d3c19c7320a9::vpc:r014-e41c3226-8d2b-473f-ac41-6516f629984d"
                      + vpc_flow_logs      = []
                      + vpc_id             = "r014-e41c3226-8d2b-473f-ac41-6516f629984d"
                      + vpc_name           = "kb-test-0607a-workload-vpc"
                    },
                ]
            }
        },
    ]
 ``` 