const std = @import("std");
const get_path_funcs = @import("../utils/get_paths.zig");
const get_dir_funcs = @import("../utils/get_dirs.zig");
const VerifyFunctions = @import("verify.zig").VerifyFunctions;

pub const AddFunctions = struct {
    init: std.process.Init,

    /// Capture a file or directory in the local source repo, following chezmoi's model.
    /// Intended flow from design_planning.excalidraw; copying and registration are not implemented yet.
    pub fn add_file_to_track(self: *const AddFunctions, sub_dir_path: []const u8) !void {
        const init = self.init;
        const verify_instance = VerifyFunctions{ .init = init };

        const io = init.io;
        const dir = std.Io.Dir;
        const allocator = init.arena.allocator();

        // 1. Verify setup. Resolve a relative or absolute path; expand a leading ~/
        // directly using this device's home, without shell expansion. Require an
        // existing, readable file or directory. Reject symlinks (including parent
        // components) initially, and reject Abode's own config and storage trees.
        const is_verified = verify_instance.verify_setup();
        if (!is_verified) {
            return;
        }

        const current_working_dir = dir.cwd();

        const file_path = try current_working_dir.realPathFileAlloc(io, sub_dir_path, init.arena.allocator());
        defer allocator.free(file_path);

        // 2. Derive the destination-relative path from this device's home directory.
        // Check containment by path components, not a string prefix. Initially accept
        // only descendants of home; reject home itself and outside-home paths.
        // No shared absolute paths, generated root IDs or fallback-path metadata.
        const file_path_modified = try get_path_funcs.get_universal_path(init, file_path);

        // 3. Encode that relative path into the source tree using chezmoi-style names.
        // Example: ~/.config/nvim/init.lua -> dot_config/nvim/init.lua;
        // ~/.zshrc -> dot_zshrc. Encode each component, not just the basename.
        // Use one reversible encoder/decoder with canonical attribute ordering and
        // escaping for literal names that resemble reserved prefixes or suffixes.
        // Preserve private/executable attributes in names (private_, executable_);
        // Use empty_ for empty files. Empty-directory tracking is deferred because
        // Git does not retain empty directories; do not add per-root metadata for it.
        // Validate decoded paths, case collisions and file/directory conflicts.
        const file_in_abode_path = try get_path_funcs.parse_universal_path_into_abode_path(allocator, file_path_modified);
        defer {
            allocator.free(file_path_modified);
            allocator.free(file_in_abode_path);
        }

        std.debug.print("Current add file path: {s}\n", .{file_in_abode_path});

        // 4. Use ~/.local/share/abode/ as the managed Git source directory.
        // Re-adding refreshes the same source entry from the selected local contents.
        // Adding a parent/child shares the same tree; merge redundant selections.
        // An unchanged re-add is a no-op. Reject aliases decoding to the same path.
        // If attribute prefixes change, replace the old encoded entry safely.
        const abode_dir = try get_dir_funcs.get_local_workspace_dir(init);
        defer abode_dir.close(io);

        try std.Io.Dir.copyFile(
            current_working_dir,
            sub_dir_path, abode_dir, 
            file_in_abode_path,
            io,
            .{
                .replace = true,
                .make_path = true 
            });

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
        // ~/.local/state/abode/state.json, keyed by decoded relative path.
        // Checkpoint only after success.
        // Offline work stays local; new remote entries remain opt-in on each device.
    }
};
