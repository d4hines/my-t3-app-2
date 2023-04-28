{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.follows = "dream2nix/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    dream2nix,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      imports = [dream2nix.flakeModuleBeta];
      perSystem = {
        config,
        system,
        self',
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        # define an input for dream2nix to generate outputs for
        dream2nix.inputs."my-t3-app" = {
          source = ./.;
          projects = {
            my-t3-app = {
              subsystem = "nodejs";
              translator = "package-lock";
            };
          };
        };
        packages = config.dream2nix.outputs.my-t3-app.packages;
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodePackages.prettier
          ];
          shellHook = with pkgs; ''
            export PRISMA_MIGRATION_ENGINE_BINARY="${prisma-engines}/bin/migration-engine"
            export PRISMA_QUERY_ENGINE_BINARY="${prisma-engines}/bin/query-engine"
            export PRISMA_QUERY_ENGINE_LIBRARY="${prisma-engines}/lib/libquery_engine.node"
            export PRISMA_INTROSPECTION_ENGINE_BINARY="${prisma-engines}/bin/introspection-engine"
            export PRISMA_FMT_BINARY="${prisma-engines}/bin/prisma-fmt"
          '';
        };
      };
    };
}
