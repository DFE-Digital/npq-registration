# Connect to an instance running in Azure

This Rails app runs on the
[Teacher Services Cloud](https://github.com/DFE-Digital/teacher-services-cloud)
Kubernetes infrastructure in Azure.

Follow these instructions to [run a Rake task](#run-a-rake-task) or
[open a Rails console](#open-a-rails-console).

## 1. Authenticate to the Kubernetes cluster

You'll need to configure your command line console so it can connect to the
Kubernetes cluster. Your authenticated state should persist for several days,
but you may need to re-authenticate every once in a while.

1. Login to the [Microsoft Azure portal](https://portal.azure.com)

   > Use your `@digitalauth.education.gov.uk` account.
   >
   > Make sure it says "DfE Platform Identity" in the top right corner of the
   > screen below your name. If not, click the settings/cog icon and choose it
   > from the list of directories.

2. Open a console. Navigate to the `npq-registration` repo
   directory and run:

   ```shell
   az login
   ```

   You'll be asked to select development, test (used for review apps) or production.

3. Install kubectl:

   ```shell
   brew install Azure/kubelogin/kubelogin
   ```

> Accessing production deployments requires a
> [PIM (Privileged Identity Management) request](#privileged-identity-management-requests).

### Run a Rake task

To get shell access on a review app for a given PR_NUMBER, run the following:

```shell
make review aks-ssh PULL_REQUEST_NUMBER=[PR_NUMBER]
```

From there, the rake task can be run

To get shell access on production, run:

```shell
make ci production aks-ssh
```

### Open a Rails console

To get a rails console on a review app for a given PR_NUMBER, run the following:

```shell
make review aks-console PULL_REQUEST_NUMBER=[PR_NUMBER]
```

By default a shell will safely run with `--sandbox` providing read only access. To run with read-write, run the following:

```shell
make review aks-rw-console PULL_REQUEST_NUMBER=[PR_NUMBER]
```

To get a read-only rails console on production, run the following:

```shell
make ci production aks-console
```

Likewise, for a read-write console, run the following

```shell
make ci production aks-rw-console
```

### Copy a file

To copy a file from the `tmp` directory on a review app:
```shell
make review aks-download-tmp-file PULL_REQUEST_NUMBER=[PR_NUMBER] FILENAME=somefile.csv
```

The file ends up locally in a subdirectory matching the pod name.

### Privileged Identity Management requests

Accessing resources in the production environment requires elevated privileges.
We do this through Microsoft Entra Privileged Identity Management (PIM) request system.

To make a PIM request:

1. Visit
   [this page](https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup).
2. Activate the 'Member' role for the `s189 CPD production PIM` group.
3. Give a reason for your request and submit.
4. The request must now be approved by another team member

You can view all pending requests
[here](https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/~/aadgroup).


### Environments

There are other environments apart from review apps and production, documented in [Environments](environments.md).

## Useful links

- [Teacher Services Cloud developer documentation](https://github.com/DFE-Digital/teacher-services-cloud/blob/main/documentation/developer-onboarding.md)
