{
  description = "A Nix-flake-based PostgreSQL development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    {
      overlay = final: prev:
        let pgutil = prev.callPackage ./pgutil.nix { }; in
        {
          inherit (pgutil) init_pg create_pg_db start_pg stop_pg;
        };

    } // utils.lib.eachDefaultSystem (system:
      let
        postgresqlVersion = 14;
        overlays = [
          (final: prev: {
            postgresql = prev."postgresql_${toString postgresqlVersion}";
          })

          self.overlay
        ];
        pkgs = import nixpkgs { inherit overlays system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # postgresql 14 (specified by overlay)
            postgresql

            init_pg
            create_pg_db
            start_pg
            stop_pg
          ];

          # UNCOMMENT & FILL the value of this env variable if you used this flake template in your project.
          # PGUSER = "";
          # PGPASSWORD = "";
          # PGHOST = "";
          # PGPORT = "";

          shellHook = ''
            psql --version
          '';
        };

        packages = {
          inherit (pkgs) init_pg create_pg_db start_pg stop_pg;
        };

      });
}

