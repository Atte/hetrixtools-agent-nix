{
  inputs = {
    nixpkgs.url = "nixpkgs";

    flake-utils.url = "flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }: {
    nixosModules.default = import ./module.nix;
    overlays.default = final: prev: {
      hetrixtools-agent = self.packages.${prev.system}.default;
    };
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      # TODO: turn into overridable parameters
      checkDriveHealth = true;
      checkSoftRAID = true;
    in
    {
      packages.default = pkgs.stdenv.mkDerivation rec {
        pname = "hetrixtools-agent";
        version = "2.2.7";

        src = pkgs.fetchFromGitHub {
          owner = "hetrixtools";
          repo = "agent";
          rev = "571cd846014c0fda423ec1ae635b09627d783a97";
          hash = "sha256-Aw/xBa8MfVjHGh1/8hhozoqrPdQl9Ah2Eqb+9spXo+Q=";
        };

        buildInputs = with pkgs; ([
          coreutils
          util-linux
          findutils
          procps
          gawk
          wget
          gnugrep
          gnused
          gzip
          iproute2
        ] ++ lib.optionals checkDriveHealth [
          smartmontools
          nvme-cli
        ] ++ lib.optionals checkSoftRAID [
          mdadm
          zfs
        ]);
        nativeBuildInputs = [ pkgs.makeWrapper ];

        patches = [
          ./patches/configfile.patch
          ./patches/paths.patch
        ];

        buildPhase = ''
          chmod +x -- *.sh
        '';

        installPhase = ''
          mkdir -p -- "$out/bin"
          cp -- hetrixtools_agent.sh "$out/bin/"
        '';

        postFixup = ''
          wrapProgram "$out/bin/hetrixtools_agent.sh" \
            --set PATH '${pkgs.lib.makeBinPath buildInputs}'
        '';
      };

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
        ];
      };
    });
}
