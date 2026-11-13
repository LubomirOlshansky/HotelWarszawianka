# Graphics: how a frame is drawn

The full plan, numbers and device tiers are in docs/design/graphics.md; the budgets in the archive
section "Performance budgets" (`grep -n "^## Performance budgets" docs/archive/DEVELOPMENT-full.md`).
This page is the map.

## 1. The pipeline

```
3D city (Mobile renderer, Metal on iPhone, Vulkan on Android)
   drawn into a low-resolution SubViewport (main.gd `sv`, the "pixel image")
        │  size from tiers.gd: whole-pixel scale `view.stretch_shrink`
        ▼
post.gdshader on that image: outlines where depth jumps, colour levels, saturation
        │  (optional vhs.gdshader: the Retro filter)
        ▼
scaled up with sharp pixels to the screen
        ▼
HUD (hud.gd, CanvasLayer) at full resolution on top: text, bubbles, cards, minimap
```

The pixel-art look comes from rendering the 3D small and scaling it up. Text and bubbles are drawn
after the scale-up, so they stay sharp and need no 3D transparency.

## 2. Materials and shaders (`game/shaders/`)

| Shader | Draws |
| --- | --- |
| `ground.gdshader` | Ground, parks, paths, roads, markings, rails (layers in UV.x) |
| `building.gdshader` | LoD2 and OSM buildings and landmarks; a lite copy on Adreno 6xx (`gpu_quirks.gd`) |
| `actor.gdshader` | Everything that moves: cars, trams, people (legs swing in the shader) |
| `foliage.gdshader` | Tree crowns, colour per instance |
| `fixture.gdshader`, `glow.gdshader`, `neon.gdshader` | Lamps, additive light cones, neon signs (night only) |
| `map_edge.gdshader` | Land past the map edge |
| `poster.gdshader`, `led_screen.gdshader`, `spire_*.gdshader`, `event_fog.gdshader` | Single landmarks and events |
| `post.gdshader`, `vhs.gdshader` | Full-screen passes |
| `title.gdshader`, `chrome.gdshader`, `solo.gdshader` | Title screen, wordmark, landmark review look |
| `common`, `night`, `city_maps`, `ghost`, `tunnel_cut` `.gdshaderinc` | Shared code: noise macros, time of day, baked AO / light / surface maps, the see-through ghost, the tunnel cutaway |

**Global shader uniforms** (project.godot `[shader_globals]`): `lights_on`, `daylight`,
`sky_colour`, `wetness`, `rain`, `edge_haze`, the `city_*` maps and slots. `time_of_day.gd` and
`weather.gd` write them; every city shader reads them. A new look that depends on the hour or the
rain reads these, never its own copy.

## 3. Quality: tiers and the governor

- `tiers.gd`: Low, Medium, High, Ultra and Auto. Auto picks by device model at first launch. Each
  tier sets the pixel image budget, shadows, reflections, glow, traffic share and people count.
- `governor.gd`: watches late frames and steps the extras (traffic share, pedestrians, small sun
  shadows) down one level, back up after a calm while. It never touches the pixel size, the shadow
  map size, landmarks, the ghost, the river or the night lights.
- A new extra that costs frame time is a field in `tiers.gd`, and a step in `governor.gd` if it is
  CPU work. Features don't test the device themselves.

## 4. Budgets (the gate)

- **Draw calls**, not triangles: default views 124-190, helicopter 245, ceiling 500 at any view.
  Measure with `--probe` at 2868x1320 on the Mobile renderer.
- **Scripts**: all systems about 1 ms a frame on the Mac at the spawn.
- **Adreno shader budget**: the Android driver fails to link fragment shaders past a
  control-flow ceiling. The lite building shader stands at 498 of about 508. Prefer `step`, `mix`,
  ternaries and `all()`/`any()` over `if`; run `check_shader_budget.gd`. The next shader change to
  building must slim it first.
- **Streaming**: a frame that loads a sector at most 33 ms; the main thread per frame at most 3 ms.

## 5. Cheap ways to add things

| Want | Do |
| --- | --- |
| Many copies of a thing | One MultiMesh (instance colour in custom data). `instance_buffers.gd` writes it. |
| More people | Rent slots in pedestrians' MultiMesh (+0 draw calls). |
| Static props | Append boxes to the shared props surface (props.gd style) in the actors' material. A place script's dressing is poured to `places.gd`, which merges it into one mesh per 512 m sector (one draw call per sector, shadow casters and non-casters apart). |
| A detail only close up | Its own visibility range (`fine_detail` hidden beyond 170 m, 240 m on Ultra). |
| Night-only light | `glow.gdshader` or the lamp map, gated by `lights_on`. Avoid real lights. |
| Something in the static city | It must appear on **both city paths**: the runtime build (`map_builder.gd`) and the prebuilt sectors (`tools/bake_city.gd`). Check with `--prebuilt`. |

## 6. What only the phone can show

Thermal throttling over a long drive, real touch feel, the Metal frame time, Android driver
failures. The Mac and the cloud give draw calls and script time; anything per-frame names in its PR
what still needs a phone run.
