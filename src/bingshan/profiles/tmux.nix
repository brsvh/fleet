{
  home,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mapAttrs
    ;

  # Subsets of the Modus tinted palettes.
  palettes = {
    dark = {
      bg-active = "#484d67";
      bg-dim = "#1d2235";
      bg-highlight = "#303a6f";
      bg-main = "#0d0e1c";
      bg-popup = "#14162c";
      bg-region = "#555a66";
      blue = "#2fafff";
      border = "#61647a";
      cyan = "#00d3d0";
      fg-dim = "#989898";
      fg-main = "#ffffff";
      green = "#44bc44";
      magenta = "#feacd0";
      red = "#ff5f59";
      yellow = "#d0bc00";
    };

    light = {
      bg-active = "#cab9b2";
      bg-dim = "#efe9dd";
      bg-highlight = "#f1d5d0";
      bg-main = "#fbf7f0";
      bg-popup = "#f6eddd";
      bg-region = "#c2bcb5";
      blue = "#0031a9";
      border = "#9f9690";
      cyan = "#00598b";
      fg-dim = "#595959";
      fg-main = "#000000";
      green = "#006300";
      magenta = "#721045";
      red = "#a60000";
      yellow = "#6d5000";
    };
  };

  themes = mapAttrs (
    name: palette:
    pkgs.writeText "tmux-modus-${name}.conf" ''
      set -s theme ${name}

      set -g status-style 'fg=${palette.fg-main},bg=${palette.bg-dim}'
      set -g status-left '#[fg=${palette.blue},bold] #S #[default] '
      set -g status-right '#{?client_prefix,#[fg=${palette.blue}]PREFIX #[default],}#{?#{==:#{pane_mode},copy-mode},COPY ,}#{?window_zoomed_flag,ZOOM ,}#{?pane_synchronized,#[fg=${palette.red}]SYNC #[default],} #h  %H:%M '
      setw -g window-status-style 'fg=${palette.fg-dim},bg=${palette.bg-dim}'
      setw -g window-status-current-style 'fg=${palette.fg-main},bg=${palette.bg-active},bold'
      setw -g window-status-bell-style 'fg=${palette.red},bold'
      setw -g window-status-activity-style 'fg=${palette.blue},bold'
      setw -g pane-border-style 'fg=${palette.border}'
      setw -g pane-active-border-style 'fg=${palette.blue}'
      setw -g pane-scrollbars-style 'fg=${palette.border},bg=${palette.bg-dim}'
      setw -g mode-style 'fg=${palette.fg-main},bg=${palette.bg-region}'
      setw -g copy-mode-current-line-style 'bg=${palette.bg-highlight}'
      setw -g copy-mode-line-number-style 'fg=${palette.fg-dim}'
      setw -g copy-mode-current-line-number-style 'fg=${palette.fg-main},bg=${palette.bg-highlight},bold'
      setw -g switch-mode-match-style 'fg=${palette.blue},bold'
      set -g message-style 'fg=${palette.fg-main},bg=${palette.bg-popup}'
      set -g message-command-style 'fg=${palette.fg-main},bg=${palette.bg-popup}'
      set -g menu-style 'fg=${palette.fg-main},bg=${palette.bg-popup}'
      set -g menu-selected-style 'fg=${palette.fg-main},bg=${palette.bg-region},bold'
      set -g menu-border-style 'fg=${palette.border}'
      set -g popup-style 'fg=${palette.fg-main},bg=${palette.bg-popup}'
      set -g popup-border-style 'fg=${palette.blue}'

      set -g @thumbs-bg-color '${palette.bg-main}'
      set -g @thumbs-fg-color '${palette.fg-main}'
      set -g @thumbs-hint-bg-color '${palette.bg-active}'
      set -g @thumbs-hint-fg-color '${palette.blue}'
      set -g @thumbs-select-bg-color '${palette.bg-region}'
      set -g @thumbs-select-fg-color '${palette.fg-main}'
    ''
  ) palettes;
in
{
  imports = [
    home.profiles.tmux
  ];

  programs = {
    tmux = {
      escapeTime = 10;

      extraConfig = ''
        # Match Ghostty's Hyper+b mapping.
        set -s user-keys[0] "\e[9001~"
        bind -N "Send the prefix to a nested session" User0 send-keys -l "\e[9001~"

        # Emacs requests modifyOtherKeys when it initializes the terminal.
        set -s extended-keys on
        set -s extended-keys-format xterm
        set -as terminal-features ',xterm-ghostty:RGB:extkeys:clipboard'

        # Allow applications to copy through the enclosing terminal.
        set -s set-clipboard on
        set -ag update-environment ' COLORTERM'

        # Start new work in the active pane's directory.
        bind -N "New window in the current directory" c new-window -c "#{pane_current_path}"
        bind -N "Split left and right" % split-window -h -c "#{pane_current_path}"
        bind -N "Split top and bottom" '"' split-window -v -c "#{pane_current_path}"
        bind -N "Split left and right" '|' split-window -h -c "#{pane_current_path}"
        bind -N "Split top and bottom" - split-window -v -c "#{pane_current_path}"
        bind -N "Open a floating shell" '*' new-pane -A -x 80% -y 70% -X 10% -Y 15% -T shell -c "#{pane_current_path}"

        bind -N "Find a window" Tab switch-mode -Zw
        bind -N "Find a session" BTab switch-mode -Zs
        bind -r -N "Resize pane left" S-Left resize-pane -L 5
        bind -r -N "Resize pane right" S-Right resize-pane -R 5
        bind -r -N "Resize pane up" S-Up resize-pane -U 5
        bind -r -N "Resize pane down" S-Down resize-pane -D 5

        # Retain failed tool output until a key is pressed.
        setw -g remain-on-exit failed-key
        setw -g pane-scrollbars auto-hide
        setw -g copy-mode-line-numbers absolute
        setw -g pane-border-status top-floating
        setw -g pane-border-format " #{pane_index}: #{pane_title} "
        set -g set-titles on
        set -g set-titles-string "#S / #W / #h"
        set -g status-left-length 30
        set -g status-right-length 70
        setw -g window-status-format ' #I:#W#F '
        setw -g window-status-current-format ' #I:#W#F '

        # Keep built-in menus and modes aligned with both Modus palettes.
        set -s light-theme-black '${palettes.light.fg-main}'
        set -s light-theme-white '${palettes.light.bg-main}'
        set -s light-theme-light-grey '${palettes.light.bg-dim}'
        set -s light-theme-dark-grey '${palettes.light.fg-dim}'
        set -s light-theme-red '${palettes.light.red}'
        set -s light-theme-green '${palettes.light.green}'
        set -s light-theme-yellow '${palettes.light.yellow}'
        set -s light-theme-blue '${palettes.light.blue}'
        set -s light-theme-magenta '${palettes.light.magenta}'
        set -s light-theme-cyan '${palettes.light.cyan}'

        set -s dark-theme-black '${palettes.dark.bg-main}'
        set -s dark-theme-white '${palettes.dark.fg-main}'
        set -s dark-theme-light-grey '${palettes.dark.fg-dim}'
        set -s dark-theme-dark-grey '${palettes.dark.bg-dim}'
        set -s dark-theme-red '${palettes.dark.red}'
        set -s dark-theme-green '${palettes.dark.green}'
        set -s dark-theme-yellow '${palettes.dark.yellow}'
        set -s dark-theme-blue '${palettes.dark.blue}'
        set -s dark-theme-magenta '${palettes.dark.magenta}'
        set -s dark-theme-cyan '${palettes.dark.cyan}'

        set -s command-alias[theme-light] 'theme-light=source-file ${themes.light}'
        set -s command-alias[theme-dark] 'theme-dark=source-file ${themes.dark}'
        bind -N "Toggle light and dark themes" T if -F '#{==:#{theme},light}' {
          source-file ${themes.dark}
        } {
          source-file ${themes.light}
        }

        # Keep modus-operandi-tinted as the startup theme.
        source-file ${themes.light}
      '';

      focusEvents = true;
      historyLimit = 50000;
      keyMode = "emacs";
      mouse = true;

      plugins = [
        {
          plugin = pkgs.tmuxPlugins.tmux-thumbs;

          extraConfig = ''
            set -g @thumbs-key Space
            set -g @thumbs-unique 1
            # Let tmux send clipboard updates to the enclosing terminal.
            set -g @thumbs-command 'tmux set-buffer -w -- "{}"'
            set -g @thumbs-upcase-command 'tmux set-buffer -w -- "{}" && tmux paste-buffer'
            set -g @thumbs-multi-command 'tmux set-buffer -w -- "{}" && tmux paste-buffer'
          '';
        }
      ];

      prefix = "User0";
    };
  };
}
