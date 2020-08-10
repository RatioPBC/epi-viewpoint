# Epicenter

## Resources

* Repo: https://gitlab.com/geometerio/resolve/epicenter
* CI: https://gitlab.com/geometerio/resolve/epicenter/-/pipelines

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
