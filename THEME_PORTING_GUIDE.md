# Hugo Tufte Theme Porting Guide

Complete instructions to migrate your blog from the current theme to **hugo-tufte**.

---

## 1. Prerequisites

- Hugo Extended v0.128+ (for SCSS support)
- Git

---

## 2. Setup New Theme

### Option A: Fresh Clone (Recommended)

```bash
# Backup your current site
cp -r your-site your-site-backup

# Navigate to your site
cd your-site

# Add hugo-tufte theme as submodule
git submodule add https://github.com/loikein/hugo-tufte.git themes/hugo-tufte

# Or clone directly (if not using git submodules)
git clone https://github.com/loikein/hugo-tufte.git themes/hugo-tufte
```

### Option B: Use Existing Preview (If Available)

If you've been following the preview setup in this repo:
```bash
cp -r preview-tufte/* your-new-site/
```

---

## 3. Apply Hugo Compatibility Patches

Hugo 0.128+ requires syntax updates. Apply these changes to the theme:

### Patch 1: Fix Template Recursion
```bash
mv themes/hugo-tufte/layouts/partials/header.includes.html \
   themes/hugo-tufte/layouts/partials/header-includes.html
```

Update `themes/hugo-tufte/layouts/partials/header.html`:
- Change `{{ partial "header.includes.html" . }}` to `{{ partial "header-includes.html" . }}`

### Patch 2: Update Deprecated Syntax

**In `hugo.toml`:**
```toml
# OLD (deprecated)
paginate = 10

# NEW
[pagination]
pagerSize = 10
```

**In `layouts/partials/header-includes.html`:**
```go
{{/* OLD */}}
{{ $style := resources.Get "scss/main.scss" | resources.ToCSS $options }}

{{/* NEW */}}
{{ $style := resources.Get "scss/main.scss" | css.Sass $options }}
```

**In `layouts/partials/pagination.html`:**
```go
{{/* OLD */}}
{{ if .Paginator.HasPrev }}
  <a href="{{ .Paginator.PrevPage.URL }}">← Prev</a>
{{ end }}

{{/* NEW */}}
{{ if .Paginator.HasPrev }}
  <a href="{{ .Paginator.Prev.URL }}">← Prev</a>
{{ end }}
```

---

## 4. Create Site Configuration

Create `hugo.toml` in your site root:

```toml
baseURL = 'https://yourdomain.com'
languageCode = 'en-us'
title = 'Your Blog Title'
theme = 'hugo-tufte'

# Pagination
[pagination]
pagerSize = 10

# Markup settings
[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true
  [markup.highlight]
    noClasses = false
    guessSyntax = true

# Theme parameters
[params]
  subtitle = "Your tagline here"
  showPoweredBy = false
  hidedate = false
  showSummary = true
  math = true  # Enable KaTeX
  codeblocksdark = false
  marginNoteInd = "⊕"
  sansSubtitle = false

# Navigation menu
[[menu.nav]]
  name = "Home"
  weight = 10
  url = "/"

[[menu.nav]]
  name = "Posts"
  weight = 20
  url = "/post/"

[[menu.nav]]
  name = "Tags"
  weight = 30
  url = "/tags/"

# Taxonomies
[taxonomies]
  category = "categories"
  tag = "tags"
```

---

## 5. Migrate Content

### Directory Structure

```
content/
├── post/
│   ├── 2024-01-01-my-post.md
│   └── 2023-12-01-another-post.md
├── about.md          # Optional
└── _index.md         # Optional homepage content
```

### Standardize Post Frontmatter

**Required fields:**
```yaml
---
title: "Your Post Title"
date: 2024-01-15T10:00:00+08:00
draft: false
---
```

**Optional fields:**
```yaml
---
title: "Your Post Title"
subtitle: "Optional subtitle"
date: 2024-01-15T10:00:00+08:00
author: "Your Name"
draft: false
image: "/images/featured.png"  # Featured image
meta: true                     # Show author/date
hidedate: false               # Hide date
hidereadtime: false           # Hide reading time
categories:
  - "Technology"
tags:
  - "hugo"
  - "web"
---
```

### Heading Standardization

Ensure your markdown headings follow this hierarchy:

```markdown
<!-- Post title is h1 (added by template) -->

## Introduction      ← h2 for main sections
Content here...

### Subsection       ← h3 for subsections
More content...

#### Details         ← h4 for details
Even more content...
```

**Important:** Do NOT use `# Heading` (h1) in post content - it will appear same size as the post title.

---

## 6. Add Custom CSS (Heading Hierarchy & Featured Images)

Create `static/css/hugo-tufte-override.css`:

```css
/* ========================================
   Heading Hierarchy Fix
   ======================================== */

/* Post titles on list pages */
.page-list .content-title {
  font-size: 2.6rem;
  font-style: normal;
  font-weight: 400;
  margin-top: 3rem;
  margin-bottom: 1rem;
}
.page-list .content-title:first-child { margin-top: 1rem; }
.page-list .content-title a { text-decoration: none; background: none; }
.page-list .content-title a:hover { text-decoration: underline; }

/* Post titles on single pages */
.content-title {
  font-size: 2.8rem;
  font-style: normal;
  margin-top: 2rem;
  margin-bottom: 1rem;
}

.subtitle {
  font-style: italic;
  font-size: 1.6rem;
  color: #555;
  margin-top: 0.5rem;
}

/* Content headings */
section h1 { font-size: 2rem; font-style: normal; margin-top: 2rem; }
section h2 { font-size: 1.8rem; font-style: italic; }
section h3 { font-size: 1.5rem; }
section h4 { font-size: 1.3rem; font-style: italic; }

/* ========================================
   Featured Images
   ======================================== */

.featured-image {
  margin: 1rem 0 2rem 0;
  max-width: 100%;
}
.featured-image img {
  max-width: 100%;
  height: auto;
  display: block;
}

/* Post preview cards on homepage */
.post-preview {
  margin-bottom: 3rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid #ddd;
}
.post-preview:last-child { border-bottom: none; }
.post-preview .featured-image { margin: 0.5rem 0 1rem 0; }
.post-preview .featured-image img {
  max-height: 300px;
  object-fit: cover;
  width: 100%;
}
.post-preview p { color: #444; margin-top: 0.5rem; }
.read-more { font-size: 1.1rem; color: #666; }
```

---

## 7. Create Custom Partials

### Featured Image Support

Create `layouts/partials/content-header.html`:

```go-html-template
<section>
{{- if .Params.subtitle -}}
<p class="subtitle">{{ .Params.subtitle }}</p>
{{- end -}}

{{- if and (.IsPage) (.Params.meta) -}}
<span class="content-meta">
  {{- if .Params.author -}}
  <span class="author">{{ .Params.author }}</span>&nbsp;
  {{- end -}}
  {{- if not .Params.hidedate -}}
  <span class="date">{{ .Date.Format "2006-01-02" }}</span>&nbsp;
  {{- end -}}
  {{- if not .Params.hidereadtime -}}
  <span>{{ .ReadingTime }} min read</span>&nbsp;
  {{- end -}}
</span>
{{- end -}}

{{- if .Params.image -}}
<div class="featured-image">
  <img src="{{ .Params.image | relURL }}" alt="{{ .Title }}">
</div>
{{- end -}}
</section>
```

### Update Homepage Template

Create/override `layouts/index.html` to use h1 for post titles:

```go-html-template
{{ define "main" }}
<article id="main" class="home-page">
{{ partial "brand.html" . }}

{{ with .Content }}<section>{{ . }}</section>{{ end }}

<section class="page-list">
{{ $pgFilter := where .Site.RegularPages "Draft" false 
    | intersect (where .Site.RegularPages "Params.date" "!=" nil) }}
{{ range (.Paginate $pgFilter).Pages }}
  <article class="post-preview">
    <h1 class="content-title">
      <a href="{{ .RelPermalink }}">{{ .Title }}</a>
    </h1>
    {{ partial "content-header.html" . }}
    {{ if .Description }}
      <p>{{ .Description }}</p>
    {{ else if .Site.Params.showSummary }}
      <p>{{ truncate 140 .Summary }}</p>
    {{ end }}
  </article>
{{ end }}
</section>

{{ if and (.Paginator) (gt .Paginator.TotalPages 1) }}
<nav class="pagination">
  {{ if .Paginator.HasPrev }}
    <a href="{{ .Paginator.Prev.URL }}">← Newer</a>
  {{ end }}
  {{ if .Paginator.HasNext }}
    <a href="{{ .Paginator.Next.URL }}">Older →</a>
  {{ end }}
</nav>
{{ end }}

{{ partial "footer.html" . }}
</article>
{{ end }}
```

---

## 8. Migrate Static Assets

Copy your images and static files:

```bash
# Copy images
cp -r /path/to/old/site/static/images/* static/images/

# Copy other static assets
cp -path/to/old/site/static/favicon.ico static/
```

---

## 9. Test Build

```bash
# Clean and build
hugo --gc

# Or serve locally for testing
hugo server -D --bind 127.0.0.1 --port 1313
```

Visit http://localhost:1313 and verify:
- [ ] Homepage loads with post list
- [ ] Post titles are larger than content headings
- [ ] Featured images display correctly
- [ ] Navigation menu works
- [ ] Tags/categories pages work
- [ ] Individual posts render correctly

---

## 10. Deploy

### GitHub Pages (GitHub Actions)

Create `.github/workflows/hugo.yml`:

```yaml
name: Deploy Hugo site to Pages

on:
  push:
    branches: [main, master]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.140.0'
          extended: true

      - name: Build
        run: hugo --minify

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

### Netlify

Add `netlify.toml`:

```toml
[build]
  command = "hugo --gc --minify"
  publish = "public"

[build.environment]
  HUGO_VERSION = "0.140.0"
  HUGO_ENABLEGITINFO = "true"
```

### Manual Deployment

```bash
# Build for production
hugo --gc --minify

# Deploy the 'public' folder to your web server
rsync -avz public/ user@server:/var/www/html/
```

---

## 11. Post-Migration Checklist

- [ ] All posts display with correct heading hierarchy
- [ ] Images load correctly
- [ ] Math rendering works (if using KaTeX)
- [ ] Code syntax highlighting works
- [ ] RSS feed works at `/index.xml`
- [ ] 404 page exists
- [ ] Favicon displays
- [ ] Mobile responsive layout works
- [ ] SEO meta tags present

---

## Troubleshooting

### Issue: SCSS compilation fails
**Fix:** Ensure Hugo Extended is installed (not regular Hugo)

### Issue: Headings are wrong size
**Fix:** Check `static/css/hugo-tufte-override.css` is loaded. Verify no `# ` headings in content.

### Issue: Featured images don't show
**Fix:** Ensure `image` field in frontmatter has leading slash: `/images/photo.png`

### Issue: Pagination links broken
**Fix:** Update `.PrevPage` → `.Prev`, `.NextPage` → `.Next` in templates

---

## Quick Reference

| Task | File/Location |
|------|---------------|
| Site config | `hugo.toml` |
| Custom CSS | `static/css/hugo-tufte-override.css` |
| Custom layouts | `layouts/` (overrides theme) |
| Posts | `content/post/` |
| Images | `static/images/` |
| Homepage template | `layouts/index.html` |
| Post template | `layouts/post/single.html` |
