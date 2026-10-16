const std = @import("std");
const home_dir_funcs = @import("../utils/home_dir_resolve.zig");

/// Register a file or directory as a sync root, or enable an existing root on this device.
/// Intended flow from design_planning.excalidraw; the steps below are not implemented yet.
pub fn add_file_to_track(init: std.process.Init, sub_dir_path: []const u8) !void {
    const io = init.io;
    const dir = std.Io.Dir;

    // 1. Resolve sub_dir_path against the current working directory (or accept an
    // absolute path). Verify setup and require an existing, readable file or directory.
    // Expand a leading ~/ using this device's home directory, without shell expansion.
    // Reject paths inside Abode's own storage; define a symlink policy before supporting links.
    const current_working_dir = dir.cwd();

    const file_path = try current_working_dir.realPathFileAlloc(
        io,
        sub_dir_path,
        init.arena.allocator()
        );
    std.debug.print("Current add file path: {s}\n", .{file_path});

    // 2. Derive the shared fallback_path relative to home, storing ~/ literally.
    // For a source outside home, ask for a portable ~/ fallback and keep the actual
    // source path as a device-only destination override in config.toml.
    // Do not publish this device's resolved absolute paths in shared metadata.

    // 3. Read existing roots' metadata and this device's config.toml mappings.
    // Root identity is the full stable ID, not its display name or path alone.
    // Resolve mappings using destination override first, then shared fallback_path.
    // Detect duplicate destinations and overlapping roots before registering a root;
    // reject ../ escapes and case collisions in managed relative paths.

    // 4. If the selection matches an existing root, reuse its ID and repo folder.
    // If already enabled at this destination, adding it again is a no-op.
    // Otherwise enable it under [roots."<full-id>"] in config.toml, saving a
    // destination override only when needed. Do not create duplicate shared metadata.
    // Compare existing local contents with the repo before the first application.
    // If they differ, require a choice of local, remote, or reconciled contents;
    // preserve the actual files until that choice is safely applied by sync.

    // 5. For a new root, generate a full stable ID and a readable, stable folder
    // name such as nvim--a81f39c2. The planned managed clone layout is
    // ~/.local/share/abode/repo/roots/<generated-name>/{metadata.json, content/}.
    // Init currently creates ~/.local/share/abode/roots/ directly; align storage
    // setup with the planned repo/ layout when implementing this flow.
    // Write metadata.json with format_version, id, kind, display_name and fallback_path.
    // A file root also records content_entry (for example, kitty.conf).
    // Directory children are identified initially by root ID + relative path;
    // record attributes such as executable bits and empty directories in metadata.

    // 6. Copy stable original bytes into content/; leave the source files in place.
    // Directory: preserve child names and relative paths recursively.
    // Single file: copy to content/<content_entry>.
    // Honor root-relative ignores and exclude Abode storage and nested Git metadata.
    // Keep content files free of metadata headers. An unreadable or disappearing
    // source is an error, not a deletion to publish.

    // 7. Enable the new ID in ~/.config/abode/config.toml after preparing its copy
    // and metadata successfully. Keep config and sync state outside the Git repo;
    // an interrupted add must not leave an enabled, partially populated root.

    // 8. Hand off to the normal sync cycle to commit, reconcile and publish.
    // Adding alone must not overwrite local destinations or claim a successful sync.
    // Record applied revisions/hashes in state.json only after successful sync;
    // keep pending work locally when offline. Existing remote roots remain opt-in.
}
