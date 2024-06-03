{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, utils, ... }:

    utils.lib.eachDefaultSystem (system:
      let
        nodejsVersion = 20;
        overlays = [
          (final: prev: {
            nodejs = prev."nodejs_${toString nodejsVersion}";
          })
        ];

        pkgs = import nixpkgs { inherit overlays system; };

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs

            (stdenv.mkDerivation {
              name = "corepack-shims";
              buildInputs = [ nodejs ];
              phases = [ "installPhase" ];
              installPhase = ''
                mkdir -p $out/bin
                corepack enable --install-directory=$out/bin
              '';
            })
          ];

          shellHook = with pkgs;''
            echo "node `${nodejs}/bin/node --version`"
            echo "yarn `${yarn}/bin/yarn --version`"
            echo "pnpm `${pnpm}/bin/pnpm --version`"
          '';
        };

      });
}
