---
name: gpx-to-plan
description: Build easy-pacer (Trạm Kế) bundled route plans from GPX files and a list of rest or water stops, snapping each stop onto the track. Use whenever Iker asks to add, replace or fix a ready-made route ("kế hoạch có sẵn") in easy-pacer.
---

# gpx-to-plan

Run the tool, do not rewrite the plan JSON by hand:

```bash
~/Workspace/ai-tools/gpx-to-plan/gpx-to-plan routes.json --elm ~/Workspace/easy-pacer/src/Storage/Seeded.elm
```

- Copy `routes.example.json` and edit it. Stop positions come from Google Maps (open the place, read the
  `!3d<lat>!4d<lon>` part of the URL), OpenStreetMap, or waypoints in a race GPX.
- Check the printed "m off the track" column: more than about 100 m means the position or `near_km` is wrong.
- Then run all four easy-pacer gates and open the app to pick each route once.
