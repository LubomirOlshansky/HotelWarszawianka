## Backlog
- found: Tamka's bollards and plates are missing on the prebuilt city (the log says 0 bollards, 0 plates; the runtime city has them): tamka.gd reads the baked roads from the map's data, which the prebuilt index does not carry. Not changed in the places owner change (the picture had to stay the same).
- found: tools/verify.sh already had a `places` step (the notebook's check_places.gd), so the place scripts' check is `placescripts` (check_place_scripts.gd).
