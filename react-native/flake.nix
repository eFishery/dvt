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
        # utility function for string replace 
        replace = rec {
          replacer = a: b: str:
            nixpkgs.lib.strings.stringAsChars (x: if x == a then b else x) str;
          dotToDash = replacer "." "-";
          semicolonToDash = replacer ";" "-";
          underscoreToDash = replacer "_" "-";
          withDoubleQuote = str: ''"${str}"'';
        };

        # react-native dependencies versions
        nodejsVersion = 18;
        javaVersion = 11;
        androidBuildToolsVersion = "33.0.0";
        androidPlatformsVersion = 33;
        androidNDKVersion = "23.1.7779620";

        # references https://gist.github.com/mrk-han/66ac1a724456cadf1c93f4218c6060ae
        createEmulator = pkgs:
          let
            inherit (pkgs.stdenv) isAarch64;
            arch = if isAarch64 then "arm64-v8a" else "x86_64";
            cpuArch = if isAarch64 then "arm64" else "x86_64";
          in
          rec
          {
            inherit cpuArch;
            name = "dvt_${toString androidPlatformsVersion}";
            abi.type = arch;
            packages = "system-images;android-${toString androidPlatformsVersion};${tag.id};${abi.type}";
            sysdir = "$ANDROID_SDK_ROOT/system-images/android-${toString androidPlatformsVersion}/${tag.id}/${abi.type}/";
            tag.id = "google_apis_playstore";
            avdRootPath = "$HOME/.android/avd";
            avdPath = "${avdRootPath}/${name}.avd";
            avdConfigIni = "${avdPath}/config.ini";
          };

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
            androidSdk = let emulator = createEmulator prev; in
              prev.androidSdk (s: [
                # common android sdk package
                s.platform-tools
                s.cmdline-tools-latest
                s.tools
                s.patcher-v4
                s.extras-google-google-play-services
                s.emulator
                # specified android sdk package version
                s."build-tools-${replace.dotToDash androidBuildToolsVersion}"
                s."ndk-${replace.dotToDash androidNDKVersion}"
                s."platforms-android-${toString androidPlatformsVersion}"
                s."${replace.underscoreToDash (replace.semicolonToDash emulator.packages)}"
              ]);
          })
        ];

        pkgs = import nixpkgs { inherit overlays system; };

        run = pkg: "${pkgs.${pkg}}/bin/${pkg}";

        scripts = let emulator = createEmulator pkgs; in
          with pkgs; [
            # help commands
            (writeScriptBin "helpme" ''
              __usage="
              👋 Welcome to react-native development environment. 🚀
              If you see this message, it means your are inside the Nix shell ❄️.

              [Info]===============================================================>
              Env:
                - JAVA_HOME:        $JAVA_HOME
                - ANDROID_HOME:     $ANDROID_HOME
                - ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT
                - ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT

              Android Emulator:
                - name:     ${emulator.name}
                - packages: ${emulator.packages} 

              Android SDK packages:
                - build-tools:        ${androidBuildToolsVersion}
                - platforms-android:  ${toString androidPlatformsVersion}
                - ndk:                ${androidNDKVersion}

              Command available:
                - start:            start the project 🛹
                - create-emulator:  create emulator (default: android)
                - align-emulator:   align dev environment with AVD configurations
                - gen-properties:   generate local.properties in <currentDir>/android
                - helpme:           show this messages

              Report/Help:
                - https://github.com/eFishery/dvt
              [Info]===============================================================>
              "
              echo "$__usage"
            '')

            # check dependencies
            (writeScriptBin "check-react-native" ''
              until ${run "yarn"} react-native -v > /dev/null 2>&1; do
                echo "install dependencies..."
                ${run "yarn"} install || (echo failed instll dependencies with yarn; exit 1)
                echo ""
                read -p "Do you want to create an android emulator? [y/n]: " __is_create_emulator
                [[ $__is_create_emulator == "y" ]] && create-emulator && align-emulator
                sleep 0.5
              done
            '')

            # align emulator configuration for sync system-images location and relateds.
            (writeScriptBin "align-emulator" ''
              [[ -f ${emulator.avdConfigIni} ]] && (
              cat <<EOF > ${emulator.avdConfigIni}
              PlayStore.enabled = enable
              abi.type = ${emulator.abi.type}
              avd.ini.encoding = UTF-8
              skin.name = 1080x1920
              hw.lcd.density = 480
              hw.keyboard = yes
              hw.cpu.arch = ${emulator.cpuArch}
              image.sysdir.1 = ${emulator.sysdir}
              tag.display = Google Play
              tag.id = ${emulator.tag.id}
              disk.dataPartition.size = 6442450944
              EOF
              echo "🚀 Updated emulator (${emulator.name}) configurations."
              )
            '')

            # create emulator
            (writeScriptBin "create-emulator" ''
              echo "no" | ${androidSdk}/bin/avdmanager \
                --clear-cache -s \
                create avd -f \
                -n ${emulator.name} \
                -p ${emulator.avdPath} \
                -g ${emulator.tag.id} \
                -b ${emulator.abi.type} \
                -k ${replace.withDoubleQuote emulator.packages} \
                || (echo "❌ Fail: to create emulator"; exit 1)
            '')

            # TODO: delete emulator
            # (writeScriptBin "delete-emulator" ''
            #   Try your self here!
            # '')

            # start react-native metro bundler
            (writeScriptBin "start" ''
              check-react-native
              align-emulator
              $PWD/node_modules/.bin/react-native start $@
            '')

            # gen-properties
            (writeScriptBin "gen-properties" ''
              cat <<EOF > ./android/local.properties
              sdk.dir=$ANDROID_SDK_ROOT
              ndk.dir=$ANDROID_NDK_ROOT
              EOF || (echo "are you sure in the right project directory?"; exit 1)
            '')
          ];

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

            # react-native development dependencies 
            watchman
          ] ++ scripts;

          ANDROID_NDK_ROOT = "${pkgs.androidSdk.outPath}/share/android-sdk/ndk/${androidNDKVersion}";

          shellHook = ''
            helpme
          '';
        };
      });
}

