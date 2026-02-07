# UI/UX Specifications

## Theme System

### Colors (Already matched in app_theme.dart)
| Token | Light | Dark |
|-------|-------|------|
| Primary | #4988C4 (HSL 209 51% 53%) | #4988C4 |
| Background | #F9F8F6 (warm off-white) | #0A1929 |
| Foreground | #1A3A5C (deep blue-grey) | #E5EBF1 |
| Card | #FFFFFF | #112240 |
| Muted | #E8EEF4 | #1E3A5F |
| Muted Foreground | #6B8AAB | #8BA4BD |
| Border | #D4E0EC | #2D4A6F |
| Destructive | #EF4444 | #EF4444 |

### Border Radius
- Cards: 12px (0.75rem)
- Inputs: 8px (0.5rem)
- Buttons: 8px (0.5rem)

### Typography
- System fonts (no custom fonts)
- Headline Large: 32px bold, -0.5 letter spacing
- Headline Medium: 24px semibold
- Title Large: 20px semibold
- Title Medium: 16px medium
- Body Large: 16px
- Body Medium: 14px
- Body Small: 12px
- Label Small: 10px semibold, 0.5 letter spacing

## Component Mapping: React (Radix/shadcn) -> Flutter (Mad*)

| React Component | Flutter Component | File |
|-----------------|-------------------|------|
| Button | MadButton | mad_button.dart |
| Card | MadCard | mad_card.dart |
| Input | MadInput | mad_input.dart |
| Select | MadSelect | mad_select.dart |
| Dialog | MadDialog | mad_dialog.dart |
| Badge | MadBadge | mad_badge.dart |
| Switch | MadSwitch | mad_switch.dart |
| Checkbox | MadCheckbox | mad_checkbox.dart |
| Tabs | MadTabs | mad_tabs.dart |
| Textarea | MadTextarea | mad_textarea.dart |
| DataTable | MadDataTable | mad_data_table.dart |
| DropdownMenu | MadDropdownMenu | mad_dropdown_menu.dart |
| Skeleton | MadSkeleton | mad_skeleton.dart |
| Toast/Toaster | MadToast | mad_toast.dart |
| StatCard | StatCard | stat_card.dart |
| LoadingOverlay | LoadingOverlay | loading_overlay.dart |

## Layout Structure
- MainLayout: Sidebar + Header + Content
- Sidebar: 288px expanded, 80px collapsed
- Header: Breadcrumbs + Search + Notifications + User menu
- Content: Max width 1400px, centered

## Responsive Breakpoints
- Mobile: < 768px (drawer sidebar)
- Tablet: 768-1024px (drawer sidebar)
- Desktop: > 1024px (persistent sidebar)

## Animation Patterns
- Page transitions: Fade + slide
- Dialog: Scale + fade
- Sidebar collapse: Width animation

## Icons
- React: lucide-react
- Flutter: lucide_icons_flutter (already matched)
