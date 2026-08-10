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
      # macOS account that owns this system — change this if your account name differs
      username = "bragur";

      configuration =
        { pkgs, config, ... }:
        {

          nixpkgs.config.allowUnfree = true;

          # Primary user for system-level options
          system.primaryUser = username;

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
            pkgs.btop
            pkgs.dust
            pkgs.delta
            pkgs.neovim
            pkgs.tmux
            pkgs.tmuxifier
            pkgs.mkalias # See comment below
            pkgs.typescript-language-server
            pkgs.typst
            pkgs.mise
            pkgs.nixfmt
            pkgs.ripgrep
            pkgs.gh
            pkgs.gum
            pkgs.sesh
            pkgs.terraform
            pkgs.tldr
            pkgs.fd
            pkgs.yazi
            pkgs.yq
            pkgs.jq
            pkgs.jqp
            pkgs.lld # provides ld64.lld (Mach-O linker) for Rust
            pkgs.carapace
            pkgs.chafa
            pkgs.antidote
            pkgs.mas
            pkgs.atuin
            pkgs.awscli2
            pkgs.cmatrix
            pkgs.rsync
            pkgs.shellcheck
            # GUI apps with auto-updaters are installed via Homebrew casks instead of Nix
            # because Nix's immutable store prevents in-place updates
          ];

          environment.pathsToLink = [ "/share/antidote" ];

          homebrew = {
            enable = true;
            taps = [ ];
            brews = [ ];
            casks = [
              "arc"
              "cleanshot"
              "claude"
              "figma"
              "ghostty"
              "google-chrome"
              "1password"
              "karabiner-elements"
              "linearmouse"
              "macdown-3000"
              "monitorcontrol"
              "obsidian"
              "pearcleaner"
              "qlmarkdown"
              "raycast"
              "slack"
              "sonos"
              "spotify"
              "tailscale-app"
              "visual-studio-code"
            ];
            # masApps disabled — nix-darwin#1722: brew bundle changed mas install → mas get
            # Amphetamine (937984704) is installed via App Store directly
            masApps = { };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          fonts.packages = [
            pkgs.inter
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
                pathsToLink = [ "/Applications" ];
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
              sudo -u ${username} defaults write com.apple.dock persistent-others -array \
                ${mkFolder "/Users/${username}/Pictures/Screenshots" 2} \
                ${mkFolder "/Users/${username}/Downloads" 2} \
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
          # Determinate Nix runs its own daemon and manages the Nix install itself;
          # nix-darwin's own Nix management conflicts with it and aborts activation
          # ("Determinate detected, aborting activation") unless disabled here.
          nix.enable = false;

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
      # The config is machine-agnostic; every machine builds the same system.
      darwinSystem = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # Apple Silicon Only
              enableRosetta = false;
              # User owning the Homebrew prefix
              user = username;
            };
          }
        ];
      };
    in
    {
      # Build darwin flake using either name (both point at the same config):
      # $ darwin-rebuild build --flake .#main
      # $ darwin-rebuild build --flake .#air
      darwinConfigurations."main" = darwinSystem;
      darwinConfigurations."air" = darwinSystem;
    };
}
