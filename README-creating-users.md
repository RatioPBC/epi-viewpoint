# Creating users in staging/production

As of this writing, there is no UI to create users. Here's how to do it manually:

1. `bin/staging/iex`
2. `Epicenter.Release.create_user("User's Name", "user@example.com")`