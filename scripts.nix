{ writeScriptBin, nix, nixpkgs-fmt }:
{
  update = writeScriptBin "update"
    ''
      for dir in `ls -d */`; do
        (
          cd $dir
          ${nix}/bin/nix flake update # Update flake.lock 
          ${nix}/bin/nix develop $dir # Make sure this work after update
        )
      done
    '';

  test-develop = writeScriptBin "test-develop"
    ''
      for dir in `ls -d */`; do
        (
          ${nix}/bin/nix develop $dir # Make sure this work after update
          [[ "$dir" == "react-native/" ]] && ${nix}/bin/nix develop $dir -c create-emulator
          sleep 0.2
        )
      done
    '';

  format = writeScriptBin "format"
    ''
      ${nixpkgs-fmt}/bin/nixpkgs-fmt **/*.nix
    '';

  dvt = writeScriptBin "dvt"
    ''
      if [ -z $1 ]; then
        echo "no template specified"
        exit 1
      fi
      TEMPLATE=$1
      ${nix}/bin/nix \
        --experimental-features 'nix-command flakes' \
        flake init \
        --template \
        "github:efishery/dvt#''${TEMPLATE}"
    '';
}

