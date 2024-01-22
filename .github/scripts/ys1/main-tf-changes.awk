#! /usr/bin/awk -f

{
    # find lines in the file that match this
    match_regex = " *source *=.*\"https://cm.globalcatalog.cloud.ibm.com.*"

    # comment out the catalog url source and insert a source statement to reference the git repo
    if (match($0, match_regex) != 0) {
        print("#"$0)
        # use the same version spec that is on the catalog url within the git repo url being inserted
        versionIndex = index($0,"version=")
        versionString = substr($0, versionIndex + length("version="), length($0)-versionIndex-length("version="))
        print("  source           = \"git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone.git//patterns/vsi?ref="versionString"\"")
    }
    else if (match($0, " *region *=.*\"us-east\"")) {
        print("#"$0)
        # replace us-east with us-south since its ys1
        sub("us-east", "us-south", $0)
        print($0)
    }
    else 
        print($0)
} 