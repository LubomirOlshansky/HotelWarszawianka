- The website's "open beta" signup now asks which phone you have (iPhone or Android), the website says in the first screen that this is a free game for iPhone and Android, and the game has a OPINIA / WRITE TO THE AUTHOR button in Settings that sends your message (and an email, if you want a reply) straight to the author.

- The site's Worker can now take the signup and the feedback itself (stored in a Cloudflare database and mailed to the game's inbox, no monthly cap); it goes live after F's word.

## Backlog
- found: the website's forms posted to the Formspree form of another project (`mykaeqjp`, Stillplace's contact form); they now post to the Around Warsaw project's own "Website beta signup" form
- found: Formspree's free plan has a monthly limit of submissions; if the signups grow past it, move the signup to the Worker (site/worker.js) with a KV list
- found: the in-game card's layout was written without a Godot or a phone to look at; check it at the phone's sizes (PHONE-CHECK) and on the Mac

## Roadmap
- added: "In-game feedback form" (the beta needs a way for testers to write to the author)
