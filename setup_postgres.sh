# Place the data directory inside the project directory
export PGDATA="$(pwd)/postgres"
# Place Postgres' Unix socket inside the data directory
export PGHOST="$PGDATA"

if [[ ! -d "$PGDATA" ]]; then
	# If the data directory doesn't exist, create an empty one, and...
	initdb
	# ...configure it to listen only on the Unix socket, and...
	cat >> "$PGDATA/postgresql.conf" <<-EOF
		listen_addresses = ''
		unix_socket_directories = '$PGHOST'
	EOF
	# ...create a database using the name Postgres defaults to.
	echo "CREATE DATABASE $USER;" | postgres --single -E postgres
fi