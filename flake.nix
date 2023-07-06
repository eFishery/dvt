{
  description = "Ready-made templates for easily creating flake-driven environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: {

    overlay = final: prev:
      let scripts = prev.callPackage ./scripts.nix { }; in
      {
        inherit (scripts) format update test-develop dvt;
      };

    templates = import ./templates.nix;

  } // utils.lib.eachDefaultSystem (system:
    let
      overlays = [ (self.overlay) ];
      pkgs = import nixpkgs { inherit system overlays; };
    in
    {
      devShells.default = pkgs.mkShell { buildInputs = with pkgs; [ format update ]; };

      packages = {
        dvt-init = pkgs.dvt;
        dvt-format = pkgs.format;
        dvt-update = pkgs.update;
        inherit (pkgs) test-develop;
      };
    });
}
