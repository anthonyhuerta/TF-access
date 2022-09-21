# Terraform Womply Access

The module in `src/` creates users and manages their access.

## Local Development

The following commands use Brew to install the necessary development tools:

```
# Uninstall Terraform and use Brew to install tfenv
brew ls --versions terraform && brew uninstall terraform
brew bundle install
# Install the most up to date correct Terraform version for this repo
TF_VERSION_MAJOR=$(sed -n 's~^  required_version \{1,\}[^0-9]*\([0-9]*\)\.\([0-9]*\)[^0-9]*\([0-9]*\)[^0-9]*$~\1.\2~p' src/versions.tf)
tfenv install $(tfenv list-remote | grep "^${TF_VERSION_MAJOR}\.[0-9]\+" | head -n 1)
# Always use the correct Terraform version while in this repo
echo "latest:^${TF_VERSION_MAJOR}" > .terraform-version
```

### Example Files

When using this root module for your own environment in a shared account you'll want to create the files `localdev.auto.tfvars` and `localdev_override.tf` inside the `src/` directory. The directory `src/examples/ contains examples that you can use as a starting point for your own.

Note: Outside of this directory any files starting with `localdev*` will be ignored by git.

## Terraform Apply

Using Terraform Cloud as our backend results in all executions being performed remotely. As a result the credentials that Terraform uses must be set as environmental variables in Terraform Cloud.
