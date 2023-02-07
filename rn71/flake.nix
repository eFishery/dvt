{
  description = "A Nix-flake-based React Native development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    android-nixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, android-nixpkgs, utils }:

    utils.lib.eachDefaultSystem (system:
      let
        nodejsVersion = 18;
        javaVersion = 11;
        androidBuildToolsVersion = "30.0.3";
        androidPlatformsVersion = 33;
        androidNDKVersion = "23.1.7779620";
        androidArch = pkgs:
          if pkgs.stdenv.isAarch64 then "arm64-v8a" else "x86-64";
        replaceDotToDash = str:
          nixpkgs.lib.strings.stringAsChars (x: if x == "." then "-" else x) str;

        overlays = [
          android-nixpkgs.overlays.default
          (final: prev: rec {
            nodejs = prev."nodejs-${toString nodejsVersion}_x";
            yarn = prev.yarn.override { inherit nodejs; };
            jdk = pkgs."jdk${toString javaVersion}";
            gradle = prev.gradle.override {
              java = jdk;
            };
            ruby = prev.ruby.withPackages (p: [ p.cocoapods ]);
            androidSdk = prev.androidSdk (s: [
              # common android sdk package
              s.platform-tools
              s.cmdline-tools-latest
              s.tools
              s.patcher-v4
              s.extras-google-google-play-services
              s.emulator

              # specified android sdk package version
              s."platforms-android-${toString androidPlatformsVersion}"
              s."build-tools-${replaceDotToDash androidBuildToolsVersion}"
              s."system-images-android-${toString androidPlatformsVersion}-google-apis-playstore-${androidArch prev}"
              s."ndk-${replaceDotToDash androidNDKVersion}"
            ]);
          })
        ];

        pkgs = import nixpkgs { inherit overlays system; };

        run = pkg: "${pkgs.${pkg}}/bin/${pkg}";

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # nodejs 18 (specified by overlay)
            nodejs

            # yarn with nodejs 18 (specified by overlay)
            yarn

            # java 11 (specified by overlay)
            jdk

            # gradle with java 11 (specified by overlay)
            gradle

            # ruby with cocoapods (specified by overlay)
            ruby

            # androidSdk (specified by overlay)
            androidSdk
          ];

          shellHook = ''
            export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/${androidNDKVersion} 
            echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
            echo "ANDROID_HOME=$ANDROID_HOME"
            echo "ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"
            echo "build-tools-${androidBuildToolsVersion}"
            echo nodejs $(${pkgs.nodejs}/bin/node --version)
            echo yarn $(${run "yarn"} --version)
            ${run "ruby"} --version
            ${run "gradle"} --version
          '';
        };
      });
}

