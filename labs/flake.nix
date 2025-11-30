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
      in rec {
        packages = {
          document = pkgs.stdenvNoCC.mkDerivation rec {
            name = "LaTeX-Build";
            src = self;
            buildInputs = [ pkgs.coreutils tex typstPkgs.typst ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              export HOME="$PWD"
              mkdir -p .cache/texmf-var
              mkdir -p .cache/texmf-var/fonts
              mkdir -p .cache/typst
              export XDG_CACHE_HOME="$PWD/.cache"
              export TEXMFVAR="$PWD/.cache/texmf-var"

              export TYPST_CACHE_DIR="$PWD/.cache/typst"
              export TYPST_PACKAGE_CACHE_PATH="$PWD/.cache/typst"

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
            buildInputs = [ pkgs.coreutils typstPkgs.typst ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              mkdir -p .cache/typst
              export XDG_CACHE_HOME="$PWD/.cache"
              export TYPST_CACHE_DIR="$PWD/.cache/typst"
              export TYPST_PACKAGE_CACHE_PATH="$PWD/.cache/typst"
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
