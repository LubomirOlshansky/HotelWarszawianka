- Plac Zawiszy: the Al. Jerozolimskie arm over the railway is one flat street again, paved between the carriageways like the real square, with no open rail pit, railings or raised strips between narrow bridges. Żelazna by Al. Jerozolimskie is a flat street over the cross-city tunnel, and the trains now run straight into a dark tunnel mouth under it.

## Backlog
- fixed: F's playtest report, build 11 (2026-11-16): the open pit at Plac Zawiszy, and Żelazna x Al. Jerozolimskie with a floating deck, wing walls and a road that dropped under it
- fixed: F's review of the redo (2026-11-16): at Żelazna the rails stopped in steps before the mouth and no track went in under the street; the tunnel's west mouth moved to the street's west pavement; the mouth's headwall now roofs it back to the pavement, so no open slot shows beside the street (F, 2026-11-17)
- found: by Plac Zawiszy the outermost track (north side, under the slab's ends) lies under the ground the approaches and the slab's ends hold at street level (also on main); a fix that lets the floor win under bridges moved check_drape over its limit, so it needs its own pass
- found: the cause is generic (every OpenStreetMap bridge=yes way becomes its own deck, joined to its neighbours only under 6 m apart, whatever the ground under it); the sweep (`tools/rail_covers.py --sweep`) lists the road deck groups with 6-12 m gaps: 1, 5, 7, 8, 19, 21 are river and road bridges whose gaps look real, left as they are
- found: a street over a short rail tunnel needs a `COVERS` line in tools/rail_covers.py
- found: the bus and tram stops of Plac Zawiszy sit on the square's four arms (Al. Jerozolimskie east, Grójecka and Raszyńska), as in the real city; none belongs on the slab
