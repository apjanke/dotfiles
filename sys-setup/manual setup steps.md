# Manual setup steps

These are things that still need to be done manually, in addition to what the setup-* scripts can do.

## Initial setup steps

* Sign in to AppleID/iCloud if on Mac.
* Install Dropbox.
* Install JDK.
* Install fonts.
* In System Preferences > Sharing, enable File Sharing and Remote Login.
* `ssh localhost` to create ~/.ssh with proper permissions.
* Get my standard SSH keys in to ~/.ssh on my machine from somewhere else.

## Get the files needed to bootstrap the automated process

```bash
cd ~
mkdir -p repos local local/opp
cd ~/repos
git clone https://github.com/apjanke/dotfiles
```

And then run `install-dotfiles` and stuff in sys-setup there.
