{
  description = "Bragi's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # mac-app-util.url = "github:hraban/mac-app-util"; # Check this out
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      ...
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {

          nixpkgs.config.allowUnfree = true;

          # Primary user for system-level options
          system.primaryUser = "bragur";

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.zsh
            pkgs.oh-my-posh
            pkgs.stow
            pkgs.fzf
            pkgs.zoxide
            pkgs.eza
            pkgs.bat
            pkgs.autojump
            pkgs.neovim
            pkgs.tmux
            pkgs.tmuxifier
            pkgs.mkalias # See comment below
            pkgs.obsidian
            pkgs.slack
            pkgs.vscode
            pkgs.mise
            pkgs.nixfmt-rfc-style
            pkgs.ripgrep
            pkgs.raycast
            pkgs.gh
            pkgs.gum
            pkgs.sesh
            pkgs.fd
            pkgs.claude-code
            # 1Password and Ghostty are installed via Homebrew casks instead of Nix
            # because they need better macOS integration (Touch ID, system keychain, etc.)
          ];

          homebrew = {
            enable = true;
            brews = [
              "antidote"
              "mas"
            ];
            casks = [
              "cursor"
              "ghostty"
              "1password"
              "hyperkey"
            ];
            masApps = {
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          # fonts.packages = [
          #   pkgs.maple-mono.NF
          # ];

          # Create macOS aliases for Nix-installed GUI apps in /Applications/Nix Apps/
          # mkalias creates native macOS aliases (not symlinks) so that:
          # - Spotlight can find them
          # - Dock can pin them
          # - LaunchServices recognizes them for file associations
          # Without this, Nix apps in the store would be invisible to macOS
          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
                        # Set up applications.
                        echo "Setting up /Applications..." >&2
                        rm -rf /Applications/Nix\ Apps
              	  mkdir -p /Applications/Nix\ Apps
                        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              	  while read -r src; do
                          app_name=$(basename "$src")
                          echo "copying $src" >&2
                          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
                        done
              	'';

          system.defaults = {
            dock.autohide = true;
            dock.mru-spaces = false;
            dock.show-recents = false;
            dock.minimize-to-application = true;
            dock.persistent-apps = [];
            dock.persistent-others = [
              "/Users/bragur/Pictures/Screenshots"
              "/Users/bragur/Downloads"
              "/Applications"
            ];
            finder.FXPreferredViewStyle = "clmv";
            finder.ShowPathbar = true;
            finder.ShowStatusBar = true;
            loginwindow.GuestEnabled = false;
            screencapture.location = "~/Pictures/Screenshots";
            NSGlobalDomain.ApplePressAndHoldEnabled = false;
            NSGlobalDomain.InitialKeyRepeat = 15;
            NSGlobalDomain.KeyRepeat = 2;
            NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
            NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
            screensaver.askForPassword = true;
            screensaver.askForPasswordDelay = 60;
          };
          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#air
      darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # Apple Silicon Only
              enableRosetta = true;
              # User owning the Homebrew prefix
              user = "bragur";
            };
          }
        ];
      };
    };
}
