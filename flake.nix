{
  description = "A Nix-flake-based Elixir development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
      });
    in
    {
      overlays.default = final: prev: rec {
        # documentation
        # https://nixos.org/manual/nixpkgs/stable/#sec-beam

        # ==== ERLANG ====

        # use whatever version is currently defined in nixpkgs
        # erlang = pkgs.beam.interpreters.erlang;

        # use latest version of Erlang 27
        erlang = final.beam.interpreters.erlang_25;

        # specify exact version of Erlang OTP
        # erlang = pkgs.beam.interpreters.erlang.override {
        #   version = "26.2.2";
        #   sha256 = "sha256-7S+mC4pDcbXyhW2r5y8+VcX9JQXq5iEUJZiFmgVMPZ0=";
        # }

        # ==== BEAM packages ====

        # all BEAM packages will be compile with your preferred erlang version
        pkgs-beam = final.beam.packagesWith erlang;

        # ==== Elixir ====

        # use whatever version is currently defined in nixpkgs
        # elixir = pkgs-beam.elixir;

        # use latest version of Elixir 1.17
        elixir = pkgs-beam.elixir_1_14;

        # specify exact version of Elixir
        # elixir = pkgs-beam.elixir.override {
        #   version = "1.17.1";
        #   sha256 = "sha256-a7A+426uuo3bUjggkglY1lqHmSbZNpjPaFpQUXYtW9k=";
        # };
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # use the Elixr/OTP versions defined above; will also install OTP, mix, hex, rebar3
            elixir
            
            postgresql_15

            # mix needs it for downloading dependencies
            git

            # probably needed for your Phoenix assets
            nodejs_20
          ]
          ++
          # Linux only
          pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
            gigalixir
            inotify-tools
            libnotify
          ])
          ++
          # macOS only
          pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
            terminal-notifier
            darwin.apple_sdk.frameworks.CoreFoundation
            darwin.apple_sdk.frameworks.CoreServices
          ]);

          shellHook = ''
            # limit mix to current project
            mkdir -p .nix-mix
            export MIX_HOME=$PWD/.nix-mix

            # rewire executables
            export PATH=$MIX_HOME/bin:$PATH
            export PATH=$MIX_HOME/escripts:$PATH

            # limit history to current project
            export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_path '\"$PWD/.erlang-history\"'"
          '';
        };
      });
    };
}