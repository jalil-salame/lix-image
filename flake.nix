{
  description = "A starting point for your devshell";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.lix.systems"
    ];
    extra-trusted-public-keys = [
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    lix,
    ...
  }: let
    lixImage = pkgs: pkgs.callPackage (import (lix + "/docker.nix")) {inherit pkgs;};
    allSystems = import systems;
    forEachSystem = f:
      nixpkgs.lib.genAttrs allSystems (system:
        f {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
        });
  in {
    # Nix code formatter; I like alejandra, but nixpkgsfmt, nixfmt-classic, and nixfmt-rfc-style also exist
    formatter = forEachSystem ({pkgs, ...}: pkgs.alejandra);
    # Packages exported by this flake
    packages = forEachSystem ({
      pkgs,
      system,
    }: {
      default = self.packages.${system}.lixImage;
      lixImage = lixImage pkgs;
    });
    devShells = forEachSystem ({pkgs, ...}: {
      default = pkgs.mkShell {packages = [];};
    });
  };
}
