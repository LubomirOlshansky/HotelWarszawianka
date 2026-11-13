- New driving controls: two see-through arrows in the bottom left corner steer, and the GAS and BRAKE pedals sit in the bottom right corner, always in the same place. A quick tap on an arrow steers a little and holding it turns all the way. The old slide-to-steer controls are still in Settings → Driving → Controls ("Slider").
- Lane assist is now on for everyone: when you are not steering, the car gently holds its lane. You can switch it off in Settings → Driving.

## Backlog
- found: testers find the car hard to drive. Causes from the code (F, 2026-11-13): the slide-to-steer strip had no fixed place and full lock only 1.5 cm from where the thumb landed; BRAKE was small and right next to GAS; the camera turns the whole city with the car at up to 64°/s; nothing held the car straight (lane assist was off). The arrows, bigger pedals and lane assist on by default deal with the first, second and fourth; a calmer camera is still open (F's pick)
- found: the ghost finger's hint shows two languages (Polish over English) in every layout; one language only is the rule

## Roadmap
- added and ticked: "Fixed see-through arrows + GAS / BRAKE pedals as Classic's default touch controls, the slide strip kept in Settings → Jazda → Sterowanie; lane assist on by default, switch in Settings (F, 2026-11-13; `check_hud` arrows, `check_settings`; phone feel open)"
