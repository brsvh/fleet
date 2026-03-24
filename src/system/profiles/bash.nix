{
  pkgs,
  ...
}:
let
  inherit (pkgs)
    hstr
    ;
in
{
  programs = {
    bash = {
      interactiveShellInit = ''
        # Only for interactive shells.
        [[ $- != *i* ]] && return

        # Prevent file overwrite on stdout redirection.
        set -o noclobber

        # Update window size after every command.
        shopt -s checkwinsize

        # Automatically trim long paths in the prompt.
        PROMPT_DIRTRIM=3

        # Turn on recursive globing.
        shopt -s globstar 2> /dev/null

        # Perform file completion in a case insensitive fashion.
        bind "set completion-ignore-case on"

        # Treat hyphens and underscores as equivalent.
        bind "set completion-map-case on"

        # Display matches for ambiguous patterns at first tab press.
        bind "set show-all-if-ambiguous on"

        # Immediately add a trailing slash when auto-completing symlinks to
        # directories.
        bind "set mark-symlinked-directories on"

        # Append to the history file, don't overwrite it.
        shopt -s histappend

        # Save multi-line commands as one command.
        shopt -s cmdhist

        # Record each line as it gets issued.
        _pcmd="''${PROMPT_COMMAND:+$PROMPT_COMMAND}"
        PROMPT_COMMAND="history -a; history -n''${_pcmd:+; $_pcmd}"

        case :$SHELLOPTS: in
          *:posix:*)
            _hf_prefix="sh"
            ;;
          *)
            _hf_prefix="bash"
            ;;
        esac

        _hf_dir="''${XDG_STATE_HOME:-''$HOME/.local/state}/''${_hf_prefix}"
        export HISTFILE="''${_hf_dir}/history"
        mkdir -p "$(dirname -- "${HISTFILE}")"

        # Huge history. Doesn't appear to slow things down, so why not?
        HISTSIZE=500000
        HISTFILESIZE=500000

        # Avoid duplicate entries.
        HISTCONTROL="erasedups:ignoreboth"

        # Don't record some commands.
        export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

        # Use standard ISO 8601 timestamp.
        # %F equivalent to %Y-%m-%d
        # %T equivalent to %H:%M:%S (24-hours format)
        HISTTIMEFORMAT='%F %T '

        # Enable incremental history search with up/down arrows.
        bind '"\e[A": history-search-backward'
        bind '"\e[B": history-search-forward'
        bind '"\e[C": forward-char'
        bind '"\e[D": backward-char'

        function hstrnotiocsti {
            {
        READLINE_LINE="$(
            {
        </dev/tty "${hstr}/bin/hstr" "''${READLINE_LINE}"
            } 2>&1 1>&3 3>&-
        )"
            } 3>&1
            READLINE_POINT=''${#READLINE_LINE}
        }

        # Bind hstr to <ctrl-r>.
        bind -x '"\C-r": "hstrnotiocsti"'

        # Disable hstr use of the TIOCSTI ioctl for injecting input.
        export HSTR_TIOCSTI=n

        # Prepend cd to directory names automatically.
        shopt -s autocd 2> /dev/null

        # Correct spelling errors during tab-completion.
        shopt -s dirspell 2> /dev/null

        # Correct spelling errors in arguments supplied to cd.
        shopt -s cdspell 2> /dev/null
      '';
    };
  };
}
