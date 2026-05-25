---
name: Precision Epicure
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#444748'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1c1b1b'
  on-primary-container: '#858383'
  inverse-primary: '#c8c6c5'
  secondary: '#006e1c'
  on-secondary: '#ffffff'
  secondary-container: '#91f78e'
  on-secondary-container: '#00731e'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#281900'
  on-tertiary-container: '#af7a00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474746'
  secondary-fixed: '#94f990'
  secondary-fixed-dim: '#78dc77'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005313'
  tertiary-fixed: '#ffdeac'
  tertiary-fixed-dim: '#ffba38'
  on-tertiary-fixed: '#281900'
  on-tertiary-fixed-variant: '#604100'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  display-score:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-margin: 24px
  gutter: 16px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 24px
  section-gap: 48px
---

## Brand & Style
The design system is engineered for the discerning diner who values data over hyperbole. The brand personality is **analytical, premium, and decisive**, blending the rigorous clarity of a fintech dashboard with the refined aesthetic of a high-end lifestyle journal.

The visual style is **Modern Minimalism**. It prioritizes high-density information through generous whitespace, razor-sharp typography, and a "utility-first" interface. The emotional goal is to instill **confidence and clarity**, stripping away the sensory overload common in discovery apps to leave only the essential data points required for an informed decision.

## Colors
The palette is rooted in a "Data-Chromatic" logic. The primary **Deep Charcoal (#1A1A1A)** serves as the foundation for all structural elements and primary text, ensuring maximum legibility and a premium feel.

Semantic colors are strictly reserved for score-based feedback:
- **Success (Sage Green, #4CAF50):** Indicates peak performance (8.5–10.0).
- **Warning (Soft Amber, #FFB300):** Indicates standard/mid-tier quality (7.0–8.4).
- **Critical (Dusty Rose, #E57373):** Indicates underperformance (Below 7.0).

The background utilizes **Off-White (#FAFAFA)** for page surfaces to reduce eye strain, while pure white is reserved for cards and elevated components to create subtle tonal separation.

## Typography
The typography system uses a tri-font approach to categorize information types:
- **Headlines (Hanken Grotesk):** Provides a sharp, modern, and authoritative voice for titles and brand moments.
- **Body (Inter):** Used for all descriptive text, providing a neutral, systematic, and highly readable experience.
- **Metadata (JetBrains Mono):** Introduced for technical data points, addresses, and secondary scores to lean into the "analytical" fintech aesthetic.

**Numeric Treatment:** All numerical scores above 8.0 should use `display-score` for maximum impact. Letter spacing is tightened on large headlines to maintain a compact, "designed" feel.

## Layout & Spacing
This design system utilizes a **Fixed Grid** philosophy for desktop (12 columns, 1120px max-width) and a **Fluid Content** model for mobile. 

A strict 8px linear scale governs all padding and margins. Vertical rhythm is maintained by using `stack` variables:
- **Stack-sm (4px):** Related label and data point.
- **Stack-md (12px):** Headline and supporting body text.
- **Stack-lg (24px):** Between distinct content blocks within a card.

Margins on mobile are set to 24px to provide a generous "premium" frame around content, preventing the UI from feeling cluttered.

## Elevation & Depth
To maintain a minimalist aesthetic, depth is communicated through **Tonal Layering** and **Soft Ambient Shadows**.

- **Level 0 (Background):** #FAFAFA.
- **Level 1 (Cards/Sheets):** Pure White (#FFFFFF) with a 1px border of #EEEEEE.
- **Shadows:** Use a "Fintech Glow"—an ultra-diffused shadow with 4% opacity, 20px blur, and 4px vertical offset. Avoid heavy shadows; the goal is to make elements feel like they are resting lightly on a surface rather than floating high above it.
- **Interactions:** On hover or tap, cards should not lift higher; instead, the border color should darken to the primary charcoal (#1A1A1A) for a precise, tactical response.

## Shapes
The shape language is **Structured yet Approachable**. All primary cards and containers utilize a 16px (1rem) radius. 

Smaller interactive elements like buttons and input fields follow the `rounded-lg` (1rem) specification to maintain consistency with the cards. Only score badges and specific "status" chips may use the `rounded-xl` (1.5rem) or pill-shape to distinguish them from structural layout containers.

## Components
- **Score Cards:** The centerpiece component. White background, 16px radius, featuring a `display-score` in the top right. Scores are color-coded using the semantic palette.
- **Primary Buttons:** Solid #1A1A1A background with white text. High-contrast, no gradients, sharp corners (1rem radius).
- **Secondary Buttons/Chips:** Ghost style with #1A1A1A 1px borders and `label-caps` typography.
- **Input Fields:** Minimalist design with only a bottom border (2px) that transitions from #EEEEEE to #1A1A1A on focus. No background fill.
- **Data Tables:** Used for restaurant breakdowns (Price, Noise, Service). These use `data-mono` typography and 8px gutters for a dense, spreadsheet-inspired look.
- **Score Badges:** Small circular or pill-shaped indicators that appear in list views, always utilizing the semantic color as a background with white text.