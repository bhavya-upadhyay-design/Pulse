# Pulse: blood donation for OneStop

A Flutter prototype of **Pulse**, the blood-donation flows for IITG's OneStop app.
Only the blood-donation flows work. Home is a static copy of OneStop's Home so the
request takeover can be judged in context; Food, Travel and Profile are placeholders.

It uses OneStop's own design system ([`onestop_ui`](https://github.com/swciitg/onestop_ui)):
Geist type scale, `OColor`, `OSpacing` and `OCornerRadius`. Pulse adds one crimson card
language on top, built on OneStop's red scale (`lib/theme/pulse_tokens.dart`).

## Flows

| Flow | Where |
| --- | --- |
| Onboarding: "Become a Lifeline" (blood group, last donated, weight) | `lib/onboarding/` |
| Request takeover on Home: Lifeline Card, countdown, 6-slot "few of us" row, slide to accept | `lib/request/lifeline_card.dart`, `slide_to_accept.dart` |
| Decline with one-tap reasons | `lib/request/decline_sheet.dart` |
| Request details: POC, coordinator, what to expect, rewards, FAQ | `lib/request/request_detail_page.dart` |
| Accepted: live-tracker Event Card pinned on Home, logistics as the admin adds them | `lib/event/event_card.dart` |
| After the slot: "I donated" celebration or "I couldn't make it" | `lib/event/outcome_flows.dart` |
| Recovery Bingo (3×3) with iron-rich mess-meal QR coupon | `lib/bingo/` |
| Quick Access → Blood Donation hub: status, register, Hero Wall, Hostel Cup, history, camps | `lib/hub/` |

## No backend: the NSS console

Tap **NSS console** in the app bar to play the admin and NSS coordinator side: raise a
request, have other students accept, schedule the slot, send the pickup, mark the slot
passed, confirm the donation, and so on. All state lives in `lib/state/pulse_store.dart`.

## Run

```bash
flutter pub get
flutter run            # Android / iOS
flutter run -d chrome  # web; shows the app in a phone frame on wide screens
```

Jump to a state with `?scene=` on web: `onboarding` (default), `home`, `request`,
`critical`, `event`, `outcome`, `bingo`. Add `a11y=1` to turn on the semantics tree.
