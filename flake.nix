{
  description = "A starting point for your devshell";

  inputs = {
    nixpkgs.follows = "lix/nixpkgs";
    systems.url = "github:nix-systems/default";
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/2.90-beta.1.tar.gz";
      inputs.nixpkgs-regression.follows = "";
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
  }: let
    lixImage = system: lix.packages.${system}.dockerImage;
    allSystems = import systems;
    forEachSystem = nixpkgs.lib.genAttrs allSystems;
    nixpkgsFor = forEachSystem (system:
      import nixpkgs {
        inherit system;
        overlays = [lix.overlays.default];
      });
  in {
    # Nix code formatter; I like alejandra, but nixpkgsfmt, nixfmt-classic, and nixfmt-rfc-style also exist
    formatter = forEachSystem (system: nixpkgsFor.${system}.alejandra);
    # Packages exported by this flake
    packages = forEachSystem (system: {
      default = self.packages.${system}.lixImage;
      lixImage = lixImage system;
    });
    devShells = forEachSystem (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShellNoCC {packages = [];};
    });
  };
}
