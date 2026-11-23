- Nothing changes on the page for visitors; the author now sees, for every beta signup and feedback message, which country and city it came from and which language the browser uses.

## Backlog
- found: the signup stored the country already, but the language was empty (the page never sent it); the Worker now stores the browser language (from the page, else the Accept-Language header) and puts city, region and timezone into `meta`, so they show in the notification mail and the admin CSV. No new fields for the visitor, no migration. Needs the site deploy (F's word) to go live.

## Roadmap
- no change
