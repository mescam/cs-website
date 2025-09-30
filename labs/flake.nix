{
  description = "Lab scripts for Distributed Systems Management at PUT";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
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
            buildInputs = [ pkgs.coreutils tex ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              mkdir -p .cache/texmf-var
              for i in *.tex; do
                env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
                  latexmk -interaction=nonstopmode -pdf -lualatex \
                  $i
              done;
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
