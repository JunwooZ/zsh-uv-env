# Function to check if a virtualenv is already activated
is_venv_active() {
    [[ -n "${VIRTUAL_ENV:-}" ]] && return 0
    return 1
}

# Add caching mechanism to avoid repeated lookups
typeset -g _ZSH_UV_ENV_LAST_VENV=""
typeset -g _ZSH_UV_ENV_LAST_DIR=""

_zsh_uv_env_is_within_dir() {
    local current_dir="$1"
    local parent_dir="$2"

    [[ -n "$parent_dir" ]] || return 1
    [[ "$current_dir" == "$parent_dir" || "$current_dir" == "$parent_dir"/* ]]
}

_zsh_uv_env_is_valid_venv() {
    local venv_path="$1"

    [[ -d "$venv_path" && -r "$venv_path/bin/activate" ]]
}

# Function to find nearest .venv directory
find_venv() {
    local current_dir="$PWD"

    if _zsh_uv_env_is_within_dir "$current_dir" "$_ZSH_UV_ENV_LAST_DIR" && _zsh_uv_env_is_valid_venv "$_ZSH_UV_ENV_LAST_VENV"; then
        local probe_dir="$current_dir"

        while [[ "$probe_dir" != "$_ZSH_UV_ENV_LAST_DIR" ]]; do
            if _zsh_uv_env_is_valid_venv "$probe_dir/.venv"; then
                _ZSH_UV_ENV_LAST_VENV="$probe_dir/.venv"
                _ZSH_UV_ENV_LAST_DIR="$probe_dir"
                return 0
            fi
            probe_dir="${probe_dir:h}"
        done

        return 0
    fi

    # Reset cache
    _ZSH_UV_ENV_LAST_VENV=""
    _ZSH_UV_ENV_LAST_DIR=""

    local home_dir="$HOME"
    local root_dir="/"
    local stop_dir="$root_dir"

    # If we're under home directory, stop at home
    if _zsh_uv_env_is_within_dir "$current_dir" "$home_dir"; then
        stop_dir="$home_dir"
    fi

    while [[ "$current_dir" != "$stop_dir" ]]; do
        if _zsh_uv_env_is_valid_venv "$current_dir/.venv"; then
            # Update cache after finding venv
            _ZSH_UV_ENV_LAST_VENV="$current_dir/.venv"
            _ZSH_UV_ENV_LAST_DIR="$current_dir"
            return 0
        fi
        current_dir="${current_dir:h}"
    done

    # Check stop_dir itself
    if _zsh_uv_env_is_valid_venv "$stop_dir/.venv"; then
        # Update cache after finding venv
        _ZSH_UV_ENV_LAST_VENV="$stop_dir/.venv"
        _ZSH_UV_ENV_LAST_DIR="$stop_dir"
        return 0
    fi

    return 1
}

# Variable to track if we activated the venv
typeset -g AUTOENV_ACTIVATED="${AUTOENV_ACTIVATED:-0}"
typeset -g _ZSH_UV_ENV_ACTIVE_VENV="${_ZSH_UV_ENV_ACTIVE_VENV:-}"

# Function to handle directory changes
autoenv_chpwd() {
    # Drop stale ownership if the user deactivated or replaced our venv.
    if [[ $AUTOENV_ACTIVATED == 1 && "${VIRTUAL_ENV:-}" != "$_ZSH_UV_ENV_ACTIVE_VENV" ]]; then
        AUTOENV_ACTIVATED=0
        _ZSH_UV_ENV_ACTIVE_VENV=""
    fi

    # Don't do anything if a virtualenv is already manually activated
    if is_venv_active && [[ $AUTOENV_ACTIVATED == 0 ]]; then
        return
    fi

    find_venv
    local venv_path="$_ZSH_UV_ENV_LAST_VENV"

    if [[ -n "$venv_path" ]]; then
        if [[ "${VIRTUAL_ENV:-}" != "$venv_path" ]]; then
            if [[ $AUTOENV_ACTIVATED == 1 ]] && is_venv_active; then
                deactivate
                AUTOENV_ACTIVATED=0
                _ZSH_UV_ENV_ACTIVE_VENV=""
            fi

            if ! is_venv_active; then
                source "$venv_path/bin/activate"
                if [[ "${VIRTUAL_ENV:-}" == "$venv_path" ]]; then
                    AUTOENV_ACTIVATED=1
                    _ZSH_UV_ENV_ACTIVE_VENV="$venv_path"
                fi
            fi
        fi
    else
        # If no venv found and we activated one before, deactivate it
        if [[ $AUTOENV_ACTIVATED == 1 ]] && is_venv_active; then
            deactivate
            AUTOENV_ACTIVATED=0
            _ZSH_UV_ENV_ACTIVE_VENV=""
        fi
    fi
}

# Register chpwd hook to check directories after cd
autoload -U add-zsh-hook
add-zsh-hook chpwd autoenv_chpwd

# Run once when shell starts
autoenv_chpwd
