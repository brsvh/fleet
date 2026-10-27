{
  home,
  ...
}:
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
      '';

      focusEvents = true;
      keyMode = "emacs";
      prefix = "User0";
    };
  };
}
