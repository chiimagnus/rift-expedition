# Tiled Map Contract

`.tmx` is the canonical map source. Generated summaries, SVG previews, and markdown reports are review artifacts, not hand-edited source.

## Required Object Layers

- `spawn`: requires `id`
- `npc`: requires `actorId`, `dialogId`
- `encounter`: requires `encounterId`, `radius`
- `trigger`: requires `triggerId`, `action`
- `exit`: requires `targetAreaId`, `targetSpawnId`
- `navObstacle`: requires `blocksMovement`, `blocksSight`
- `surface`: requires `surfaceType`
- `item`: requires `itemId`

## Validation Rules

- All required layers must exist, even if empty.
- Tiled numeric object ids must be unique per map.
- Required properties must be present.
- `exit.targetSpawnId` must reference an existing `spawn.id` in the validated map.
- `spawn` points must not be inside `navObstacle` objects with `blocksMovement = true`.

## CLI

```sh
rtk swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources --area village_square --write-preview Docs/Reports/map-previews/chapter1/village_square --write-report Docs/Reports/map-previews/chapter1/village_square/report.md
```

`--write-preview` writes SVG previews. `--write-report` writes a markdown report.
