# jfrog-cli-resource

This resource is meant for sending and pulling single SBT artifacts to
Artifactory.

This resource is horrible by all standards, but we've had more trouble with all
the others we tried.

The general idea of this resource is to wrap the [`jfrog` cli](https://github.com/jfrog/jfrog-cli).

## :warning: Caveat Emptor

Be advised that this resource is opinionated in the sense it wants you to only
send a single file to Artifactory to keep the operation atomic from a Concourse
point of view. If you mean to send multiple files, it is recommended you do it
with a task, and use something like a GitHub release, or an Artifactory release.

The reasoning behind this is that Artifactory, by default, allows you to
overwrite existing artifacts, and will let you do partial updates to a version.
This type of change cannot be tracked from Concourse's point of view and is
essentially useless as a gate lock, thus the recommmendation to use releases.

_(There's also the fact that Artifactory's API will report success on quite a
few silent failure scenarios... but that's a different story.)_

## Usage

```yaml
source:
  url: creds.data.url,
  username: creds.data.username,
  password: creds.data.password,
  repository: 'libs-test-test',
  path: 'com/adgear/data/',
  artifact_name: 'linear-ads-freqap',
  qualifier: 'distribution',
  extension: '.tar.gz',
params: # When uploading / using out
  source_folder: '_artifacts'
```

## Using the test executables

All the test executable expect to get the credentials from stdin. The expected
schema is:

```json
{
  "data": {
    "username": "username",
    "password": "password",
    "url": "https://my.artifactory.domanin.example/herpderp"
  }
}
```

AdGear users can just pipe the Vault output into those.

```shell
vault read -format json some/vault/path/with/juicy/credz | ./tests/test-check
```

## Contributing

1. Create your feature branch: `git checkout -b feature/my-new-feature`
2. Commit your changes: `git commit -am 'Add some feature'`
3. Push to the branch: `git push origin my-new-feature`
4. Submit a pull request :D

## License

> Copyright AdGear | Samsung Ads
