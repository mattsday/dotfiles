# Matt Day's dotfiles

## Getting Started

``` bash
git clone "https://github.com/mattsday/dotfiles/" "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
chmod +x init.sh
./init.sh
```

## About

This started off as a simple place to store dotfiles... Now it's out of control.

The goal is compatibility between the look, feel and features of shells (autocd, noclobber, prompt etc) wherever it's possible for bourne-compatible (ksh, bash and zsh), csh & tcsh, and fish environments. It also handles bootstrapping various systems (servers, desktops, ...) with common software I struggle to live without.

To get going either run `init.sh` to just deploy the dotfiles (existing files _should_ be backed up) or run `bootstrap.sh` to do a full system boostrap including installing tools and utilities (which likely requires root).

For bourne shells `shell_common` is a bourne-compatible script that loads most stuff. `alias_list` is a weird way of handling aliases between both bourne and csh... I probably don't need it any more but it does no harm. Local changes can be made by creating a `dotfile_local` which will be sourced at the end of each file (e.g. `zsh_local` or `shell_common_local` all get called when their main piece has been run.

I also maintain various rc files for programs like vim and mutt. I try and document the settings as comments inside each one.
