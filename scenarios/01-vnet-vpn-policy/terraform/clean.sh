#!bin/bash

az group delete -n MyResourceGroup --no-wait
rm -rf .terraform
rm terraform.*
rm .terraform.*
