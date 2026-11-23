## Backlog
- fixed: session_end.minutes_played counted the whole launch after every return from the background (sums and averages counted minutes twice); heli_pct and the lost-session checkpoint too
- fixed: a focus loss alone (iOS Control Center, a system alert, the Android shade, a Mac window switch) ended a session and began a new one
- fixed: a street race given up with ✕ went out as activity_end how="done"; races now say won, lost or quit
