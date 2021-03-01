# Epi Viewpoint

_Epi Viewpoint_ is a focused, simple tool that enables case investigation and contact tracing 
teams to manage cases and contacts and keep track of congregate settings where outbreak clusters 
have occurred.

Built for public health departments that lack the digital tools to manage an overwhelming 
volume of COVID cases, Viewpoint is a simple, focused tool that helps you and your staff 
prioritize who to investigate, what information to collect, and where to focus your efforts. 
Designed to be easy to implement and learn, Viewpoint is the first step to jump-start a 
data-informed COVID containment program.

[Learn more here](https://preventepidemics.org/covid19/us-response/digital-products/epi-viewpoint/).


## Contributing

Viewpoint is open-source, meaning that you can make as many copies of it as you want and do 
whatever you want with those copies, without limitation. But Viewpoint is not accepting 
pull requests or issues at this time.


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

### Running docker on a development machine 

`docker-compose` uses the same docker image that production does.

There are some scripts to make local docker development easier (though they don't get used very often so they may not work):

* `bin/dev/docker-start` will:
  * check that your computer is set up to run the app via docker
  * build the docker image
  * start the docker container
* `bin/dev/docker-bash` will open a bash shell inside the running container
* `bin/dev/docker-iex` will open an iex session inside the running container

### Adding translations

When adding strings to be translated in the domain layer (`Epicenter`), you'll want to use `gettext_noop` to provide a 
hook for `gettext` to be able to extract the keys without translating them in the code at runtime. For example:

```elixir
gettext("some_string_to_be_translated")
```

Once you have added the strings, run the following command to update the po/pot files:

```shell
mix gettext.extract --merge
```

You will then want to update the corresponding key in the `po` file. For example, you'll want to add a `msgstr` value such as:

```gettext
msgid "unable_to_quarantine"
msgstr "Person unable to quarantine"
```

Note that `mix gettext.extract --merge` is run as part of `shipit`, and `shipit` will fail if there are any changes as a result. 


## Deploying

### "Deploy to Heroku" button

Use the Deploy to Heroku button to quickly deploy this app to your Heroku account for demo or exploration purposes.
Heroku accounts are free, and the Deploy to Heroku button only provisions free resources (with the standard limitations
that Heroku puts on free resources).

<a href="https://heroku.com/deploy?template=https://github.com/geometricservices/epi-viewpoint">
  <img src="https://www.herokucdn.com/deploy/button.svg" alt="Deploy">
</a>

#### Instructions

1. Click the button above.
1. Sign up or log into Heroku.
1. Set the app name (e.g., `myviewpoint`).
1. Set the **CANONICAL_HOST** configuration variable to the app name you chose above, 
   followed by `.herokuapp.com` (e.g., `myviewpoint.herokuapp.com`).
1. Set the **INITIAL_USER_EMAIL** configuration variable to the email address you want for the first admin user.
   You will use this email address to log in. 
   Epi Viewpoint does not currently send email, so this technically does not need to be a real email address,
   but it does need to have an "@" sign and cannot include spaces.
1. Click the "Deploy app" button.
1. If the deploy is successful, click on the "View" button at the bottom of the page. 
   If everything has worked properly, you will land on a page asking you to set your password. 
   Enter a new password and click "Continue".
1. You will then be asked to log in. Use the email address you set up earlier plus the password you just created.
1. Configure multifactor authentication with a tool like Google Authenticator, 1Password, etc. 

### Heroku

Run `bin/staging/deploy` which will make sure your Heroku account is all set up for deploying this project, and once
it's happy, it will deploy to Heroku.

### GCP

If you are deploying to GCP, set the `REMOVE_CITEXT_EXTENSION` environment variable to `true` to work around an issue with
GCP cloud_sql import/export.

### Creating users

Unless you used the "Deploy to Heroku" button, you must create the first admin user manually (see the docs 
for `Epicenter.Release.create_user`). After that, you can log in as that admin user and create other users.

### Exporting Data

This command will copy data from the database into the CSV files.

```
psql -f export_csvs.sql <database-name>
```

Depending on permissions with the database, it may be necessary to modify the script to be run within `psql` using the
`\copy` command.

```
\copy ... to ...;
```

## Copyright and license

Copyright © 2021 Geometer, LLC, and Resolve to Save Lives. This code is available under the Apache 2.0 license.
See also [license](LICENSE.txt).
