# App Store Connect: ready answers

Answers for Around Warsaw's App Store Connect forms, for TestFlight now and the App Store
release later. Version 0.1 (build 1), bundle ID `com.olshanskysoft.aroundwarsaw`, team in
`game/export_presets.cfg`. The build: `tools/export_ios.sh` (docs/DEVELOPMENT.md). Field names
follow App Store Connect's English labels as of October 2026; Apple renames things, so match by
meaning. Character limits are Apple's; the counts in brackets were measured (Polish letters
with diacritics count as one character but two bytes, and the keyword field is limited in
bytes).

Facts behind every answer: no accounts, no ads, no purchases, no crash SDK; the only network use is
the beta's anonymous play stats to PostHog EU (docs/STATS.md); saves only on the device (`user://`), haptics only. English is the
default language (the user's choice, 2026-10-29); Polish is the second localization. The game
itself shows Polish above English on every screen.

Google Play's answers are in [play-console.md](play-console.md); the testing notes for both
stores are in [beta-testing.md](beta-testing.md); screenshots in
[screenshots/](screenshots/README.md).

**Needs your accounts (parked, nothing here can do them):** creating the app record, the
support email, the App Review contact (name, phone, email), signing and uploading the build,
adding testers, submitting for Beta App Review. Each is marked ⏸ below.

## 1. New app (Apps → +)

| Field | Answer |
| --- | --- |
| Platforms | iOS |
| Name | **Around Warsaw** |
| Primary language | **English (U.S.)** |
| Bundle ID | `com.olshanskysoft.aroundwarsaw` (register it under Certificates, IDs & Profiles first if Xcode hasn't) |
| SKU | `aroundwarsaw-ios` (yours only, never shown) |
| User access | Full access |

⏸ Needs your Apple developer account.

## 2. App information (General → App Information)

| Field | English (U.S.) | Polish |
| --- | --- | --- |
| Name (30) | **Around Warsaw** (13) | **Around Warsaw** (13) |
| Subtitle (30) | **Drive and fly the real Warsaw** (29) | **Jeźdź i lataj po Warszawie** (26) |

| Field | Answer |
| --- | --- |
| Category | **Games**, subcategories **Racing** and **Simulation** |
| Content rights | **Yes, it contains third-party content, and I have the rights**: the map is OpenStreetMap data (ODbL) and GUGiK data (CC BY 4.0), both credited in the game and in CREDITS.md; the music and sounds are original or synthesised; brands appear only as parodies |
| Age rating | section 6 |
| License agreement | Apple's standard EULA |

Add Polish under "Localizable Information" with the language picker (top right).

## 3. Pricing and availability

Free (price tier 0) · all countries and regions · no pre-orders for the beta. Leave "Make this
app available on Mac (Apple silicon)" and "on Apple Vision Pro" **off**: the touch controls and
the renderer are tested on iPhone only.

## 4. App Privacy

| Question | Answer |
| --- | --- |
| Privacy Policy URL | `https://aroundwarsaw.app/privacy/` |
| User Privacy Choices URL | leave empty |
| Do you or your third-party partners collect data from this app? | **Yes, we collect data from this app** (the beta's anonymous play stats, play_stats.gd, docs/STATS.md, F 2026-11-15) |

Declare three data types, each **Not linked to the user**, **Not used for tracking**, purpose
**Analytics** only:

| Data type (App Store Connect) | What it is in the game |
| --- | --- |
| Usage Data → Product Interaction | sessions, minutes played, jobs and races started and finished, districts and secrets found, setting changes |
| Diagnostics → Performance Data | the frame-rate sample (average and low FPS, draw calls) |
| Identifiers → Device ID | the random install ID the PostHog SDK makes on the phone (no IDFA, no IDFV, no account) |

The label then reads **Data Not Linked to You** (Usage Data, Diagnostics, Identifiers). PostHog's
project discards the IP address on arrival; the game sends the phone's model code (not a unique ID) and strips the language
list before sending. Settings → Dźwięk → "Anonimowa statystyka" turns it off. The website's beta
form is the website's, not the app's, and the privacy page describes it separately.

**Privacy manifest.** Godot's iOS export writes `PrivacyInfo.xcprivacy` from the preset's
`privacy/` options. Since 2026-11-15 the iOS preset sets `privacy/collected_data/
{product_interaction,performance_data,device_id}/collected=true`, `linked_to_user=false`,
`used_for_tracking=false`, `collection_purposes=1` (Analytics), which matches the answers above;
`NSPrivacyTracking` stays false, no tracking domains. The required-reason APIs stay as checked in
the export of 2026-10-30 (file timestamps DDA9.1, C617.1; system boot time 35F9.1; disk space
E174.1, 85F4.1). When the first archive is uploaded, still read App Store Connect's email: an
"ITMS-91053: Missing API declaration" warning would name a reason to add in the export preset.

## 5. Export compliance (asked for every build)

**The app uses no encryption beyond what's exempt** (its only network use is HTTPS to PostHog for the anonymous play stats, which is exempt).
If asked: "None of the algorithms mentioned above". The question doesn't come back with each
TestFlight build, because the iOS preset's `application/additional_plist_content`
(`game/export_presets.cfg`) carries, since 2026-10-30,

```xml
<key>ITSAppUsesNonExemptEncryption</key><false/>
```

next to `CADisableMinimumFrameDurationOnPhone`. Builds exported before that still ask once.

## 6. Age rating (the questionnaire)

Apple's 2025 questionnaire (ratings 4+, 9+, 13+, 16+, 18+). Answers:

| Section | Answer | Why |
| --- | --- | --- |
| In-app controls: parental controls, age assurance | **No / No** | |
| Capabilities: unrestricted web access | **No** | no browser, no links out of the game |
| Capabilities: user-generated content | **No** | |
| Capabilities: messaging and chat | **No** | single player, offline |
| Capabilities: advertising | **No** | |
| Mature themes: profanity or crude humour | **None** | gentle Warsaw jokes, no swearing (warsaw-tone skill) |
| Mature themes: horror or fear themes | **None** | |
| Mature themes: alcohol, tobacco or drug use or references | **None** | the 3 a.m. delivery is kebab; nobody drinks, the night is safe (docs/design/vision.md pillar 5) |
| Medical or treatment-focused content | **None** | the helicopter flies rescue calls, nothing medical is shown |
| Sexual content or nudity, graphic sexual content | **None** | |
| Violence: cartoon or fantasy violence | **None** | cars bump cars, kerbs and barriers; nobody is ever hurt, pedestrians and pigeons can't be hit |
| Violence: realistic violence, prolonged graphic or sadistic violence, guns or other weapons | **None** | the police are comic: a speed trap, the lizak, a talking-to, never a fine, no weapons |
| Chance-based activities: simulated gambling, contests, loot boxes | **None** | the złoty you earn buys nothing real |
| Unrestricted web access / gambling (real money) | **No** | |

Expected rating: **4+**. If you prefer to count the car bumping as cartoon violence,
"Infrequent/Mild" gives 9+; both are honest.

## 7. The version page (iOS App → 0.1 Prepare for Submission)

### English (U.S.)

**Promotional text** (170; this is 139, can change without a new build):

```
The real centre of Warsaw, street by street. Drive a small car or fly a helicopter by day, at night and in the rain. Free, no ads, offline.
```

**Description** (4000):

```
Around Warsaw is an arcade drive in a small car (and a rescue helicopter) through the real centre of Warsaw, built street by street from open map data.

From Śródmieście to the National Stadium: the Palace of Culture, Marszałkowska, Rondo Dmowskiego, Varso Tower, Poniatowski Bridge and the Vistula, which you'd better not test with your wheels.

• Kebab at 3 a.m., the Sunday run with słoiki (jars of Mum's cooking) and Podwózka, the ride app that trusts its GPS more than it trusts you.
• Helicopter rescues and street races against the locals. Seba from Praga is already revving.
• Traffic that keeps to its lights, trams, pedestrians and pigeons in no hurry at all.
• Day, dusk, night and rain, or the real sun over Warsaw right now: neon, street lamps, wet streets and the Palace floodlit.
• The police are here, with a sense of humour: speed traps, the lizak, a little talk. No fine, ever. A caution, maybe.
• A car radio and a city that keeps talking back, in Polish with English.

No ads, no purchases, no account, nothing about you collected (anonymous play stats in the beta, off in Settings). A free, open-source fan game made out of love for Warsaw. Every brand in it is a parody.

The Marszałkowska roadworks continue. You keep driving.

Map data © OpenStreetMap contributors (ODbL) and GUGiK.
```

**Keywords** (100 bytes; this is 95; the name and subtitle are indexed already, so no
"warsaw", "drive" or "fly"):

```
warszawa,poland,city,driving,car,taxi,helicopter,police,kebab,arcade,isometric,offline,tram,map
```

**Support URL:** `https://aroundwarsaw.app/support/` · **Marketing URL:** `https://aroundwarsaw.app/`

**What's New** (first version: not shown; for later builds see beta-testing.md).

### Polish

**Promotional text** (170; this is 140):

```
Prawdziwe centrum Warszawy, ulica po ulicy. Jedź małym autem albo leć helikopterem w dzień, nocą i w deszczu. Za darmo, bez reklam, offline.
```

**Description:**

```
Around Warsaw to zręcznościowa jazda małym autem (i helikopterem ratunkowym) po prawdziwym centrum Warszawy, zbudowanym ulica po ulicy z otwartych danych map.

Od Śródmieścia po Stadion Narodowy: Pałac Kultury, Marszałkowska, Rondo Dmowskiego, Varso, Most Poniatowskiego i Wisła, której lepiej nie sprawdzać kołami.

• Kebab o trzeciej w nocy, niedzielny kurs ze słoikami i Podwózka, aplikacja, która ufa GPS-owi bardziej niż Tobie.
• Akcje ratunkowe helikopterem i wyścigi z miejscowymi. Seba z Pragi już grzeje silnik.
• Ruch, który staje na światłach, tramwaje, piesi i gołębie, którym nigdzie się nie spieszy.
• Dzień, zmierzch, noc i deszcz albo prawdziwe słońce nad Warszawą: neony, latarnie, mokre ulice i podświetlony Pałac.
• Policja jest, ale z humorem: suszarka, lizak, pogadanka. Mandatu nie będzie. Pouczenie owszem.
• Radio w aucie i miasto, które ciągle coś do Ciebie mówi, po polsku i po angielsku.

Bez reklam, bez zakupów, bez konta, bez danych o Tobie (w becie anonimowe statystyki, do wyłączenia w Ustawieniach). Darmowa gra fanowska open source, zrobiona z miłości do Warszawy. Wszystkie marki w grze to parodie.

Remont Marszałkowskiej trwa. Ty jedź.

Dane mapy © współtwórcy OpenStreetMap (ODbL) i GUGiK.
```

**Keywords** (100 bytes; this is 98):

```
warszawa,wawa,polska,miasto,jazda,auto,taxi,helikopter,policja,kebab,tramwaj,most,mapa,offline,gra
```

**Support URL:** `https://aroundwarsaw.app/support/` · **Marketing URL:** `https://aroundwarsaw.app/pl/`

### Both languages

| Field | Answer |
| --- | --- |
| Screenshots | iPhone 6.9" display, landscape **2868 × 1320**, up to 10: `screenshots/appstore-iphone-6.9/` (Apple scales them for the smaller iPhones). iPad 13" display **2752 × 2064**: `screenshots/appstore-ipad-13/`, required while the preset targets iPad (section 10). Same images for both languages: the game shows Polish above English on screen anyway |
| App previews (video) | none for the beta |
| Copyright | `2026 Liubomyr Olshanskyi` |
| Version | 0.1 |
| Build | the uploaded build (⏸) |
| Routing app coverage file | none |

### App Review information

| Field | Answer |
| --- | --- |
| Sign-in required | **No** |
| Contact | ⏸ your name, phone and email (not written here: the repo is public) |
| Notes | below |

```
Around Warsaw is a free, offline, single-player arcade driving game set in the real centre of Warsaw, Poland, built from OpenStreetMap and GUGiK (Polish surveying office) open data, credited in the game. No account, network, ads, purchases or data collection.

How to play: drag the stick on the left to drive (or switch control scheme in Settings, the gear in the top-left corner). HELI switches to the helicopter. Side jobs and rescue calls appear on their own; RADIO changes the station.

Real place names are used as places. Every business, brand and logo in the game is an invented parody. The police are comic (a talking-to, never a fine, no weapons). On-screen text is Polish with English underneath.
```

## 8. TestFlight

| Field | Answer |
| --- | --- |
| Beta App Description (EN) | `Drive and fly the real centre of Warsaw: a small car, a rescue helicopter, side jobs, gentle police and a car radio, by day, at night and in the rain. This is an early test build: tell us what breaks and what feels wrong.` |
| Feedback email | ⏸ your support address |
| Marketing URL | `https://aroundwarsaw.app/` |
| Privacy Policy URL | `https://aroundwarsaw.app/privacy/` |
| Beta App Review: sign-in required | No |
| Beta App Review: contact | ⏸ as in App Review information |
| Beta App Review: notes | the same text as App Review's notes |
| What to Test | per build, from [beta-testing.md](beta-testing.md) (EN and PL; 4000 characters) |

**Testers.** Internal testers (up to 100 people on your App Store Connect team) get builds at
once, without review. External testers (up to 10,000) need the first build of each version to
pass Beta App Review (usually under a day). Make one external group, "Warsaw locals", turn on its
**public link**, and put that link on aroundwarsaw.app (site/README.md, "When the betas have
public links"). The website's beta form collects emails for invites until then.

## 9. Before the first TestFlight upload

- [ ] ⏸ The app record exists (section 1), Polish added (section 2).
- [ ] The build was exported after 2026-10-30, so it carries the encryption key (section 5).
- [ ] `tools/export_ios.sh`, open `build/ios` in Xcode, Product → Archive, Distribute App →
      App Store Connect → Upload (⏸ signing).
- [ ] Read App Store Connect's email after processing: privacy manifest warnings (section 4).
- [ ] Install from TestFlight on the iPhone, play ten minutes (beta-testing.md checklist).
- [ ] Check `https://aroundwarsaw.app/support/` and `/privacy/` open.

## 10. Open question: iPad

`game/export_presets.cfg` sets `application/targeted_device_family=2` (iPhone **and** iPad).
That means the App Store needs iPad screenshots, the game must hold up on iPad (its 4:3 screen,
the HUD layout, the frame rate), and **once a version that supports iPad is on the App Store,
later versions can't drop iPad**. For TestFlight it doesn't matter. Before the first App Store
release, decide: keep iPad (screenshots are rendered, a device pass on an iPad is needed), or set
the preset to iPhone only (value `0`) before the first release.
