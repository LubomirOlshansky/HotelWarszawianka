# Sienkiewicza 4 (site `sienkiewicza4`)

F's ask (2026-11-24): model the three houses round THE TAPCZAN on ul. Sienkiewicza. Photo:
`/mnt/project-files/refs/sienkiewicza/f-sienkiewicza4-front.png` (never shipped).

## Identity
A cream Art Nouveau tenement of seven bays: two rounded bow corners with curved iron-railed
balconies at the 2nd and 3rd floors, dark green-grey stone friezes with leafy relief under the 3rd
and the top floor, a strong dark band over the ground floor, a steel truss canopy over the middle
gate, tall arched first-floor windows.

## Massing
Replaces the mapped outlines (OSM: the 20.8 m block with its front from -789.1,-46.2 to
-763.1,-56.4, the 24.1 m range behind it and the 4.3 m base). The front is recessed 0.35 m behind
a 0.4 m skin so THE TAPCZAN's street level (site `tapczan`, u 0.3-12.9, up to 4.5 m) stands in front
of it untouched; the skin starts east of u 12.9 at street level and covers every floor above 4.5 m.
The two bows project 0.9 m (three facets each, u 0.3-4.9 and 23.0-27.6).

## Facade
Base: the pub (not this site's), then the gate (u 14.75, 2.3 m, steel canopy 3.8 m wide, 1.7 m out)
and three shop bays east of it, a grey plinth. Middle: five floors, sills 5.6, 8.6, 11.6, 14.6,
17.6 m; an arched window per middle bay on the first floor, pairs of windows above; the friezes at
10.45-11.25 m and 16.45-17.25 m. Top: a cream cornice at 20.2-20.8 m.

## Roof
Flat gravel roof at 20.8 m, the rear range flat at 24.1 m (LoD2's mansard is not modelled).

## Colour and material
Cream #ece7db (F 2026-11-24: repainted from #e6dcc6, which read tan; refs/sienkiewicza4 5, 1), trim #f5f2ea, frieze #566259, balcony rails PAL_PATINA_COPPER,
steel #4b5156. Windows are kit panes (lit by chance at night); everything is M_STONE.

## Ground and night
The pub's terrace and dressing stay as they are. Window panes light by chance at night.

## Detail level and budget
L3, 4394 triangles (budget 5300), +0 draw calls.

## Parts table
| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| body | prism | 27.9 m front, 20.8 m | OSM main ring, front back 0.35 m | M_STONE | the mass |
| rear | prism | 24.1 m | OSM rear ring | M_STONE | the range behind |
| skin | kit_wall | 27.9 x 15.7 m | v -0.4..0 | M_STONE | the cream front |
| bows | prism, 3 facets | 4.6 m wide, 0.9 m out | u 0.3-4.9, 23.0-27.6 | M_STONE | rounded corners |
| bow balconies | kit_balcony IRON | 1.2 m, 0.5 m out | 2nd and 3rd floor, each facet | M_STONE | curved iron balconies |
| windows | kit_window ARCHED, SILL | 1-1.8 m | 5 bays, 5 floors | M_PANE | the window rhythm |
| friezes | box + leaf boxes | 18 x 0.8 m | two bands | M_STONE | leafy stone bands |
| canopy | boxes, beams | 3.8 x 1.7 m | over the gate, 4 m up | M_STONE | steel truss |
| shops | kit_shop_bay | 2.4-3 m | east of the gate | M_STONE | ground floor |
| cornice | kit_cornice | 18 m | 20.2 m | M_STONE | top and over the ground floor |
