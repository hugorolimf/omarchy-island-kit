# Island Kit `ui/` — anatomy components

A copy of Omarchy's `qs.Ui` components (`/usr/share/omarchy/shell/Ui/`) with the
anatomy look. The API is the same (properties, signals, functions), so a panel
written for Omarchy works here by changing only its import. This folder is a
library, not a plugin: it has no `manifest.json` of its own.

- **Tokens:** `Anatomy.qml` (colours, radii, fonts, the `Anatomy.ease` curve) and
  stroke icons in `Anatomy.icons.*`, drawn with `AnatomyIcon { path: ... }` on a
  24-unit grid.
- `AnatomyLift` is the soft "lift" shadow; `BorderGeometry.js` is a local copy of
  Omarchy's Commons one (a relative `../Commons` import doesn't resolve from here).

## Moving an Omarchy panel over (e.g. `omarchy.audio`)

1. Copy the panel out of `/usr/share/omarchy/shell/plugins/panels/audio` into your
   own plugin folder (`chmod -R u+w`).
2. In its `.qml` files, replace `import qs.Ui` with
   `import "../io.github.hugorolimf.kit/ui"` (one more `../` per subfolder).
3. Give it your own `moduleName` and `manifest.json` id. Keep `ipcTarget` and the
   `IpcHandler` targets, and keep `"omarchy": { "clonedFrom": "omarchy.audio" }`
   in the manifest, so shortcuts and scripts that call the original id still work.
4. For the full look: loose text in `Anatomy.strong` / `Anatomy.text` /
   `Anatomy.muted`, `Anatomy.sans` for words and `Anatomy.mono` for numbers and
   labels, `Font.DemiBold` instead of bold, Nerd Font glyphs replaced by
   `AnatomyIcon`, and no `fill:` / `currentFill:` on `CursorSurface` (its defaults
   are already anatomy's). `font.pixelSize` takes integers only.
5. `omarchy plugin validate <folder>`, then add it and restart the shell.
