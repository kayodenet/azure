#!bin/bash

az group delete -n MyResourceGroup
rm -rf .terraform
rm terraform.*
rm .terraform.*
