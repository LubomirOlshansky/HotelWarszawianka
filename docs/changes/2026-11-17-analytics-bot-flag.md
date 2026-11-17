## Backlog
- found: PostHog (project 351865, EU) marks every beta event `$virt_is_bot=true` and `$virt_traffic_type="Automation"`, so any bot-filtered view shows 0 players. Likely cause: the posthog-godot SDK's user agent (unconfirmed). To investigate later, not fix now: confirm the cause, then set a normal user agent or override the property in the SDK call, and check the dashboard filters
- found: the events `heli_landed`, `garage`, `save_problem` and `stats_off` never appear in PostHog data. To check later whether they are wired and fired, or only defined
