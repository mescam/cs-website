{
  description = "PSR lecture slides (Typst) for Distributed Systems Design at PUT";
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
        packages = {
          document = pkgs.stdenvNoCC.mkDerivation rec {
            name = "PSR-Lectures";
            src = self;
            buildInputs = [ pkgs.coreutils pkgs.typst pkgs.cacert ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              export HOME="$PWD"
              mkdir -p .cache/typst
              export XDG_CACHE_HOME="$PWD/.cache"
              export TYPST_CACHE_DIR="$PWD/.cache/typst"
              export TYPST_PACKAGE_PATH="${typstPackagePath}"
              export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

              for i in psr-w*.typ; do
                typst compile "$i" "$(basename "$i" .typ).pdf"
              done
            '';
            installPhase = ''
              mkdir -p $out
              cp *.pdf $out/
            '';
          };
        };
        defaultPackage = packages.document;
      });
}
