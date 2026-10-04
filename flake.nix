{
  description = "bunless Hare development environment";

  inputs.nixpkgs.url = "github:Nixos/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.callPackage ./nix/package.nix { };
          nxinit = self.packages.${system}.default;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              hare
              harec
              qbe
              haredoc
              hare-lsp
            ];

            HAREPATH = "${pkgs.hare}/src/hare/stdlib";

            shellHook = ''
              echo "entering bunless Hare development environment"
              hare version
            '';
          };
        }
      );
    };
}
