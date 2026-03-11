# Services Seed

This folder contains seed-ready taxonomy data extracted from `services provider.pdf`.

- File: `services_catalog.json`
- Structure: `categories[]` with nested `subcategories[]`

## Recommended seed flow

1. Run `amplify push` to deploy schema changes.
2. Use AppSync query/mutation console or a script to:
   - create `ServiceCategory` rows from `categories[]`
   - create `ServiceSubcategory` rows linked via `categoryId`
3. Provider onboarding in provider app should create `ProviderServiceOffering` records for selected subcategories.

## Notes

- Existing `Category` model is kept for backward compatibility in the current customer app.
- New taxonomy models are `ServiceCategory` and `ServiceSubcategory`.
