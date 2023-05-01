#! /usr/bin/awk -f

{
    # find in the file where the resource group list starts
    match_regex = "\"resource_groups\":"

    # once the resource groups definition starts, insert settings for Default resource group and we want to ignore the 
    # rest of the lines within the definition until the security groups definition starts.
    if (match($0, match_regex) != 0) {
        print($0)
        print("      {")
        print("         \"create\": false,")
        print("         \"name\": \"Default\",")
        print("         \"use_prefix\": false")
        print("      }")
        print("   ],")

        eatLines = "true"
    } 
    else
    {
        # once we find the security groups definition, then keep remaining lines.
        end_match = "\"security_groups\":"
        if (match($0, end_match) != 0) {
            eatLines = "false"
        }

        if (eatLines != "true") {
            sub("slz-service-rg", "Default", $0)
            sub("slz-workload-rg", "Default", $0)
            print($0)
        }
    }
} 