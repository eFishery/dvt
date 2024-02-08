# Special Thanks to: 
# * @Rizary       - https://github.com/Rizary
# * nix-community - https://github.com/nix-community/todomvc-nix/blob/master/nix/database/pgutil.nix

{ writeScriptBin, stdenv }:
# Change .pgdata location to $HOME/.pgdata to anticipate permission error
{
  init_pg = writeScriptBin "init-pg"
    ''
      #!${stdenv.shell}
      pg_pid=""
      set -euo pipefail
      # TODO: explain what's happening here
      LOCAL_PGHOST=$PGHOST
      LOCAL_PGPORT=$PGPORT
      LOCAL_PGUSER=$PGUSER
      LOCAL_PGPASSWORD=$PGPASSWORD

      initdb -D $HOME/.pgdata
      echo "unix_socket_directories = '$(mktemp -d)'" >> $HOME/.pgdata/postgresql.conf

      start-pg
      create-pg-db default
      unset PGUSER PGPASSWORD

      psql postgres -w -c "CREATE ROLE $LOCAL_PGUSER WITH LOGIN PASSWORD '$LOCAL_PGPASSWORD'"

    '';

  create_pg_db = writeScriptBin "create-pg-db"
    ''
      #!${stdenv.shell}
      if [ -z "$1" ]; then
        echo "Error: create-pg-db <DATABASE NAME>. Please provide the required argument."
        exit 1
      fi

      pg_pid=""
      set -euo pipefail
      LOCAL_PGDATABASE=$1
      LOCAL_PGHOST=$PGHOST
      LOCAL_PGPORT=$PGPORT
      LOCAL_PGUSER=$PGUSER
      LOCAL_PGPASSWORD=$PGPASSWORD
      unset PGUSER PGPASSWORD

      psql postgres -w -c "CREATE DATABASE $LOCAL_PGDATABASE"
      psql postgres -w -c "GRANT ALL PRIVILEGES ON DATABASE $LOCAL_PGDATABASE TO $LOCAL_PGUSER"
    '';

  start_pg = writeScriptBin "start-pg"
    ''
      #!${stdenv.shell}
      pg_pid=""
      set -euo pipefail
      LOCAL_PGHOST=$PGHOST
      LOCAL_PGPORT=$PGPORT
      LOCAL_PGUSER=$PGUSER
      LOCAL_PGPASSWORD=$PGPASSWORD
      unset PGUSER PGPASSWORD
      # TODO: port
      pg_ctl -D "$HOME/.pgdata" -w start || (echo pg_ctl failed; exit 1)

      until psql postgres -c "SELECT 1" > /dev/null 2>&1 ; do
          echo waiting for pg
          sleep 0.5
      done
    '';

  stop_pg = writeScriptBin "stop-pg"
    ''
      #!${stdenv.shell}
      pg_pid=""
      set -euo pipefail

      pg_ctl -D $HOME/.pgdata -w -m immediate stop
    '';
}
