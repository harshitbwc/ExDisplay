# ExDisplay promo assets

A [Remotion](https://www.remotion.dev/) project that renders the logo, banner and launch
video for ExDisplay. Everything it produces is committed in [`../docs/assets`](../docs/assets)
and served by the project website, so you only need this folder to change or regenerate them.

| Composition | Output | Size |
|---|---|---|
| `Launch` | `launch.mp4`, `poster.jpg` | 1920×1080, 30 fps, about 37 s |
| `Banner` | `banner.png` (README banner, GitHub social preview, Open Graph image) | 1280×640 |
| `LogoMark` | `logo-1024.png` (transparent) | 1024×1024 |
| `LogoLockup` | `logo-lockup.png` | 1600×640 |

`docs/assets/logo.svg` is the same mark as `src/Logo.tsx`; keep the two in sync by hand.

## Preview and render

```bash
npm install
npm run dev            # Remotion Studio
npm run assets         # render everything into ../docs/assets
npm run stills         # logo + banner only
npm run video          # launch video only
```

Rendering uses your installed Chrome (`/Applications/Google Chrome.app` by default). Point it
elsewhere with `CHROME=/path/to/chrome npm run assets`. The scripts pass `--gl=angle`, because
the default GL backend intermittently produced garbled, tiled frames during parallel renders.

## Notes

- The video is an animated overview, not a screen recording; the Mac and tablet are mock-ups.
- It has no soundtrack. If you add music, use something you are licensed to redistribute.
- Remotion is free for individuals and teams of up to 3; see
  [remotion.pro/license](https://www.remotion.pro/license) for company use.
