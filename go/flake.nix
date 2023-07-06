{
  description = "A Nix-flake-based Go development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:

    utils.lib.eachDefaultSystem (system:
      let
        goVersion = 19;
        overlays = [ (final: prev: { go = prev."go_1_${toString goVersion}"; }) ];
        pkgs = import nixpkgs { inherit overlays system; };

      in
      {
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = with pkgs; [
            # go 1.19 (specified by overlay)
            go

            # go lsp
            gopls

            # goimports, godoc, etc.
            gotools

            # https://github.com/golangci/golangci-lint
            golangci-lint
          ];

          shellHook = ''
            ${pkgs.go}/bin/go version
          '';
        };
      });
}
