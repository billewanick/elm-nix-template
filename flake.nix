{
  description = "Template for an Elm app defined by a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-22.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        debugMode = false;
      in
      {
        packages.elm-nix-template = pkgs.stdenv.mkDerivation {
          name = "elm-nix-template";
          version = "0.1.0";
          src = ./.;

          buildInputs = with pkgs.elmPackages; [
            elm
            pkgs.nodePackages.uglify-js
          ];

          configurePhase = pkgs.elmPackages.fetchElmDeps {
            elmVersion = "0.19.1";
            elmPackages = import ./nix/elm-srcs.nix;
            registryDat = ./nix/registry.dat;
          };

          buildPhase =
            if debugMode then ''
              elm make src/Main.elm --debug --output=$out/debug.js
            '' else ''
              elm make src/Main.elm --output=$out/main.js --optimize
              uglifyjs $out/main.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
                | uglifyjs --mangle --output $out/main.min.js
              rm $out/main.js
            '';

          installPhase = ''
            mkdir -p $out
            cp public/main.css $out

            ${if debugMode then ''
              cp public/index.debug.html $out/index.html
            ''
            else ''
              cp public/index.html       $out
            ''}
          '';
        };

        packages.default = self.packages.${system}.elm-nix-template;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs;
            [
              elmPackages.elm
              elmPackages.nodejs
              elmPackages.elm-xref
              elmPackages.elm-test
              elmPackages.elm-live
              elmPackages.elm-json
              elmPackages.elm-review
              elmPackages.elm-format
              elmPackages.elm-upgrade
              elmPackages.elm-analyse
              elmPackages.elm-language-server

              elm2nix
            ];
        };
      });
}
