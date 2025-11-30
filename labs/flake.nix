{
  description = "Lab scripts for Distributed Systems Management at PUT";
  inputs = {
    # Older, known-good nixpkgs for LaTeX / TeX Live
    nixpkgs.url = "github:NixOS/nixpkgs/5633bcff0c6162b9e4b5f1264264611e950c8ec7";
    # Newer nixpkgs solely to get a recent Typst
    typst-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, typst-nixpkgs }:
    with flake-utils.lib;
    eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        typstPkgs = typst-nixpkgs.legacyPackages.${system};
        tex = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-medium latex-bin latexmk curve fontawesome5 silence
            simpleicons relsize comment biblatex csquotes cochineal xstring
            cabin inconsolata upquote xurl fancyvrb xcolor listings listingsutf8;
        };

        # Vendored Typst universe packages for offline builds.
        # Layout must match: typst/packages/preview/{name}-{version}
        typstUniverseCache = pkgs.stdenvNoCC.mkDerivation {
          name = "typst-universe-cache";
          src = pkgs.fetchurl {
            url = "https://packages.typst.org/preview/rubber-article-0.5.0.tar.gz";
            sha256 = "sha256-SAv/422FDuMIglR4xgCXq6pDlb4C2p9M3k37qBh1ih0=";
          };
          phases = [ "unpackPhase" "installPhase" ];
          unpackPhase = ''
            mkdir -p source
            tar -xzf "$src" -C source
          '';
          installPhase = ''
            mkdir -p "$out/typst/packages/preview/rubber-article-0.5.0"
            cp -R source/* "$out/typst/packages/preview/rubber-article-0.5.0/"
          '';
        };
      in rec {
        packages = {
          document = pkgs.stdenvNoCC.mkDerivation rec {
            name = "LaTeX-Build";
            src = self;
            buildInputs = [ pkgs.coreutils tex typstPkgs.typst pkgs.cacert ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              export HOME="$PWD"
              mkdir -p .cache/texmf-var
              mkdir -p .cache/texmf-var/fonts
              mkdir -p .cache/typst
              export XDG_CACHE_HOME="$PWD/.cache"
              export TEXMFVAR="$PWD/.cache/texmf-var"

              # Point Typst to a pre-populated, offline universe cache.
              export TYPST_CACHE_DIR="$PWD/.cache/typst"
              export TYPST_PACKAGE_CACHE_PATH="${typstUniverseCache}/typst/packages"
              export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

              # Build all LaTeX lab documents
              for i in *.tex; do
                env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
                  latexmk -interaction=nonstopmode -pdf -lualatex \
                  "$i"
              done

              # Build all Typst lab documents
              for i in *.typ; do
                typst compile "$i" "$(basename "$i" .typ).pdf"
              done
            '';

            installPhase = ''
              mkdir -p $out
              cp *.pdf $out/
            '';
          };

          typst-docs = pkgs.stdenvNoCC.mkDerivation rec {
            name = "Typst-Build";
            src = self;
            buildInputs = [ pkgs.coreutils typstPkgs.typst pkgs.cacert ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              mkdir -p .cache/typst
              export XDG_CACHE_HOME="$PWD/.cache"

              # Use the same offline universe cache here.
              export TYPST_CACHE_DIR="$PWD/.cache/typst"
              export TYPST_PACKAGE_CACHE_PATH="${typstUniverseCache}/typst/packages"
              export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

              for i in *.typ; do
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
