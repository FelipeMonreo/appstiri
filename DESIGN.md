# Reader design system

This redesign implements the owner's explicit blue/white light theme, charcoal/white dark theme, large controls and smooth article opening. The feed is a task surface; the article is a reading surface. Product facts and constraints are in [PRODUCT.md](PRODUCT.md).

## Visual direction

An editorial technology reader with a clear typographic hierarchy, a blue lead story in light mode, restrained charcoal surfaces at night, and generous spacing. The lead story is actual feed content, without invented photography, categories or engagement numbers. The top headline is “Lumea tech, pe îndelete.” Favorites use “Biblioteca ta.”

The owner reads on a phone in changing ambient light. System brightness chooses the palette; there is no independent app setting to fall out of sync.

| Role | Light | Dark |
| --- | --- | --- |
| Page | `#F3F6FC` | `#191B20` |
| Surface | `#FFFFFF` | `#24272D` |
| Action | `#1557CD` | `#F4F5F7` |
| Text | `#17233A` | `#F4F5F7` |
| Secondary text | `#526078` | `#B9BEC8` |
| Lead-story surface | `#1557CD` | `#343841` |

`lib/theme/app_theme.dart` is the implementation authority. Components use semantic ColorScheme roles. Status and error colors remain distinct so recovery messages retain their meaning.

## Type and layout

- Bitter supplies the wordmark and editorial headlines. Manrope supplies controls and reading text. Both fonts are bundled locally with their SIL Open Font License files; no runtime font request is needed.
- Reading text is 18 logical pixels with 1.75 line height. System text scaling remains enabled. Headlines wrap; essential article titles are not truncated.
- Spacing follows a 4-pixel rhythm. Cards have 16-pixel corners. Main controls have 14-pixel corners, labeled icons and a minimum height of 56 logical pixels; icon and text controls remain at least 48 logical pixels.
- The feed uses lazy slivers and a 1064-pixel maximum width. The reader has a 768-pixel maximum width. At narrow widths action buttons stack; desktop actions wrap.
- The calendar title and content can scroll together. At enlarged text sizes, metadata wraps and the decorative date can disappear from the toolbar. No task depends on hover or a gesture alone.

## Motion

| Interaction | Timing | Purpose |
| --- | --- | --- |
| Article opening | 360 ms | Carry the headline from the feed into the reader, with the platform page transition. |
| Back | 280 ms | Restore the feed and preserve native back gestures. |
| Saved icon | 160 ms | Confirm the saved state without moving the layout. |
| Summary change | 220 ms | Crossfade loading/content/error states. |
| Theme | 220 ms | Adjust to a system brightness change. |

Both Android Remove animations and iOS Reduce Motion disable the custom timed transitions. There are no decorative background loops or per-row entrance sequences. Scroll physics and animation tickers belong to Flutter. Lenis is not inserted into the native rendering path.

The article route exposes its actual controller animation. Hero's temporary offstage measurement can report a completed proxy animation before the real route completes; requests wait for the real controller instead. The regression test observes the route status when the details API is called.

Android requests the fastest supported display mode at the active resolution when the activity resumes. iOS retains `CADisableMinimumFrameDurationOnPhone=true`. These permit high refresh rates; OS power policy and frame-rendering cost still determine delivered frames. Physical-device profiling remains required.

## Guidance used

These are source guidance, not additional production frameworks. The user-authorized implementation and explicit colors take precedence over generic skill suggestions.

| Requested resource | Application |
| --- | --- |
| [Vercel Web Design Guidelines](https://github.com/vercel-labs/agent-skills/tree/5a37a6329fbad3666c3207392a6a7c0110e92efb/skills/web-design-guidelines) | Clear labels, state feedback, responsive text, safe areas and motion preferences; adapted to Flutter. |
| [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill/tree/f823ab5fb970de820e5a0626a0786aba9aee0543/.claude/skills/ui-ux-pro-max) | Ran the design-system search for an editorial mobile reader and a separate Flutter stack search. Applied hierarchy, touch targets, semantic theming and lazy lists. The generic red palette, marketing hero and suggested fonts did not fit the owner's brief, so the requested palette and app-specific composition take precedence. |
| [Bencium Impact Designer](https://github.com/bencium/bencium-marketplace/tree/5de46a39b4640fa419560cd0b67e4c4b50dac802/bencium-impact-designer) | A coherent editorial direction, distinctive local typography, spacing and purposeful feedback. |
| [AccessLint accessibility inspection](https://github.com/AccessLint/skills/tree/2e9d7336678302d0bc08848e92542560295b34d3/plugins/accesslint/skills/accessibility-inspect) | Separate verified checks from untested assistive-technology behavior. Contrast, large-text reflow and browser AX names are checked; no full WCAG or screen-reader conformance claim is made. |
| [Impeccable](https://github.com/pbakaus/impeccable/tree/b49177d32788f2dc585c42831d845dacf1ebed2c/.agents/skills/impeccable) | Read/Operate discipline, craft floor, real rendered review, restrained motion and documented tokens. Its launcher was unavailable; project context and source guidance were read directly. |
| [Lenis](https://github.com/darkroomengineering/lenis) | Reviewed its browser scope and limitations. The equivalent intent is implemented with Flutter scrolling and display-synchronized animation, without a JavaScript dependency. |
| [Design with Intent](https://designwithintent.ai/) / [Intent](https://github.com/ghaida/intent) | Preserve the reader's task, minimize distraction and data collection, explain design decisions, and distinguish evidence from assumptions. |

No skills were installed into the user's global agent configuration. Offline search resources used for this task live under ignored `.tooling/design-skills/`.

## Validation

Static analysis and 62 automated tests pass. The release web build succeeds. Tests cover semantic text/action contrast, system-theme switching without losing favorites, deferred network work, both motion preferences, and long content at 320 logical pixels with 200% text.

Rendered browser checks use repeatable simulated API responses and inspect light/dark mobile, article and desktop layouts. Browser fixture stories are not production app content. Native builds, native calendar permissions, VoiceOver/TalkBack behavior and sustained high-refresh performance still need verification on real devices. See [the implementation guide](docs/DESIGN-SI-ANIMATII.md).
