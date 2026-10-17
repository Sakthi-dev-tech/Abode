const std = @import("std");
const get_paths_funcs = @import("../utils/get_paths_utils.zig");
const verify_funcs = @import("verify_command_funcs.zig");

/// Capture a file or directory in the local source repo, following chezmoi's model.
/// Intended flow from design_planning.excalidraw; copying and registration are not implemented yet.
pub fn add_file_to_track(init: std.process.Init, sub_dir_path: []const u8) !void {
    const io = init.io;
    const dir = std.Io.Dir;

    // 1. Verify setup. Resolve a relative or absolute path; expand a leading ~/
    // directly using this device's home, without shell expansion. Require an
    // existing, readable file or directory. Reject symlinks (including parent
    // components) initially, and reject Abode's own config and storage trees.
    const is_verified = verify_funcs.verify_setup(init);
    if (!is_verified) {
        return;
    }

    const current_working_dir = dir.cwd();

    const file_path = try current_working_dir.realPathFileAlloc(io, sub_dir_path, init.arena.allocator());
    std.debug.print("Current add file path: {s}\n", .{file_path});

    // 2. Derive the destination-relative path from this device's home directory.
    // Check containment by path components, not a string prefix. Initially accept
    // only descendants of home; reject home itself and outside-home paths.
    // No shared absolute paths, generated root IDs or fallback-path metadata.

    // 3. Encode that relative path into the source tree using chezmoi-style names.
    // Example: ~/.config/nvim/init.lua -> repo/dot_config/nvim/init.lua;
    // ~/.zshrc -> repo/dot_zshrc. Encode each component, not just the basename.
    // Use one reversible encoder/decoder with canonical attribute ordering and
    // escaping for literal names that resemble reserved prefixes or suffixes.
    // Preserve private/executable attributes in names (private_, executable_);
    // Use empty_ for empty files. Empty-directory tracking is deferred because
    // Git does not retain empty directories; do not add per-root metadata for it.
    // Validate decoded paths, case collisions and file/directory conflicts.

    // 4. Use ~/.local/share/abode/repo/ as the managed Git source directory.
    // Init/verify currently use ~/.local/share/abode/roots/; align those commands
    // with repo/ before implementing capture. There are no per-root content/
    // wrappers: source paths themselves identify the managed destinations.
    // Re-adding refreshes the same source entry from the selected local contents.
    // Adding a parent/child shares the same tree; merge redundant selections.
    // An unchanged re-add is a no-op. Reject aliases decoding to the same path.
    // If attribute prefixes change, replace the old encoded entry safely.

    // 5. Prepare a complete copy before replacing source entries; keep actual
    // files in place. Recurse for directories, encoding child names and preserving
    // original file bytes. Honor selection-relative ignores; exclude Abode's
    // config/storage and nested .git entries. An unreadable or disappearing
    // source is an error, not a deletion. Re-add does not prune absent children;
    // deletion reconciliation belongs to sync and requires a recorded base.

    // 6. After capture succeeds, select the decoded home-relative path locally
    // in ~/.config/abode/config.toml (for example .config/nvim or .zshrc).
    // Store only remote settings and selected paths; no ID-to-destination map.
    // On another device, discover entries by decoding the source tree, choose
    // paths, and resolve them beneath that device's home. Compare existing files
    // before first application; preserve them until differences are resolved.
    // An interrupted add must not enable a partially copied selection.

    // 7. Hand off to the normal sync cycle to commit, reconcile and publish.
    // Add only captures source contents; it does not apply or push them itself.
    // Keep applied revisions/hashes and pending work outside the source repo in
    // state.json, keyed by decoded relative path. Checkpoint only after success.
    // Offline work stays local; new remote entries remain opt-in on each device.
}
