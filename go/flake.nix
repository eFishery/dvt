{
  description = "A Nix-flake-based Go development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:

    utils.lib.eachDefaultSystem (system:
      let
        goVersion = 21;
        overlays = [ (final: prev: { go = prev."go_1_${toString goVersion}"; }) ];
        pkgs = import nixpkgs { inherit overlays system; };

        # common dependency

        # custom fork of swagger used by efishery
        # due to its ability to add custom tag on generated code
        # the nix package did not expose any param to override
        # thus we make a separate package for this flake
        # ref: https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/development/tools/go-swagger/default.nix
        maaf72-go-swagger = with pkgs; buildGoModule rec {
          pname = "go-swagger-custom";
          version = "0.30.6-maaf72.1";

          src = fetchGit {
            # TODO: consider move this fork into efishery repo
            url = "https://github.com/MAAF72/go-swagger.git";
            ref = "master";
            rev = "e05ec5b59149e59afa2acb79479eaec6a68106cf";
          };

          doCheck = false;
          subPackages = [ "cmd/swagger" ];
          ldflags = [
            "-s"
            "-w"
            "-X github.com/MAAF72/go-swagger/cmd/swagger/commands.Version=${version}"
            "-X github.com/MAAF72/go-swagger/cmd/swagger/commands.Commit=${src.rev}"
          ];


          vendorHash = "sha256-TqoTzxPGF0BBUfLtYWkljRcmr08m4zo5iroWMklxL7U=";


          meta = with nixpkgs.lib;{
            homepage = "https://github.com/MAAF72/go-swagger";
            license = licenses.asl20; # apache license 2.0
            maintainers = with maintainers; [ MAAF72 ];
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # go 1.21 (specified by overlay)
            go

            # go lsp
            gopls

            # goimports, godoc, etc.
            gotools

            # https://github.com/golangci/golangci-lint
            golangci-lint

            # swagger
            maaf72-go-swagger
          ];

          shellHook = ''
            # allow for external dependency to be
            # install on nix os imperatively 
            # using `go install` when certain 
            # dependencies not available/outdated 
            # on nixpkgs
            export GOPATH="$(go env GOPATH)"
            export PATH="$PATH:$GOPATH/bin"

            ${pkgs.go}/bin/go version
          '';
        };
      });
}
