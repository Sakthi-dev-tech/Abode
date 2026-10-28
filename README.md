# Abode

Keep your files in sync across your devices.

Run `Abode init` to create the initial setup, then `Abode verify` to check that
these paths exist with the expected types:

- `~/.config/abode/` (directory)
- `~/.config/abode/config.toml` (regular file)
- `~/.local/share/abode/` (directory)

The managed Git source tree lives directly in `~/.local/share/abode/`.

Verification prints yellow warnings for invalid or missing paths and a green
message on success, then returns normally. Colour is disabled when output is
redirected or `NO_COLOR` is set. It does not modify files or check configuration contents, local copies, or
Git repository setup yet.
