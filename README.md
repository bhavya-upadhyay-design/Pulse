# Pulse: blood donation for OneStop

A Flutter prototype of the blood-donation flows for IITG's OneStop app, built
from the Figma section "Screens" (file *Others*, node `1810:3556`).

- **Base app:** OneStop Home rebuilt from the onestop_flutter source in its
  dark theme (Time Table, Food, Gatelog, Quick Access, Quick Links, bottom nav).
  Only the Blood donation entry works; other tiles and tabs are stubs.
- **From the Figma, copied 1:1:** the *New request widget* (Home, in place of
  the Time Table card), the *Blood donation* Quick Access tile, and the blood
  section with its own bottom nav: **My Donations**, **Explore**, **Hero wall**.
- **Built in the same style:** request details, decline reasons, the accepted
  event card with NSS updates, donated / couldn't-make-it outcomes, the hero
  moment, Recovery Bingo with a mess-meal QR coupon, Learn articles,
  certificates and the "Become a Lifeline" onboarding.

## Design sources

| Code | Figma |
| --- | --- |
| `lib/theme/bd.dart` | colours, radial gradient and type sizes from the frames |
| `lib/blood/widgets/request_widget.dart` | New request widget `1810:8384` |
| `lib/blood/blood_shell.dart` | header + nav pill `1810:6433` |
| `lib/blood/tabs/my_donations_tab.dart` | My donations `1810:6337` |
| `lib/blood/tabs/explore_tab.dart` | Explore `1810:6450` |
| `lib/blood/tabs/hero_wall_tab.dart` | Hero wall `1810:8200` |
| `assets/blood/` | icons, illustrations, avatars and hostel art exported from the file |

Fonts: the Figma uses Uber Move, which is proprietary and can't be bundled, so
blood-donation text uses OneStop's Geist at the same sizes and weights. The
leaderboard uses Figtree as in the file (SIL Open Font License, `assets/fonts/`).

## No backend: the NSS console

Tap **NSS** in the top bar to play the admin and NSS coordinator: raise a
request, have others accept, schedule the slot, send the pickup, mark the slot
passed, confirm the donation. State lives in `lib/state/pulse_store.dart`.

## Run

```bash
flutter pub get
flutter run            # Android / iOS
flutter run -d chrome  # web; shown in a phone frame on wide screens
```

On web, start at a state with `#scene`: `onboarding` (default), `home`,
`request`, `critical`, `event`, `outcome`, `bingo`, `blood`, `explore`,
`herowall`. Add `?a11y=1` to turn on the semantics tree.
