{
  description = "A flake for building and running the 1MCP agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      home-manager,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.callPackage ./package.nix { };

        checks = {
          version =
            pkgs.runCommand "verify-version"
              {
                buildInputs = [ self.packages.${system}.default ];
              }
              ''
                1mcp --help > $out
              '';

          homeManagerTest = pkgs.testers.nixosTest (
            (import ./tests/home-manager-test.nix {
              inherit self;
              home-manager = home-manager;
            })
              pkgs
          );

          nixosTest = pkgs.testers.nixosTest ((import ./tests/nixos-test.nix { inherit self; }) pkgs);
        };
      }
    )
    // {
      nixosModules.onemcp = import ./nixos-module.nix { inherit self; };
      nixosModules.default = self.nixosModules.onemcp;
      homeModules.onemcp = import ./home-module.nix { inherit self; };
      homeModules.default = self.homeModules.onemcp;
    };
}
