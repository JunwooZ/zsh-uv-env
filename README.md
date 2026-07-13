# zsh-uv-env

zsh-uv-env is a plugin for zsh and uv. It automatically activates a virtual environment based on the current directory.

This repository is a modified version of the original [zsh-uv-env](https://github.com/matthiasha/zsh-uv-env) plugin, with the following changes:

1. Removed hooks functionality  
2. Changed from using the `precmd` hook to the `chpwd` hook 
3. Added a caching mechanism to improve performance by remembering previously found virtual environments

# Installation with oh-my-zsh

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default
   `~/.oh-my-zsh/custom/plugins`)

   ```sh
   git clone https://github.com/JunwooZ/zsh-uv-env ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/uv-env
   ```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside `~/.zshrc`):

   ```sh
   plugins=(
     ...
     uv-env
   )
   ```

3. Start a new terminal session.

# How It Works

The plugin automatically detects and activates Python virtual environments (.venv
directories) as you navigate through your filesystem. When you leave a directory with an
environment that the plugin activated, it automatically deactivates it. Environments that
you activate manually are left unchanged.

The plugin activates an environment by sourcing its `.venv/bin/activate` file. Only use
the plugin in directories you trust, because activation files contain executable shell code.
