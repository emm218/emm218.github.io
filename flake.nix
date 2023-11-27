{
  description = "Personal website for Emmy Alme";

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
    ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        rec {

          formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
          packages.website = pkgs.stdenv.mkDerivation {
            name = "website";
            src = self;
            buildInputs = [ pkgs.git pkgs.nodePackages.prettier ];
            buildPhase = ''
              sed -i -e 's/enableGitInfo = true/enableGitInfo = false/' config.toml
              ${pkgs.hugo}/bin/hugo
            '';
            installPhase = "cp -r public $out";
          };

          defaultPackage = self.packages.${system}.website;

          apps = rec {
            hugo = utils.lib.mkApp { drv = pkgs.hugo; };
            default = hugo;
          };

          devShell =
            pkgs.mkShell {
              buildInputs = [ pkgs.nixpkgs-fmt pkgs.hugo ];

              shellHook = ''
                exec zsh
              '';
            };
        });
}
