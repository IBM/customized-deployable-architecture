#! /bin/bash

#
# To use the same DA in ys1 cloud, there a just a few changes to be made.  To use this script
#   1.  create a new branch from main
#   2.  be in the root directory of the repo directory tree
#   3.  run this script
# Keep the main branch up to date as per usual.  Create a fresh test branch periodically by running this script
# and create a test release from this branch.  This way dual maintenance is not needed on two branches.
#
# The script changes:
# - in the custom-slz DA, change 'us-east' to 'us-south'
# - in the ibm_catalog.json file, set the programmatic name to 'deploy-arch-ibm-gm-test-slz' to prevent a name 
#   collision with 'custom-deployable-arch' AND set the label to 'Test SLZ'.
# - set the icon for BabySLZ to be different from custom-dep
#

echo "Making changes to BabySLZ variation enable successfull deployment on ys1"

cd solutions/custom-slz || exit

echo "...modify main.tf"
echo ".....change region from us-east to us-south"
sed -i '' 's/us-east/us-south/g' main.tf

cd ../..
echo "...modify ibm_catalog.json"
echo ".....change \"name\": \"custom-deployable-arch\" to \"name\": \"deploy-arch-ibm-gm-test-slz\""
sed -i '' 's/name\": \"custom-deployable-arch/name\": \"deploy-arch-ibm-gm-test-slz/g' ibm_catalog.json

echo ".....change \"label\": \"custom-deployable-arch\" to \"label\": \"Test SLZ\""
sed -i '' 's/label\": \"custom-deployable-arch/label\": \"Test SLZ/g' ibm_catalog.json

echo "...set an icon for Test SLZ"
# determine the index of offering "Test SLZ" in ibm_catalog.json
productIndex=$(jq '[.products[].label] | index("Test SLZ")' < ibm_catalog.json)

newIcon="data:image/svg+xml;base64,PHN2ZyBpZD0iVlNJb25WUENSZWd1bGF0ZWRJbmR1c3RyaWVzIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB2aWV3Qm94PSIwIDAgMzIgMzIiPjxkZWZzPjxsaW5lYXJHcmFkaWVudCBpZD0ibWx5Z3RvdnNiYSIgeDE9Ii0xODU1LjIzMyIgeTE9Ii0yOTkyLjQxNSIgeDI9Ii0xODU1LjIzMyIgeTI9Ii0zMDEyLjAzMSIgZ3JhZGllbnRUcmFuc2Zvcm09Im1hdHJpeCgxLjA2IDAgMCAtLjY2OSAxOTc0Ljk1MiAtMjAwMi41MTgpIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHN0b3Agb2Zmc2V0PSIwIi8+PHN0b3Agb2Zmc2V0PSIuOCIgc3RvcC1vcGFjaXR5PSIwIi8+PC9saW5lYXJHcmFkaWVudD48bGluZWFyR3JhZGllbnQgaWQ9IjhkaHNzaHNxMGIiIHgxPSIzMjguNTAzIiB5MT0iLTY0NTEuNzQxIiB4Mj0iMzI4LjUwMyIgeTI9Ii02NDcxLjM1NyIgZ3JhZGllbnRUcmFuc2Zvcm09Im1hdHJpeCgxLjA2IDAgMCAuNjY5IC0zMzguODgxIDQzNDguMzU4KSIgeGxpbms6aHJlZj0iI21seWd0b3ZzYmEiLz48bGluZWFyR3JhZGllbnQgaWQ9IjZlaXZwZzhiM2MiIHgxPSItOTUzLjI4MiIgeTE9Ii02NTQyLjI0MSIgeDI9Ii05NTMuMjgyIiB5Mj0iLTY1NDguMjIxIiBncmFkaWVudFRyYW5zZm9ybT0ibWF0cml4KDEuMDYgMCAwIC42NjkgMTAzNy4yNTQgNDM4OS45MTcpIiB4bGluazpocmVmPSIjbWx5Z3RvdnNiYSIvPjxsaW5lYXJHcmFkaWVudCBpZD0iM3NnYm8xcHBhZCIgeDE9Ii0xOTE1Ljk1OCIgeTE9Ii0zMTgyLjMyOCIgeDI9Ii0xOTE1Ljk1OCIgeTI9Ii0zMTg5LjkyMyIgZ3JhZGllbnRUcmFuc2Zvcm09Im1hdHJpeCgxLjA2IDAgMCAuNjY5IDIwNDkuNjQzIDIxMzUuMjk3KSIgeGxpbms6aHJlZj0iI21seWd0b3ZzYmEiLz48bGluZWFyR3JhZGllbnQgaWQ9InhtZ3I1Ym9paGYiIHgxPSIwIiB5MT0iMzIiIHgyPSIzMiIgeTI9IjAiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9Ii4xIiBzdG9wLWNvbG9yPSIjZWU1Mzk2Ii8+PHN0b3Agb2Zmc2V0PSIuOSIgc3RvcC1jb2xvcj0iIzhhM2ZmYyIvPjwvbGluZWFyR3JhZGllbnQ+PG1hc2sgaWQ9IjJ2aTFpbmIxcGUiIHg9IjAiIHk9Ii0xLjMxMiIgd2lkdGg9IjMyIiBoZWlnaHQ9IjM0LjYzIiBtYXNrVW5pdHM9InVzZXJTcGFjZU9uVXNlIj48cGF0aCBkPSJNMTYgMzAuMDE5Yy03LjcyIDAtMTQtNi4yOC0xNC0xNHM2LjI4LTE0IDE0LTE0IDE0IDYuMjggMTQgMTQtNi4yOCAxNC0xNCAxNHptMC0yNmMtNi42MTcgMC0xMiA1LjM4My0xMiAxMnM1LjM4MyAxMiAxMiAxMiAxMi01LjM4MyAxMi0xMi01LjM4My0xMi0xMi0xMnoiIHN0eWxlPSJmaWxsOiNmZmYiLz48cGF0aCBkPSJNMTYgMTYuMDE5aDE0LjcwOHYxNC43MDhIMTZ6TTcgMjAuMDE5bC02IDUuNDk0VjYuODI2bDYgNS4wMTV2OC4xNzh6TTIyIDEuMDE5aDguOTAxdjkuMThIMjJ6Ii8+PHBhdGggdHJhbnNmb3JtPSJyb3RhdGUoLTEzNSA5LjE5MyA1LjU3NCkiIHN0eWxlPSJmaWxsOnVybCgjbWx5Z3RvdnNiYSkiIGQ9Ik02LjAxNC0uOTg2aDYuMzU3djEzLjEySDYuMDE0eiIvPjxwYXRoIHRyYW5zZm9ybT0icm90YXRlKDEzNSA5LjE5MyAyNi40MzIpIiBzdHlsZT0iZmlsbDp1cmwoIzhkaHNzaHNxMGIpIiBkPSJNNi4wMTQgMTkuODcyaDYuMzU3djEzLjEySDYuMDE0eiIvPjxwYXRoIHRyYW5zZm9ybT0icm90YXRlKDE4MCAyNy4xNzggMTIuMDE5KSIgc3R5bGU9ImZpbGw6dXJsKCM2ZWl2cGc4YjNjKSIgZD0iTTI0IDEwLjAxOWg2LjM1N3Y0SDI0eiIvPjxwYXRoIHRyYW5zZm9ybT0icm90YXRlKC05MCAxOS41NCA0LjE5OCkiIHN0eWxlPSJmaWxsOnVybCgjM3NnYm8xcHBhZCkiIGQ9Ik0xNi4zNjEgMS42NThoNi4zNTd2NS4wOGgtNi4zNTd6Ii8+PHBhdGggZD0iTTkgMjEuMDE5SDNjLTEuMTAzIDAtMi0uODk3LTItMnYtNmMwLTEuMTAzLjg5Ny0yIDItMmg2YzEuMTAzIDAgMiAuODk3IDIgMnY2YzAgMS4xMDMtLjg5NyAyLTIgMnptLTYtOHY2aDYuMDAxdi02SDN6TTI3LjAwOCAxMC4wMTlIMjRjLTEuMTAzIDAtMi0uODk3LTItMlY1LjAxMWMwLTEuMTAzLjg5Ny0yIDItMmgzLjAwOGMxLjEwMyAwIDIgLjg5NyAyIDJ2My4wMDhjMCAxLjEwMy0uODk3IDItMiAyek0yNCA1LjAxMXYzLjAwOGgzLjAwOVY1LjAxMUgyNHoiIHN0eWxlPSJmaWxsOiNmZmYiLz48L21hc2s+PC9kZWZzPjxnIHN0eWxlPSJtYXNrOnVybCgjMnZpMWluYjFwZSkiPjxwYXRoIGlkPSJDb2xvciIgc3R5bGU9ImZpbGw6dXJsKCN4bWdyNWJvaWhmKSIgZD0iTTAgMGgzMnYzMkgweiIvPjwvZz48cGF0aCBkPSJNMjguMDIgMzBoLThjLTEuMTAzIDAtMi0uODk3LTItMnYtOGMwLTEuMTAzLjg5Ny0yIDItMmg4YzEuMTAzIDAgMiAuODk3IDIgMnY4YzAgMS4xMDMtLjg5NyAyLTIgMnptLTgtMTB2OGg4LjAwMXYtOEgyMC4wMnoiIHN0eWxlPSJmaWxsOiMwMDFkNmMiLz48L3N2Zz4K"
jq --argjson productIndex "$productIndex" --arg newIcon "$newIcon" '.products[$productIndex].offering_icon_url = $newIcon' > ibm_catalog.json.new < ibm_catalog.json
cp ibm_catalog.json.new ibm_catalog.json
rm ibm_catalog.json

echo "done with changes."
echo ""
echo "after onboarding TestSLZ to ys1, update the offering (get/put) and remove the referenced modules section.  The referenced module does not exist in the staging env."