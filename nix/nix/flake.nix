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
            pkgs.neovim
            pkgs.tmux
            pkgs.tmuxifier
            pkgs.mkalias # See comment below
            pkgs.typst
            pkgs.mise
            pkgs.nixfmt-rfc-style
            pkgs.ripgrep
            pkgs.gh
            pkgs.gum
            pkgs.sesh
            pkgs.fd
            pkgs.yazi
            pkgs.yq
            pkgs.jq
            pkgs.jqp
            pkgs.carapace
            pkgs.chafa
            pkgs.antidote
            pkgs.mas
            pkgs.atuin
            pkgs.cmatrix
            pkgs.rsync
            # GUI apps with auto-updaters are installed via Homebrew casks instead of Nix
            # because Nix's immutable store prevents in-place updates

            # Work
            pkgs.openssl
            pkgs.pkg-config
            pkgs.shellcheck # Bottega
          ];

          environment.pathsToLink = [ "/share/antidote" ];

          homebrew = {
            enable = true;
            taps = [
              "schpet/tap"
            ];
            brews = [
              "schpet/tap/linear"
            ];
            casks = [
              "arc"
              "cleanshot"
              "claude"
              "cursor"
              "dbeaver-community"
              "figma"
              "ghostty"
              "google-chrome"
              "1password"
              "hyperkey"
              "macdown-3000"
              "monitorcontrol"
              "obsidian"
              "raycast"
              "slack"
              "sonos"
              "spotify"
              "tailscale-app"
              "visual-studio-code"

              # Work
              "docker-desktop"
            ];
            masApps = {
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          fonts.packages = [
            pkgs.maple-mono.NF
          ];

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

          # Configure dock folder stacks with sort order (arrangement: 1=Name, 2=Date Added)
          # nix-darwin's persistent-others only accepts paths (no sort options),
          # so we write the full tile-data via defaults write and omit persistent-others
          # from system.defaults to avoid conflicts
          system.activationScripts.dockFolders.text =
            let
              mkFolder = path: arrangement:
                "'<dict><key>tile-data</key><dict>"
                + "<key>arrangement</key><integer>${toString arrangement}</integer>"
                + "<key>file-data</key><dict>"
                + "<key>_CFURLString</key><string>file://${path}/</string>"
                + "<key>_CFURLStringType</key><integer>15</integer>"
                + "</dict>"
                + "<key>file-type</key><integer>2</integer>"
                + "</dict><key>tile-type</key><string>directory-tile</string></dict>'";
            in
            ''
              echo "Configuring dock folders..." >&2
              sudo -u bragur defaults write com.apple.dock persistent-others -array \
                ${mkFolder "/Users/bragur/Pictures/Screenshots" 2} \
                ${mkFolder "/Users/bragur/Downloads" 2} \
                ${mkFolder "/Applications" 1}
              killall Dock 2>/dev/null || true
            '';

          system.defaults = {
            dock.autohide = true;
            dock.mru-spaces = false;
            dock.show-recents = false;
            dock.minimize-to-application = false;
            dock.persistent-apps = [ ];
            # persistent-others is handled by activationScripts.dockFolders
            # (supports sort order, which the dock module doesn't)
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

          # Completion is handled by .zshrc (compinit -C -u) with caching
          programs.zsh.enableCompletion = false;

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
              enableRosetta = false;
              # User owning the Homebrew prefix
              user = "bragur";
            };
          }
        ];
      };

      # Mac Mini M4 Pro — same config as air for now
      darwinConfigurations."main" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = "bragur";
            };
          }
        ];
      };
    };
}
