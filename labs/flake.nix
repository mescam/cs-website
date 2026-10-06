{
  description = "Lab scripts for Distributed Systems Management at PUT";
  inputs = {
    # Older, known-good nixpkgs for LaTeX / TeX Live
    nixpkgs.url = "github:NixOS/nixpkgs/5633bcff0c6162b9e4b5f1264264611e950c8ec7";
    # Newer nixpkgs solely to get a recent Typst (and Typst packages)
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

        # Expose rubber-article 0.4.2 and its dependencies as local packages
        rubberArticlePkg = typstPkgs.typstPackages.rubber-article_0_4_2;
        hydraPkg         = typstPkgs.typstPackages.hydra_0_6_1;
        oxifmtPkg        = typstPkgs.typstPackages.oxifmt_0_2_1;
        pillarPkg        = typstPkgs.typstPackages.pillar_0_3_1;
        zeroPkg          = typstPkgs.typstPackages.zero_0_3_2;

        typstPackagePath = pkgs.linkFarm "typst-local-packages" {
          # Layout: preview/<name>/<version>
          "preview/rubber-article/0.4.2" = "${rubberArticlePkg}/lib/typst-packages/rubber-article/0.4.2";
          "preview/hydra/0.6.1"          = "${hydraPkg}/lib/typst-packages/hydra/0.6.1";
          "preview/oxifmt/0.2.1"         = "${oxifmtPkg}/lib/typst-packages/oxifmt/0.2.1";
          "preview/pillar/0.3.1"         = "${pillarPkg}/lib/typst-packages/pillar/0.3.1";
          "preview/zero/0.3.2"           = "${zeroPkg}/lib/typst-packages/zero/0.3.2";
        };
      in rec {
        packages = {
          ansible-student = pkgs.stdenvNoCC.mkDerivation {
            name = "zsr-ansible-student";
            src = self;
            nativeBuildInputs = [ pkgs.bash pkgs.coreutils pkgs.zip typstPkgs.typst ];
            phases = [ "unpackPhase" "buildPhase" "installPhase" ];
            buildPhase = ''
              export STUDENT_FONT_PATH="${typstPkgs.dejavu_fonts}/share/fonts/truetype"
              bash build-student-ansible.sh
              mkdir -p package/materialy
              cp -R draft/materialy/ansible package/materialy/ansible
              (cd package && zip -qr "$PWD/ansible-materialy.zip" materialy/ansible)
            '';
            installPhase = ''
              install -Dm644 0-ansible.pdf "$out/0-ansible.pdf"
              install -Dm644 package/ansible-materialy.zip "$out/ansible-materialy.zip"
            '';
          };

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

              # Use a local package path for Typst packages (@preview/...)
              export TYPST_CACHE_DIR="$PWD/.cache/typst"
              export TYPST_PACKAGE_PATH="${typstPackagePath}"

              export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              export SSL_CERT_DIR="${pkgs.cacert}/etc/ssl/certs"

              # Ansible uses the top-level Typst source. Teacher notes,
              # solutions and test artifacts are not publication inputs.
              cp ${packages.ansible-student}/0-ansible.pdf ./0-ansible.pdf

              # Keep the remaining existing lab documents.
              for i in *.tex; do
                if [ "$i" = "0-ansible.tex" ]; then continue; fi
                env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
                  latexmk -interaction=nonstopmode -pdf -lualatex \
                  "$i"
              done

              # Build all Typst lab documents
              for i in *.typ; do
                if [ "$i" = "0-ansible.typ" ]; then continue; fi
                typst compile "$i" "$(basename "$i" .typ).pdf"
              done
            '';

            installPhase = ''
              mkdir -p $out
              # Only top-level PDFs: never copy draft/ or teacher/ recursively.
              cp *.pdf $out/
              cp ${packages.ansible-student}/ansible-materialy.zip $out/
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

              # Same local package path here
              export TYPST_CACHE_DIR="$PWD/.cache/typst"
              export TYPST_PACKAGE_PATH="${typstPackagePath}"
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
