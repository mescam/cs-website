{
  description =
    "Academic website of Jakub Wozniak at Poznan University of Technology";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, utils, ... }:
    utils.lib.eachSystem [
      utils.lib.system.x86_64-darwin
      utils.lib.system.x86_64-linux
      utils.lib.system.aarch64-darwin
      utils.lib.system.aarch64-linux
    ] (system:
      let pkgs = import nixpkgs { inherit system; };
      in rec {
        packages.website = pkgs.stdenv.mkDerivation {
          name = "website";
          src = self;
          buildInputs = [ pkgs.git ];
          buildPhase = ''
            ${pkgs.hugo}/bin/hugo --minify --baseURL "//www.cs.put.poznan.pl/jwozniak/"
          '';
          installPhase = "cp -r public $out";
        };

        defaultPackage = self.packages.${system}.website;

        apps = rec {
          hugo = utils.lib.mkApp { drv = pkgs.hugo; };
          default = hugo;
        };

        devShell =
          pkgs.mkShell { buildInputs = [ pkgs.nixpkgs-fmt pkgs.hugo ]; };
      });
}
