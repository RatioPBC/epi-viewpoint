# Epicenter

## Resources

* Repo: https://gitlab.com/geometerio/resolve/epicenter
* CI: https://gitlab.com/geometerio/resolve/epicenter/-/pipelines
* Staging: https://viewpoint.staging.gsi.dev/
* Demo: https://viewpoint.demo.gsi.dev/
  * Must be invited to gain access

## Terminology (work-in-progress)
* case - a person with confirmed or suspected covid
* lab result - the information that comes from a laboratory, excluding person's name, phone, address, etc.
* result - "positive" or "negative" lab result

## Development

### Getting started

1. Clone the repo
2. Run `bin/dev/doctor` and for each problem, either use the suggested remedies or fix it some other way
3. Run `bin/dev/test` and then `bin/dev/start` to make sure everything is working

### Day-to-day

* Get latest code: `bin/dev/update`
* Run tests: `bin/dev/test`
* Start server:
  * `bin/dev/start`
  * (to skip running doctor when starting, use `bin/dev/start fast`)
* Run tests and push: `bin/dev/shipit`

## Docker

`docker-compose` uses the same docker image that production does.

There are some scripts to make local docker development easier:

* `bin/dev/docker-start` will:
  * check that your computer is set up to run the app via docker
  * build the docker image
  * start the docker container
* `bin/dev/docker-bash` will open a bash shell inside the running container
* `bin/dev/docker-iex` will open an iex session inside the running container
