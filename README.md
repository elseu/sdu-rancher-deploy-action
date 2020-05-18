# Rancher Deploy Action

## Usage

### Directory structure

You need to have in the root of your project having a directory called `deploy` within this directory there should be a `values.yaml` file that will be used for the helm chart.

### Action

#### Action options

| Prop          | description                                                                                                                                         |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| token         | Rancher Token for logging in.                                                                                                                       |
| context       | Context of the project to access. (AKA Cluster ID : Project ID)                                                                                     |
| url           | URL of the Rancher instance.                                                                                                                        |
| chart         | Define chart name based on Rancher chart name.                                                                                                      |
| release_name  | Release name, get automaticly prefixed with a envrioment name, based on branch name or if its a versoin tag it gets the production envrioment name. |
| values_file   | Location of the values file                                                                                                                         |
| chart_version | Define chart verion, if not defined it uses the latest chart verion.                                                                                |

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: elseu/sdu-rancher-deploy-action@v1
        with:
          token: RANCHER_TOKEN
          context: RANCHER_CONTEXT
          url: RANCHER_URL
          chart: RANCHER_CHART
          release_name: RELEASE_NAME
          values_file: VALUES
          chart_version: CHART_VERSION
        env:
          MASTER_DATABASE_URL: 'psql://login:test@localhost'
          PRODUCTION_DATABASE_URL: 'psql://login:test@localhost'
          RELEASE_DATABASE_URL: 'psql://login:test@localhost'
          DEVELOP_DATABASE_URL: 'psql://login:test@localhost'
```

#### Envrioment variables

You can add envrioment variables that you want to pass to the deploy script. First it will rename the envrioment variable based on the branch name. So for example when you have as branch name `MASTER` and you have a envrioment variable defined with `MASTER_DATABASE_URL` that becomes `DATABASE_URL` so that you can define variables based on the branch.

Those variables will be used to fill up your values.yaml file where you can define those variables with \${DATABASE_URL} and get replaced with the value that you have given this envrioment variable.
