## Material 3 UI — Global (All Projects)

Build all Flutter web admin panel UIs following the [Material Design 3 spec](https://m3.material.io/components). Components, theming, colors, and interaction patterns from M3 are the default across all projects.

## SecuroApp — Auth Card (Big Screens Only)

Auth screen cards on wide screens (>600px) use:

- `shadowColor: Colors.black.withValues(alpha: 2)`
- `borderRadius: BorderRadius.circular(30)`
- `padding: EdgeInsets.all(40)`
- `maxWidth: 480` (constrained, centered)
- Card only shows on wide screens — **never on mobile**
