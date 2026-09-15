# KalaSetu — Clean UI (Screens 4 & 5)

This `ui/` folder intentionally contains only:
- Screen 4: Artisan Approval
- Screen 5: Outward / Bazaar
- Their routes, reusable widgets, theme, and localization helpers

There is no Screen 2 or Screen 3 implementation here.

## Integration

The screens use Flutter Material and `google_fonts`.

Add the dependency if it is not already present:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: any
```

Set the app entry route to `AppRoutes.approval`, or use:

```dart
MaterialApp(
  theme: buildKsTheme(),
  onGenerateRoute: AppRoutes.onGenerateRoute,
  initialRoute: AppRoutes.approval,
);
```

## End-to-end interactions

Screen 4:
- back
- profile
- listing ID
- provenance audio action
- geotag card
- Edit Details / Mark Verified
- Approve & Publish → Screen 5
- bottom navigation → Screen 5 from Bazaar

Screen 5:
- back
- profile
- listing card
- toolkit
- A4 / story / voice actions
- WhatsApp share state
- all marketplace switches
- officer contact
- dispatch card
- Create Another Product → Screen 4
- bottom navigation → Screen 4 from Kala List

Both screens are vertically scrollable with AlwaysScrollableScrollPhysics.
