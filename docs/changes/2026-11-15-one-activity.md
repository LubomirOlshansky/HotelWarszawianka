- During a tour, a race or a job, M (or the pad's A) and the helicopter list no longer start a rescue call on top of it.
- The ✕ ends one thing at a time.
- A rescue call card nobody answers now goes away by itself after 12 seconds.

## Backlog
- fixed: M and the pad's A offered a rescue call while another activity (a tour, a race, a job) was on
- fixed: the HELI list's rescue call and Pan Paw rows started a call while another activity was on (the rows are not listed then)
- fixed: one ✕ ended every activity that had a run up at once (it goes through the activity director to the first that takes it)
- fixed: the rescue line's TRY AGAIN started a second run over the failed one, and no rescue run ever told the other activities it had ended
- fixed: the rescue line's call card stayed up for ever, holding every other call; it has the kit's life now (12 s, the next call in half the wait)
- found: the rescue's result card (URATOWANI / ZA PÓŹNO) has no put-back if something else takes it down (the kit's put-back is for cards of the run shown with `show_card`; the line shows it itself)
- found: a run started past the director (a questline's meeting, a test flag) can still be up beside another; the ✕ then takes the first in the director's order, which may not be the one whose status line shows
