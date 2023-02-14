{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: {

    templates = {
      go = {
        path = ./go;
        description = "Go development environment";
      };

      node = {
        path = ./node;
        description = "Nodejs development environment";
      };

      node14 = {
        path = ./node14;
        description = "Nodejs (v14) and pnpm (v5) development environment";
      };

      react-native = {
        path = ./react-native;
        description = "React Native development environment";
      };
    };

  } // utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs) mkShell writeScriptBin;
      run = pkg: "${pkgs.${pkg}}/bin/${pkg}";

      dvt = writeScriptBin "dvt" ''
        if [ -z $1 ]; then
          echo "no template specified"
          exit 1
        fi
        TEMPLATE=$1
        ${run "nix"} \
          --experimental-features 'nix-command flakes' \
          flake init \
          --template \
          "github:efishery/dvt#''${TEMPLATE}"
      '';

      format = writeScriptBin "format" ''
        ${run "nixpkgs-fmt"} **/*.nix
      '';

      update = writeScriptBin "update" ''
        for dir in `ls -d */`; do
          (
            cd $dir
            ${run "nix"} flake update # Update flake.lock 
            ${run "nix"} develop $dir # Make sure this work after update
          )
        done
      '';

    in
    {
      devShells.default = mkShell { buildInputs = [ format update ]; };

      packages = {
        default = dvt;
        inherit dvt;
      };
    });
}
