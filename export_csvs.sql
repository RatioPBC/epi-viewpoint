-- Additional details and usage information can be found in the README.md
copy (
    select *
    from addresses
    order by inserted_at asc
    ) to '/tmp/addresses.csv' delimiter ',' csv header;

copy (
    select *
    from case_investigations
    order by inserted_at asc
    ) to '/tmp/case_investigations.csv' delimiter ',' csv header;

copy (
    select *
    from demographics
    order by inserted_at asc
    ) to '/tmp/demographics.csv' delimiter ',' csv header;
copy (
    select *
    from emails
    order by inserted_at asc
    ) to '/tmp/emails.csv' delimiter ',' csv header;
copy (
    select *
    from investigation_notes
    order by inserted_at asc
    ) to '/tmp/investigation_notes.csv' delimiter ',' csv header;
copy (
    select *
    from lab_results
    order by inserted_at asc
    ) to '/tmp/lab_results.csv' delimiter ',' csv header;
copy (
    select *
    from logins
    order by inserted_at asc
    ) to '/tmp/logins.csv' delimiter ',' csv header;
copy (
    select *
    from people
    order by inserted_at asc
    ) to '/tmp/people.csv' delimiter ',' csv header;
copy (
    select *
    from phones
    order by inserted_at asc
    ) to '/tmp/phones.csv' delimiter ',' csv header;
copy (
    select *
    from revisions
    order by inserted_at asc
    ) to '/tmp/revisions.csv' delimiter ',' csv header;
copy (
    select id, seq, name, inserted_at, updated_at, email, confirmed_at, disabled, admin
    from users
    order by inserted_at asc
    ) to '/tmp/users.csv' delimiter ',' csv header;
