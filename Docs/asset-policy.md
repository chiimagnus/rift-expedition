# Asset Policy

Formal game assets must be listed in `RiftExpedition/Resources/Assets/assets-manifest.json`.

## Manifest Fields

- `id`: stable English id
- `path`: path relative to `RiftExpedition/Resources`
- `type`: asset type, for example `tileset`, `sprite`, `icon`, `audio`
- `source`: source URL or local creation note
- `license`: one of `CC0`, `self-made`, `ai-static`
- `downloadedAt`: ISO date string
- `author`: asset author or generator note

## Allowed Licenses

- `CC0`
- `self-made`
- `ai-static`

GPL, CC-BY-SA, unknown, and missing licenses are not allowed for formal assets.

Formal ids must not contain `placeholder`, `temp`, or `graybox`.
