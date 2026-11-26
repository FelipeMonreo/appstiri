# Reader design system

This redesign implements the approved UNITBV-inspired header and light/dark palettes sampled from the Student@UNITBV screenshots, large controls and smooth article opening. The feed is a task surface; the article is a reading surface. Product facts and constraints are in [PRODUCT.md](PRODUCT.md).

## Visual direction

Știri UNITBV is a compact reader powered by Hacker News. The header language button switches the interface between Romanian and English for the current session. Article titles and summaries keep their source language. Scrollbars stay hidden across the app. The feed starts with the actual list of stories and gives each card equal emphasis. The header combines the UNITBV mark, app title, language selector and refresh. Favorites keeps calendar export above the saved list. The white UNITBV mark is bundled from the [university website](https://unitbv.ro/images/Logo-UT-s.png) and displayed in the app header and launch animation. Navigation is in the bottom bar on phones and the top bar when width and text scaling allow.

The owner reads on a phone in changing ambient light. System brightness chooses the palette; there is no independent app setting to fall out of sync.

| Role | Light | Dark |
| --- | --- | --- |
| Page | `#F3EEF5` | `#121212` |
| Surface | `#FEF7FF` | `#212121` |
| Accent and filled actions | `#0064A0` | `#EF9348` |
| Text | `#17233A` | `#F4F5F7` |
| Secondary text | `#526078` | `#B9BEC8` |

`lib/theme/app_theme.dart` is the implementation authority. Components use semantic ColorScheme roles. Status and error colors remain distinct so recovery messages retain their meaning.

## Type and layout

- UT Sans supplies headlines, controls and reading text. Regular, Medium and Bold are bundled from the supplied TTF archive.
- Reading text is 18 logical pixels with 1.75 line height. System text scaling remains enabled. Headlines wrap; essential article titles are not truncated.
- Rounded cards use a clear surface, a thin outline, and 12 logical pixels between cards. The title opens details. Bookmark and source icons have tooltips and touch targets of at least 48 logical pixels. Calendar export retains its visible label.
- The feed uses lazy slivers and a 1064-pixel maximum width. The domain, author and publication date sit below the title. Desktop cards align the activity and actions beside the headline. At narrow widths or enlarged text, the title uses the full card width and activity and actions sit underneath. The reader has a 768-pixel maximum width.
- The calendar title and content can scroll together. No task depends on hover or a gesture alone.

## Motion

| Interaction | Timing | Purpose |
| --- | --- | --- |
| App entrance | 5.54 s total | The UNITBV mark assembles, lights up and shrinks into its header position. After 80 ms the cards slide in from the left, with roughly 90 ms between starts, while the app title types over 1.05 s. |
| Article opening | 460 ms | Carry the headline from the feed into the focused modal reader. |
| Back | 280 ms | Dismiss the panel and return to the same feed position. |
| Refresh icon | 850 ms per turn | Rotate while the refresh request is pending. |
| Saved icon | 240 ms | Give the bookmark a small pulse after the favorite is saved. |
| Summary change | 220 ms | Crossfade loading/content/error states. |
| Theme | 220 ms | Adjust to a system brightness change. |

Both Android Remove animations and iOS Reduce Motion disable the custom timed transitions. The first cards have a staggered entry during the launch sequence. The feed and article use Flutter scroll physics with inertia and a soft edge. Reduced motion uses a clamped edge. The launch animation coordinates logo assembly, movement into the header, card entry and title typing on a single Flutter ticker. On Android, the sequence waits for Flutter to rasterize its first frame.

The article route exposes its actual controller animation. Hero's temporary offstage measurement can report a completed proxy animation before the real route completes; requests wait for the real controller instead. The regression test observes the route status when the details API is called.

Android requests the fastest supported display mode at the active resolution when the activity resumes. iOS retains `CADisableMinimumFrameDurationOnPhone=true`. These permit high refresh rates; OS power policy and frame-rendering cost still determine delivered frames. Physical-device profiling remains required.

## Frosted controls

The article and calendar export panels use about 70% of the viewport height. Desktop panels use up to 70% of its width, while phones retain room for reading and actions. Modal routes keep keyboard focus in the foreground over a dimmed, blurred backdrop. The mobile navigation and article action bar sit over scrolling content. The phone navigation docks flush to the bottom edge and extends its glass surface under the system gesture area. The article action bar floats with rounded corners. Both use dense backdrop blur, a frosted tint at 15–20% transparency, a fine reflective edge and a soft shadow. High-contrast mode uses a solid background. Card and article text remain on solid reading surfaces.

## Guidance used

These are source guidance, not additional production frameworks. The user-authorized implementation and explicit colors take precedence over generic skill suggestions.

| Requested resource | Application |
| --- | --- |
| [GSAP Timeline skill](https://github.com/greensock/gsap-skills/tree/main/skills/gsap-timeline) | A single timeline with overlapping logo and reader transitions. |
| [Radix Dialog](https://www.radix-ui.com/primitives/docs/components/dialog) | Modal overlay and keyboard focus within the panel, implemented by Flutter routes. |
| [Glassmorphism](https://www.ui-skills.com/skills/iart-ai/glassmorphism) | Frosted control surfaces with a legible solid fallback. |
| [Vercel Web Design Guidelines](https://github.com/vercel-labs/agent-skills/tree/5a37a6329fbad3666c3207392a6a7c0110e92efb/skills/web-design-guidelines) | Clear labels, state feedback, responsive text, safe areas and motion preferences; adapted to Flutter. |
| [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill/tree/f823ab5fb970de820e5a0626a0786aba9aee0543/.claude/skills/ui-ux-pro-max) | Ran the design-system search for an editorial mobile reader and a separate Flutter stack search. Applied hierarchy, touch targets, semantic theming and lazy lists. The generic red palette, marketing hero and suggested fonts did not fit the owner's brief, so the requested palette and app-specific composition take precedence. |
| [Bencium Impact Designer](https://github.com/bencium/bencium-marketplace/tree/5de46a39b4640fa419560cd0b67e4c4b50dac802/bencium-impact-designer) | A coherent editorial direction, distinctive local typography, spacing and purposeful feedback. |
| [AccessLint accessibility inspection](https://github.com/AccessLint/skills/tree/2e9d7336678302d0bc08848e92542560295b34d3/plugins/accesslint/skills/accessibility-inspect) | Separate verified checks from untested assistive-technology behavior. Contrast, large-text reflow and browser AX names are checked; no full WCAG or screen-reader conformance claim is made. |
| [Impeccable](https://github.com/pbakaus/impeccable/tree/b49177d32788f2dc585c42831d845dacf1ebed2c/.agents/skills/impeccable) | Read/Operate discipline, craft floor, real rendered review, restrained motion and documented tokens. Its launcher was unavailable; project context and source guidance were read directly. |
| [Lenis](https://github.com/darkroomengineering/lenis) | Reviewed its browser scope and limitations. The equivalent intent is implemented with Flutter scrolling and display-synchronized animation, without a JavaScript dependency. |
| [Design with Intent](https://designwithintent.ai/) / [Intent](https://github.com/ghaida/intent) | Preserve the reader's task, minimize distraction and data collection, explain design decisions, and distinguish evidence from assumptions. |

No skills were installed into the user's global agent configuration. Offline search resources used for this task live under ignored `.tooling/design-skills/`.

## Validation

Automated tests cover semantic text/action contrast, system-theme switching without losing favorites, deferred network work, both motion preferences, and long content at 320 logical pixels with 200% text.

The [README](README.md#testare) records the handoff checks. The [design guide](docs/DESIGN-SI-ANIMATII.md) describes device profiling and accessibility checks.
