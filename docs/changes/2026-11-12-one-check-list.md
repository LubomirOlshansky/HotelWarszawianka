## Backlog
- fixed: TD-18, a new check is one line in tools/ci_steps.txt and its case in tools/verify.sh; verify.sh reads its step lists from that file
- fixed: 26 verify steps that CI never ran now run there (21 in quick; tunnelcut, roadworks-prebuilt, oldtowndrive and railsignals with the prebuilt city, since they need the map; firstlife with the runtime runs); 16 long runs are marked local
- found: lanedrive-grounded (about 4 min) is still local only; it could join the full set once the runtime city is built once per shard
