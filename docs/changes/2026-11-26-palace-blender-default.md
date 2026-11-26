- The Palace of Culture and Science is the detailed model now: profiled cornices and pinnacles on every step, round columns on the main portico and the wings, the Congress Hall's colonnade, the clocks above the tower's arcade as in the photos, tall dark timber doors behind the main columns, and a crown with bigger clocks, a frieze of pointed panels above them and clusters of pinnacles at the corners, as in the photos.

## Backlog
- fixed: the Blender Palace trial (QUESTIONS "Blender for the top landmarks?"): taken as the default for the reel's close-ups; `--palace=code` still builds the old code model
- fixed: 186 z-fighting triangles in the Blender Palace (the entrance steps shared their outer face; the colonnade and portico columns ended flush under their entablatures)
- found: 101 hidden coplanar triangles remain at 17-18 m where the wings' walls meet the base cornice (check_mesh_quality KNOWN `palace`)
- found: phone look and a device bench at the Palace (26.9k triangles, one mesh) are owed; the prebuilt sectors must be re-baked before a store build
- found: the Palace's own proxy in the far city could use the glb's LOD 1 (9.3k triangles)

## Roadmap
- ticked: "Blender trial: the Palace built in Blender behind --palace=blender"
