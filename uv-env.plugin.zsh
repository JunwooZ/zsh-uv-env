# Function to check if a virtualenv is already activated
is_venv_active() {
    [[ -n "$VIRTUAL_ENV" ]] && return 0
    return 1
}

# Add caching mechanism to avoid repeated lookups
typeset -g _ZSH_UV_ENV_LAST_VENV=""
typeset -g _ZSH_UV_ENV_LAST_DIR=""

# Function to find nearest .venv directory
find_venv() {
    local current_dir="$PWD"
    # If current directory is a subdirectory of the last searched directory and a venv was found before, return cached result directly
    if [[ "$current_dir" == "$_ZSH_UV_ENV_LAST_DIR"* ]] && [[ -n "$_ZSH_UV_ENV_LAST_VENV" ]] && [[ -d "$_ZSH_UV_ENV_LAST_VENV" ]]; then
        return 0
    fi
    # Reset cache
    _ZSH_UV_ENV_LAST_VENV=""
    _ZSH_UV_ENV_LAST_DIR=""

    local home_dir="$HOME"
    local root_dir="/"
    local stop_dir="$root_dir"

    # If we're under home directory, stop at home
    if [[ "$current_dir" == "$home_dir"* ]]; then
        stop_dir="$home_dir"
    fi

    while [[ "$current_dir" != "$stop_dir" ]]; do
        if [[ -d "$current_dir/.venv" ]]; then
            # Update cache after finding venv
            _ZSH_UV_ENV_LAST_VENV="$current_dir/.venv"
            _ZSH_UV_ENV_LAST_DIR="$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    # Check stop_dir itself
    if [[ -d "$stop_dir/.venv" ]]; then
        # Update cache after finding venv
        _ZSH_UV_ENV_LAST_VENV="$stop_dir/.venv"
        _ZSH_UV_ENV_LAST_DIR="$stop_dir"
        return 0
    fi

    return 1
}

# Variable to track if we activated the venv
typeset -g AUTOENV_ACTIVATED=0

# Function to handle directory changes
autoenv_chpwd() {
    # Don't do anything if a virtualenv is already manually activated
    if is_venv_active && [[ $AUTOENV_ACTIVATED == 0 ]]; then
        return
    fi

    find_venv
    local venv_path="$_ZSH_UV_ENV_LAST_VENV"

    if [[ -n "$venv_path" ]]; then
        # If we found a venv and none is active, activate it
        if ! is_venv_active; then
            source "$venv_path/bin/activate"
            AUTOENV_ACTIVATED=1
        fi
    else
        # If no venv found and we activated one before, deactivate it
        if [[ $AUTOENV_ACTIVATED == 1 ]] && is_venv_active; then
            deactivate
            AUTOENV_ACTIVATED=0
        fi
    fi
}

# Register chpwd hook to watch for new venv creation
autoload -U add-zsh-hook
add-zsh-hook chpwd autoenv_chpwd

# Run once when shell starts
autoenv_chpwd
