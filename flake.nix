{
  description = "nxinit development environment";

  inputs.nixpkgs.url = "github:Nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
  in {
    devShells = forAllSystems (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            hare
            harec
            qbe
            haredoc
          ];

          HAREPATH = "${pkgs.hare}/src/hare/stdlib";

          shellHook = ''
            echo "launched nxinit development environment"
            hare version
          '';
        };
      }
    );
  };
}
