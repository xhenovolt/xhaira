# Sidebar Enhancement - Quick Reference Guide

## 🎯 Quick Start

### For Users
1. Click the **collapse button** (chevron left icon) in the sidebar header
2. Sidebar animates to icon-only mode (5rem width)
3. Hover over icons to see labels in tooltips
4. Click collapse button again to expand
5. State persists after refresh

### For Developers
1. The sidebar component is in `/src/components/layout/Sidebar.js`
2. It's a default export: `import Sidebar from '@/components/layout/Sidebar'`
3. Used by NavigationWrapper which controls visibility
4. Exports collapsed state to localStorage automatically

---

## 🏗️ Architecture Overview

```
App Layout
├── NavigationWrapper (shows/hides nav based on route)
│   ├── Sidebar (collapsible navigation)
│   │   ├── Header (logo + collapse button)
│   │   ├── Navigation (menu items + sections)
│   │   ├── Quick Add (button)
│   │   └── Footer (settings + logout)
│   └── Navbar (top bar, width responds to sidebar)
└── LayoutClient (adjusts content margin based on sidebar state)
```

---

## 📁 Key Files

| File | Purpose | Key Elements |
|------|---------|--------------|
| `Sidebar.js` | Main navigation | Collapse toggle, menu items, active states |
| `Navbar.js` | Top navigation bar | Dynamic positioning, search, user menu |
| `NavigationWrapper.js` | Route-based nav gating | Shows nav only on /app routes |
| `layout-client.js` | Layout adjustments | Responsive margins based on sidebar state |

---

## 💾 State Management

### localStorage
```javascript
// Key: 'sidebar-collapsed'
// Values: true (collapsed) | false (expanded)
// Access:
const collapsed = JSON.parse(localStorage.getItem('sidebar-collapsed') || 'false');

// Update:
localStorage.setItem('sidebar-collapsed', JSON.stringify(true)); // collapse
localStorage.setItem('sidebar-collapsed', JSON.stringify(false)); // expand
```

### Custom Events
```javascript
// Dispatch (in Sidebar.js):
window.dispatchEvent(new CustomEvent('sidebar-toggled'));

// Listen (in other components):
window.addEventListener('sidebar-toggled', handleToggle);
```

---

## 🎨 Key Component Props & State

### Sidebar Component
```javascript
export default function Sidebar() {
  // State
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [expandedSections, setExpandedSections] = useState({...});
  
  // Hooks
  const pathname = usePathname();
  
  // Effects
  useEffect(() => {
    // Load collapsed state from localStorage
  }, []);
  
  // Functions
  const toggleCollapse = () => {...};
  const toggleSection = (section) => {...};
  const isActive = (href) => pathname === href;
  const isParentActive = (submenu) => {...};
}
```

### Navbar Component
```javascript
export function Navbar() {
  // State
  const [isCollapsed, setIsCollapsed] = useState(false);
  
  // Hooks
  useEffect(() => {
    // Monitor sidebar state from localStorage
  }, []);
  
  // Motion component
  <motion.nav
    animate={{ left: isCollapsed ? '5rem' : '16rem' }}
    transition={{ duration: 0.3, ease: 'easeInOut' }}
  >
}
```

---

## 🎬 Animation Reference

### Collapse/Expand Animation
```javascript
<motion.aside
  animate={{ width: isCollapsed ? '5rem' : '16rem' }}
  transition={{ duration: 0.3, ease: 'easeInOut' }}
/>
```

### Active Indicator Animation
```javascript
{isItemActive && (
  <motion.div
    layoutId="activeIndicator"
    className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-blue-600"
    transition={{ duration: 0.2 }}
  />
)}
```

### Submenu Expand Animation
```javascript
<motion.div
  initial={{ opacity: 0, height: 0 }}
  animate={{ opacity: 1, height: 'auto' }}
  exit={{ opacity: 0, height: 0 }}
  transition={{ duration: 0.2 }}
>
  {/* submenu items */}
</motion.div>
```

---

## 🖱️ User Interactions

| Action | Result | Code |
|--------|--------|------|
| Click collapse button | Width animates 16rem ↔ 5rem | `toggleCollapse()` |
| Hover icon (collapsed) | Tooltip appears | `<Tooltip />` component |
| Click section header | Section expands/collapses | `toggleSection(section)` |
| Click menu item | Navigate to page | `<Link href={...} />` |
| Active route detected | Blue/purple indicator appears | Active state detection |
| Reload page | State restored from localStorage | `useEffect` on mount |

---

## 🌙 Dark Mode

### Automatic Detection
```css
/* Light mode (default) */
.sidebar { @apply bg-gray-50 border-gray-200 text-gray-700; }

/* Dark mode (via dark: prefix) */
.dark .sidebar { @apply bg-gray-900 border-gray-800 text-gray-300; }
```

### Switching
- Automatic via CSS media query
- No JavaScript required
- No animation needed (CSS handles it)

---

## 📐 Sizing Reference

| Element | Width | Height |
|---------|-------|--------|
| Expanded sidebar | 16rem (256px) | 100vh |
| Collapsed sidebar | 5rem (80px) | 100vh |
| Icon size (main) | 20px | 20px |
| Icon size (quick add) | 18px | 18px |
| Item padding | 0.75rem × 0.5rem | auto |
| Navbar | calc(100% - sidebar width) | 4rem |
| Navbar (collapsed) | calc(100% - 5rem) | 4rem |

---

## 🎯 Menu Structure

```javascript
const menuItems = [
  { label: 'Dashboard', href: '/app/dashboard', icon: Home },
  {
    label: 'Operations',
    icon: Zap,
    submenu: [
      { label: 'Divisions', href: '/app/divisions' },
      { label: 'Teams', href: '/app/teams' },
      { label: 'Projects', href: '/app/tasks' },
    ],
  },
  // ... 6 more sections ...
];
```

### Adding a New Menu Item

**Direct Link:**
```javascript
{ label: 'New Page', href: '/app/new-page', icon: IconName }
```

**Submenu Section:**
```javascript
{
  label: 'New Section',
  icon: IconName,
  submenu: [
    { label: 'Item 1', href: '/app/new/item1' },
    { label: 'Item 2', href: '/app/new/item2' },
  ],
}
```

---

## 🔧 Customization Guide

### Change Collapse Width
```javascript
// In Sidebar.js, change this:
animate={{ width: isCollapsed ? '5rem' : '16rem' }}
// To your desired width, e.g.:
animate={{ width: isCollapsed ? '6rem' : '18rem' }}
```

### Change Animation Duration
```javascript
// Slower animation (500ms):
transition={{ duration: 0.5, ease: 'easeInOut' }}

// Faster animation (200ms):
transition={{ duration: 0.2, ease: 'easeInOut' }}
```

### Change Colors
```javascript
// Replace bg-blue-600 with your color for active items
// Replace bg-purple-600 with your color for active parents
// Update all className definitions
```

### Add More Icons
```javascript
// Import from lucide-react:
import { NewIcon } from 'lucide-react';

// Use in menu item:
{ label: 'Item', icon: NewIcon, ... }
```

---

## 🐛 Debugging Tips

### Check Collapsed State
```javascript
// In browser console:
localStorage.getItem('sidebar-collapsed') // 'true' or 'false'
```

### Watch for Custom Events
```javascript
// In browser console:
window.addEventListener('sidebar-toggled', () => {
  console.log('Sidebar toggled!');
});
```

### Verify Active Route Detection
```javascript
// In Sidebar component:
console.log('Current pathname:', pathname);
console.log('Is active?', isActive('/app/dashboard'));
```

### Check Animation Performance
```javascript
// Use React DevTools Profiler to measure:
// - Component render time
// - Animation frame drops
// - Event listener overhead
```

---

## ⚡ Performance Optimizations

### Already Implemented
- ✅ AnimatePresence for efficient mount/unmount
- ✅ layoutId for GPU-accelerated animations
- ✅ localStorage instead of state sync
- ✅ Custom events for lightweight updates
- ✅ useCallback for function references
- ✅ Early returns to skip renders

### Best Practices
- Use event delegation for menu items
- Batch state updates in callbacks
- Debounce resize listeners if adding
- Memoize expensive computations

---

## 🧪 Testing Checklist

### Unit Tests (if adding)
```javascript
// Test collapse toggle
// Test active state detection
// Test submenu expand/collapse
// Test localStorage persistence
// Test custom events
```

### Integration Tests
```javascript
// Test sidebar + navbar sync
// Test sidebar + content margin sync
// Test mobile nav unaffected
// Test dark mode switching
```

### Manual Tests
```javascript
// Collapse/expand sidebar
// Hover tooltips
// Click menu items
// Refresh page (state persistence)
// Switch dark mode
// Test mobile view
```

---

## 📚 Related Documentation

- **SIDEBAR_ENHANCEMENT_GUIDE.md** - Complete technical guide
- **SIDEBAR_FEATURES.md** - Visual feature showcase
- **SIDEBAR_IMPLEMENTATION_SUMMARY.md** - Project completion summary

---

## 🆘 Common Issues & Solutions

### Issue: Collapse state not persisting
**Solution:** Check if localStorage is enabled in browser
```javascript
// Verify in console:
localStorage.setItem('test', 'value');
localStorage.getItem('test'); // Should return 'value'
```

### Issue: Navbar not aligning
**Solution:** Restart dev server and clear Next.js cache
```bash
rm -rf .next
npm run dev
```

### Issue: Tooltips not showing
**Solution:** Check z-index and verify hover state
```javascript
// Tooltip should have z-50, container should allow overflow
```

### Issue: Active indicator in wrong place
**Solution:** Verify route paths match exactly
```javascript
// pathname must match href exactly
console.log('pathname:', pathname, 'href:', item.href);
```

---

## 📋 Checklist for Maintenance

- [ ] Run `npm run build` to verify no errors
- [ ] Test collapse/expand on latest Chrome
- [ ] Test on Firefox and Safari
- [ ] Test dark mode switching
- [ ] Verify mobile nav unaffected
- [ ] Check console for warnings
- [ ] Test all menu links
- [ ] Verify active indicators
- [ ] Test keyboard navigation
- [ ] Check accessibility with axe DevTools

---

## 📞 Quick Support Matrix

| Issue | Check | Solution |
|-------|-------|----------|
| Not collapsing | Console errors? | Clear cache, rebuild |
| Wrong width | Styling cascade? | Check Tailwind config |
| Navbar misaligned | z-index conflicts? | Verify modal layering |
| Tooltips invisible | Dark mode colors? | Update color scheme |
| Performance lag | Animation duration? | Reduce 300ms → 200ms |

---

**Version**: 1.0  
**Last Updated**: 2025-01-01  
**Quick Reference**: ✅ Complete
