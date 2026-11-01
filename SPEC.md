# Pencraft — App Specification
**App slug:** `invoice-maker` | **Package:** `com.isaac.pencraft`  
**Date:** 2026-11-01 | **Version:** 1.0 (MVP)

---

## 1. Design Concept

Pencraft lives at the crossroads of a well-kept paper ledger and a small-batch print studio. Every surface is warm and tactile — the off-white of laid paper, the depth of good ink, the satisfying thud of a rubber stamp. Nothing here looks like fintech. There are no cold gradients, no floating neon glows, no default Material teal. The UI feels like the tools a thoughtful person would choose: deliberate, well-made, built to last. On dark mode, the metaphor shifts to a desk lamp burning late — amber warmth on deep paper-brown, not an inverted light theme. Every number aligns with tabular figures. Documents feel like real paper. The paid stamp lands with weight.

---

## 2. Name Rationale

### Candidates Evaluated

| # | Name | Notes |
|---|------|-------|
| 1 | Stampd | "Stamp: Invoice & Logo Maker" and "Stampcrest: Invoice & Receipt" already exist on Play Store. Adjacent risk. |
| 2 | Folio | "Folio – Invoices" and "FolioGo – Invoice & Business" already exist on Play Store for invoicing. Rejected. |
| 3 | Tally | Tally Solutions (TallyPrime) is a dominant accounting brand across South Asia and East Africa. Major conflict. Rejected. |
| 4 | **Pencraft** ✅ | No active Pencraft invoice app. Pen = writing/documenting; Craft = quality and care. Evokes the physical act of making a document. Clear Play Store path. |
| 5 | Markpaid | Descriptive and action-oriented, zero conflicts. Backup option if Pencraft conflicts emerge. |

**Winner: Pencraft.** Short, pronounceable, ownable, evokes the physical craft of writing and documenting. The "pen" root grounds it in paper culture; "craft" signals quality without pretension.

**Package ID:** `com.isaac.pencraft`  
**Play Store name:** `Pencraft – Invoice Maker`

---

## 3. MVP vs Post-MVP

### In MVP (M1–M4)
- Invoice and estimate creation, editing (incl. after sending), duplication, deletion, conversion
- Client management (name, phone, email, address, KRA PIN, notes)
- Saved items/services library (name, unit, default rate, tax)
- Line items: qty, rate, unit, per-line or global tax, inclusive/exclusive tax, percent/flat discount
- Smart numbering: INV-2026-001 format, custom prefix, auto-increment, reset per year
- Payment terms and due dates; status derived (overdue computed, not stored)
- Business profile: logo, name, address, contact, tax ID, default currency (KES), default VAT (16%), payment instructions (M-Pesa, bank, PayPal), hand-drawn signature, default notes/terms
- Multi-currency per document; correct formatting/rounding; integer minor units
- 3 PDF templates (original designs); accent colour picker; bundled Unicode font (Noto Sans)
- Multi-page PDF; share to WhatsApp/email/any app; save to Files; print
- Partial and full payment recording: date, method, running balance, payment history
- Dashboard: outstanding, overdue, paid this month; animated count-up totals
- Backup/restore to local file; CSV export (Pro only)
- Onboarding: 4-step business profile wizard (skippable)
- Monetization: free tier (5 docs/month, 1 template, small footer, 1 banner ad), Pro (unlimited, all templates, no footer/ads, logo+signature on PDF, CSV, backup)
- RevenueCat MOCK mode; TEST AdMob IDs
- Privacy policy draft; Data Safety answers

### Post-MVP (noted for future)
- Recurring invoices and scheduled sending
- Push notification reminders (overdue, payment received)
- Cloud sync / multi-device
- Online card payment processing (Stripe, M-Pesa Daraja API)
- Client portal (view/pay invoice online)
- Expense tracking and receipt scanning
- Multiple business profiles
- Team accounts with roles
- QuickBooks / accounting software export
- Change orders (estimate revisions with version history)

---

## 4. Screen Inventory & Navigation Map

### Bottom Tabs (4)
1. **Documents** — invoice and estimate list with header dashboard
2. **Clients** — client directory
3. **Items** — saved items/services library
4. **Settings** — profile, preferences, monetization, data

### Screen List (18 screens)

| ID | Screen | Tab | Notes |
|----|--------|-----|-------|
| S01 | Onboarding (4 steps) | – | Skippable; sets up business profile |
| S02 | Document List | Documents | Dashboard header + list with status chips |
| S03 | Document Detail | Documents | View, share, pay, duplicate, delete, convert |
| S04 | Document Creator | Documents | Form + live paper preview below |
| S05 | PDF Full Preview | Documents | Hero animation from preview card |
| S06 | Template Chooser | Documents | 3 templates; 2 locked for free |
| S07 | Client List | Clients | Search + sort |
| S08 | Client Detail | Clients | Info + document history |
| S09 | Client Editor | Clients | Create/edit |
| S10 | Item List | Items | Search + sort |
| S11 | Item Editor | Items | Create/edit |
| S12 | Settings (main) | Settings | All settings groups |
| S13 | Business Profile Editor | Settings | Logo, signature, address, VAT, currency |
| S14 | Payment Instructions Editor | Settings | M-Pesa, bank, PayPal, other |
| S15 | Paywall / Upgrade | – | Triggered contextually |
| S16 | Backup & Restore | Settings | Export/import JSON |
| S17 | Privacy Policy | Settings | Markdown rendered in-app |
| S18 | Accent Colour Picker | Documents | Per-document or global default |

---

## 5. Key Flows

### Flow A: Create Invoice in Under 60 Seconds
1. Tap **+** on Document List
2. Select **Invoice** (or Estimate)
3. Type client name → autocomplete from saved clients or inline-create
4. Add line items: search saved items or type new; qty and rate auto-filled from library
5. Review live preview below form (updates on each keystroke)
6. Tap **Send** → choose WhatsApp / Email / Copy Link / Save PDF
7. WhatsApp: PDF attached + pre-written message in English/Swahili; opens WhatsApp share sheet

### Flow B: Mark Invoice Paid
1. Open Document Detail
2. Tap **Record Payment**
3. Enter amount (full or partial), date, method (M-Pesa, bank, cash, etc.)
4. Confirm → rubber stamp animation plays over the document header + `HapticFeedback.heavyImpact()`
5. Status chip updates to **Paid** (or **Partial** if amount < total)

### Flow C: Convert Estimate to Invoice
1. Open Estimate Detail
2. Tap **Convert to Invoice**
3. Confirm dialog (with option to keep or generate new number)
4. Navigates to the new Invoice (estimate preserved, not deleted)

### Flow D: Onboarding
1. **Step 1:** Business name + your name (text fields)
2. **Step 2:** Logo (image picker, optional) + address
3. **Step 3:** Payment instructions — M-Pesa paybill/till, bank account, PayPal
4. **Step 4:** Default currency (KES pre-selected) + VAT rate (16% pre-filled)
5. Skip anytime; revisitable from Settings

---

## 6. Data Model

> Money stored as integer minor units (e.g. KES 1,500.00 = 150000). Rates stored as basis points (16% = 1600 bps). Timestamps as Unix epoch (seconds).

### Tables

**business_profiles**
- `id` INTEGER PK
- `name` TEXT
- `owner_name` TEXT
- `address` TEXT
- `phone` TEXT
- `email` TEXT
- `tax_id` TEXT (KRA PIN)
- `logo_path` TEXT
- `signature_path` TEXT
- `currency_code` TEXT DEFAULT 'KES'
- `default_tax_rate_bps` INTEGER DEFAULT 1600
- `tax_inclusive` INTEGER DEFAULT 0
- `payment_instructions` TEXT (JSON: mpesa, bank, paypal, other)
- `default_notes` TEXT
- `default_terms` TEXT
- `created_at` INTEGER

**clients**
- `id` INTEGER PK
- `name` TEXT NOT NULL
- `phone` TEXT
- `email` TEXT
- `address` TEXT
- `tax_id` TEXT (KRA PIN)
- `notes` TEXT
- `deleted_at` INTEGER (soft-delete; null = active)
- `created_at` INTEGER

**items** (saved items/services library)
- `id` INTEGER PK
- `name` TEXT NOT NULL
- `description` TEXT
- `unit` TEXT DEFAULT 'item'
- `unit_price_minor` INTEGER DEFAULT 0
- `tax_rate_bps` INTEGER (null = use global)
- `currency_code` TEXT
- `created_at` INTEGER

**documents**
- `id` INTEGER PK
- `type` TEXT ('invoice' | 'estimate')
- `number` TEXT UNIQUE
- `client_id` INTEGER FK → clients
- `currency_code` TEXT
- `tax_mode` INTEGER (0=exclusive, 1=inclusive)
- `discount_mode` INTEGER (0=percent, 1=flat)
- `discount_value` INTEGER (bps if percent; minor units if flat)
- `global_tax_rate_bps` INTEGER
- `deposit_minor` INTEGER DEFAULT 0
- `status_override` TEXT (null=auto | 'draft' | 'sent' | 'paid' | 'void')
- `issue_date` INTEGER (epoch)
- `due_date` INTEGER (epoch; null=on receipt)
- `notes` TEXT
- `terms` TEXT
- `template_id` INTEGER DEFAULT 1
- `accent_colour` TEXT
- `created_at` INTEGER
- `updated_at` INTEGER

> Derived status logic: if `status_override='paid'` → Paid; if `status_override='void'` → Void; if `status_override='draft'` → Draft; else if `due_date < now AND balance > 0` → Overdue; else if sent → Sent.

**line_items**
- `id` INTEGER PK
- `document_id` INTEGER FK → documents
- `item_id` INTEGER FK → items (null = ad-hoc)
- `description` TEXT
- `unit` TEXT
- `quantity_x100` INTEGER (stored ×100 for 2 decimal places, e.g. 1.5 qty = 150)
- `unit_price_minor` INTEGER
- `tax_rate_bps` INTEGER (null = use document global)
- `sort_order` INTEGER
- `created_at` INTEGER

**payments**
- `id` INTEGER PK
- `document_id` INTEGER FK → documents
- `amount_minor` INTEGER
- `payment_date` INTEGER (epoch)
- `method` TEXT ('mpesa' | 'bank' | 'cash' | 'paypal' | 'cheque' | 'other')
- `reference` TEXT (M-Pesa code, bank ref, etc.)
- `notes` TEXT
- `created_at` INTEGER

**settings** (key-value)
- `key` TEXT PK
- `value` TEXT

---

## 7. Monetization Plan

### Free Tier
- Up to **5 documents per month** (invoices + estimates combined)
- **1 template** (Classic Ledger only)
- **"Made with Pencraft"** footer on all PDFs (small, 8pt, tasteful)
- **1 small banner ad** on Document List and Dashboard only
- No ads inside document creation, preview, or PDF flow
- No interstitials, ever

### Pro Tier
- Unlimited documents
- All 3 templates + accent colour picker
- Logo + hand-drawn signature appear on PDFs
- No footer, no ads
- CSV export
- Backup & restore
- Priority email support

### Pricing (proposed; Play Console regional pricing)
| Plan | Global | KES |
|------|--------|-----|
| Monthly | $2.99 | KES 399 |
| Annual | $19.99 | KES 2,499 (7-day free trial) |
| Lifetime | $39.99 | KES 4,999 |

### Paywall Triggers (non-dark-pattern)
1. Creating the **6th document in a calendar month** (paywall appears before creation starts)
2. Tapping a **locked template** (lock icon visible on Template Chooser)
3. **"Upgrade to Pro"** row in Settings (always visible, never nagging)

### Flag Behaviour
| Flag | ON | OFF |
|------|----|----|
| `enablePaywall` | Free limits enforced, paywall shown | Unlimited for all users |
| `enableAds` | Banner on list/dashboard for free users | No ads anywhere |
| `enableIAP` | RevenueCat active | Mock prices shown, no real purchases |

---

## 8. Design Brief

### Colour Palette

#### Light Theme (Paper by Day)
| Role | Token | Hex |
|------|-------|-----|
| Background / Paper | `colorSurface` | `#FAF7F2` |
| Elevated Surface | `colorSurfaceElevated` | `#F3EFE6` |
| Ink (Primary Text) | `colorOnSurface` | `#1A1410` |
| Ink Muted (Secondary) | `colorOnSurfaceMuted` | `#6B5E4E` |
| Seam / Divider | `colorOutline` | `#D4C9B8` |
| Seam Subtle | `colorOutlineVariant` | `#E8E2D8` |
| Accent (Sealing Wax Red) | `colorAccent` | `#C0392B` |
| Accent Surface | `colorAccentSurface` | `#F8EDEC` |
| Success (Paid) | `colorSuccess` | `#1E7D45` |
| Warning (Overdue) | `colorWarning` | `#B35C00` |

#### Dark Theme (Desk Lamp at Night)
| Role | Token | Hex |
|------|-------|-----|
| Background | `colorSurface` | `#1C1914` |
| Elevated Surface | `colorSurfaceElevated` | `#252018` |
| Ink (Primary Text) | `colorOnSurface` | `#EDE5D5` |
| Ink Muted | `colorOnSurfaceMuted` | `#9E8E78` |
| Seam / Divider | `colorOutline` | `#3D3528` |
| Seam Subtle | `colorOutlineVariant` | `#2E2820` |
| Accent | `colorAccent` | `#E05246` |
| Accent Surface | `colorAccentSurface` | `#3D1E1C` |
| Success | `colorSuccess` | `#2ECC71` |
| Warning | `colorWarning` | `#E8922A` |

### Typography

**Heading font:** DM Serif Display (serif, editorial weight) — used for document numbers, totals, display headings  
**Body font:** Inter (humanist sans, variable) — used for all UI text  
**Monospace (amounts):** Inter with `FontFeature.tabularFigures()` — amounts always column-aligned

**Scale (4 sizes + display):**
| Name | Size | Weight | Usage |
|------|------|--------|-------|
| `displayLarge` | 32sp | DM Serif 400 | Dashboard total, document amount |
| `titleLarge` | 20sp | Inter 600 | Screen headers, invoice number |
| `bodyLarge` | 16sp | Inter 400 | Client name, line item description |
| `bodyMedium` | 14sp | Inter 400 | Secondary info, metadata |
| `labelSmall` | 11sp | Inter 500 | Status chips, footer |

### Shape Language
- **Documents/cards:** 4dp radius (paper-like, minimal rounding)
- **Buttons:** 8dp radius
- **Bottom sheet:** 16dp top corners
- **Chips:** fully rounded (pill)
- **Input fields:** underline style (not boxed) — keeps density high
- **Borders over shadows:** use `colorOutline` borders on cards, not drop shadows; one subtle shadow for floating action elements only

### Icon Set
- **Phosphor Icons** (phosphor_flutter) — consistent weight, humanist style  
- All icons at 24dp standard, 20dp for compact density  
- Optically aligned at tab bar (28dp)

### Motion
| Interaction | Duration | Curve |
|-------------|----------|-------|
| Screen transitions | 250ms | `Curves.easeInOutCubic` |
| Bottom sheet open | 300ms | `Curves.easeOutCubic` |
| List item entry | 180ms | `Curves.easeOut` |
| Count-up animation | 800ms | `Curves.easeOutCubic` |
| Paid stamp | 400ms | `SpringSimulation(stiffness=280, damping=22)` |
| Micro-interactions | 150ms | `Curves.easeInOut` |

### Signature Moments (Implementation Detail)

**1. Paid Stamp Animation**  
A rubber stamp SVG (circular, "PAID" text, stamp border) starts off-screen above, scales from 1.5→1.0 with spring physics, rotates -8° (organic imperfection), ink colour desaturates from vivid accent red over 150ms delay. `HapticFeedback.heavyImpact()` fires on first contact frame. The stamp sits permanently on the invoice header until voided.

**2. Live Paper Preview**  
The document creator is a `CustomScrollView` with form fields in a `SliverList` followed by a `SliverToBoxAdapter` containing `InvoicePreviewCard`. The card mirrors real paper: warm `#FAF7F2` background, 3-layer shadow (ambient 0dp blur / key 4dp blur offset 2dp / colour `#1A1410` at 5% opacity), border radius 4dp. Updates via Riverpod's `formStateProvider` on every field change. Tapping triggers a `Hero` animation to `PdfPreviewPage`.

**3. Dashboard Count-Up**  
`TweenAnimationBuilder<int>` from 0 to final minor-unit value, 800ms, `Curves.easeOutCubic`. Formatted with `intl.NumberFormat.currency()` and `FontFeature.tabularFigures()` so digits don't shift during animation. Fires once per app session on first load.

---

## 9. Technical Notes & Permissions

### Additional Packages (beyond template)
| Package | Version | Justification |
|---------|---------|---------------|
| `pdf` | ^3.11 | Pure Dart PDF generation; no native deps |
| `printing` | ^5.13 | PDF preview widget + print/share |
| `image_picker` | ^1.1 | Logo and photo attachments |
| `image_cropper` | ^7.1 | Crop logo to square |
| `signature` | ^5.4 | Hand-drawn signature capture |
| `file_picker` | ^8.1 | Backup restore, CSV open |
| `phosphor_flutter` | ^2.1 | Consistent icon set |
| `open_filex` | ^4.5 | Open saved PDF in external viewer |

### Permissions
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` (only what image_picker/file_picker require; Android 13+ uses photo/media permissions)
- No camera permission (picker uses system gallery)
- No network permission (app is fully offline-first; no cloud sync in MVP)
- No location, contacts, microphone, etc.

### Money Math Rules
1. Store all values as integer minor units (KES: minor unit = 1 cent → KES 1 = 100 minor units; KES has 2 decimal places per ISO 4217)
2. Tax calculation (exclusive): `tax = round(subtotal_minor × tax_rate_bps / 10000)`
3. Tax calculation (inclusive): `subtotal_excl = round(price_incl × 10000 / (10000 + tax_rate_bps))`; `tax = price_incl - subtotal_excl`
4. Discount (percent): `discount = round(subtotal_minor × discount_bps / 10000)`
5. Discount (flat): stored directly as minor units
6. Final: `total = subtotal + tax - discount`
7. Balance: `balance = total - sum(payments)`
8. Rounding: always `(value + 0.5).floor()` (standard commercial rounding)

### WhatsApp Share
- Generate PDF via `dart:pdf` → write to `path_provider.getTemporaryDirectory()`
- Share via `share_plus` `ShareParams(files: [XFile(pdfPath)], text: message)`
- Pre-written message (English): `"Hi [Client Name], please find your invoice [INV-2026-001] for KES [amount] attached. Payment due [date]. Payment details: [M-Pesa/bank]. Thank you!"`
- WhatsApp intercepts the share intent automatically on Android

---

## 10. Play Store Checklist

### Data Safety Answers
| Question | Answer |
|----------|--------|
| Does this app collect or share user data? | Yes |
| What data is collected? | Device identifiers (AdMob, free tier only) |
| Is data encrypted in transit? | Yes (AdMob SDK uses HTTPS) |
| Is data encrypted at rest? | No (local SQLite; no sensitive PII transmitted) |
| Can users request data deletion? | Yes (delete account / all data in Settings) |
| Is data shared with third parties? | Yes — AdMob (Google) for advertising |

### Privacy Policy Points
- All invoice data stored locally on device only
- No cloud sync or server-side storage in MVP
- AdMob collects device identifiers for ad targeting (free tier only)
- No personal data sold to third parties
- Users can export and delete all data from within the app

### Content Rating
- PEGI 3 / Everyone — business productivity app, no user-generated content risks

### In-App Disclaimer
> "Pencraft helps you create and send documents. It does not provide tax or legal advice. Consult a qualified professional for your business's tax and legal obligations."

---

## 11. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| "Pencraft" name conflict discovered post-launch | Low | High | Monitor; fallback name "Markpaid" already vetted |
| Multi-page PDF layout bug | Medium | Medium | Dedicated test: 30 line items, very long descriptions |
| KES tax rounding discrepancy | Medium | High | Unit tests for all inclusive/exclusive/rounding cases |
| dart_pdf performance on low-end phones | Low | Medium | Run on physical phone; cache PDF on disk |
| RevenueCat prod keys not available at launch | N/A | Low | MOCK mode functional; real keys added at Play Console submission |
| WhatsApp share_plus requires WhatsApp installed | Low | Low | Fallback: "Copy link" or general share sheet |
| Signature capture UX on small screens | Medium | Medium | Test on small phone (5" class); padding adjustments |

---

## 12. Acceptance Criteria

### M1 — Skeleton & Data
- [ ] All 4 tabs navigable, all screens reachable
- [ ] App identity applied (Pencraft palette, DM Serif + Inter, not default Material)
- [ ] Drift DB initialises; seed data visible (3 clients, 8 items, 6 documents with real Kenyan names)
- [ ] Status chips computed correctly: Overdue shown for past-due documents
- [ ] Dashboard totals animate on first view

### M2 — Core Document Lifecycle
- [ ] Invoice created and shared to WhatsApp in under 60 seconds (tested)
- [ ] Live preview updates on every field change
- [ ] PDF renders correctly for 1-item, 30-item (multi-page), and long-description invoices
- [ ] Paid stamp animation plays with haptic feedback
- [ ] Edit-after-sending works (status does not lock form)
- [ ] All money math unit tests pass (inclusive tax, rounding, partial payment balance)

### M3 — Onboarding, Settings, Monetization
- [ ] Onboarding sets business profile; skippable from any step
- [ ] `enablePaywall=true`: 6th document in month triggers paywall
- [ ] `enablePaywall=false`: unlimited documents
- [ ] `enableAds=true`: banner visible on Document List + Dashboard; absent from creator/preview
- [ ] `enableAds=false`: no ads anywhere
- [ ] Pro mock purchase unlocks all features
- [ ] Backup file created and restored correctly

### M4 — Polish & Release Prep
- [ ] `flutter analyze` — zero issues
- [ ] Dark mode: all colours correct, no system defaults showing
- [ ] Text at 200% scale: no overflow, no truncation
- [ ] Small phone (360dp width): all layouts functional
- [ ] Launcher icon: vector adaptive, no letters, readable at 48dp
- [ ] Release APK installs and runs on physical phone
- [ ] No debug prints, no TODO comments in shipped code
- [ ] BUILD_LOG.md complete and accurate
