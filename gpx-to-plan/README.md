# gpx-to-plan

Turns GPX tracks plus a list of stops into the plan JSON that the easy-pacer app (Trạm Kế)
bundles in `src/Storage/Seeded.elm`. Each stop is snapped onto the track to get its km.

    ~/Workspace/ai-tools/gpx-to-plan/gpx-to-plan routes.json --elm ~/Workspace/easy-pacer/src/Storage/Seeded.elm

Without `--elm` it prints the plans as JSON instead of rewriting the Elm file.

`routes.json` is a list; see `routes.example.json` (the five Núi Dinh routes added on 2026-10-26).
Each stop needs `lat`, `lon`, `near_km` (roughly where on the track it is, so a track that passes
the same place twice picks the right pass) and a `name` in Vietnamese for the runner.

The track is thinned to at most 3000 points exactly like the app does, so the km values here are
the km values the app will show. Elevation is copied as is; the app smooths it itself.

After running it: `npm run check && npm run format && npm test && npm run structure` in easy-pacer.
The structure check rejects Vietnamese outside string literals, so keep the Elm doc comment English.
