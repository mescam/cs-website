{
  description = "ZSR lecture slides (Typst) for Distributed Systems Management at PUT";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        typslidesPkg = pkgs.typstPackages.typslides_1_3_2;
        typstPackagePath = pkgs.linkFarm "typst-local-packages" {
          "preview/typslides/1.3.2" = "${typslidesPkg}/lib/typst-packages/typslides/1.3.2";
        };
      in rec {
        packages.document = pkgs.stdenvNoCC.mkDerivation {
          name = "ZSR-Lectures";
          src = self;
          nativeBuildInputs = [ pkgs.coreutils pkgs.typst pkgs.cacert pkgs.dejavu_fonts ];
          phases = [ "unpackPhase" "buildPhase" "installPhase" ];
          buildPhase = ''
            export PATH="${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.typst pkgs.cacert pkgs.dejavu_fonts ]}"
            mkdir -p .cache/typst
            export XDG_CACHE_HOME="$PWD/.cache"
            export TYPST_CACHE_DIR="$PWD/.cache/typst"
            export TYPST_PACKAGE_PATH="${typstPackagePath}"
            export TYPST_FONT_PATHS="${pkgs.dejavu_fonts}/share/fonts/truetype"
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

            for source in zsr-w*.typ; do
              test -f "$source"
              typst compile "$source" "''${source%.typ}.pdf"
            done
          '';
          installPhase = ''
            mkdir -p "$out"
            for source in zsr-w*.typ; do
              pdf="''${source%.typ}.pdf"
              test -f "$pdf"
              cp "$pdf" "$out/"
            done
          '';
        };
        defaultPackage = packages.document;
      });
}
