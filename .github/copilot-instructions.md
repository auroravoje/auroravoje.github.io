# AI Agent Instructions for auroravoje.github.io

## Project Overview
This is a Jekyll-based GitHub Pages site focused on AI and data science content. The site uses the Cayman remote theme and is automatically deployed via GitHub Pages when changes are pushed to the main branch.

## Architecture & Key Components

### Content Structure
- **Posts**: Located in `_posts/` with naming pattern `YYYY-MM-DD-title.md`
- **Static pages**: Root-level `.md` files (index.md, about.md)
- **Assets**: Images stored in `assets/images/YYYY-MM-DD-post-title/` following post date pattern
- **Built site**: Generated in `_site/` (not tracked in git)

### Theme & Configuration
- **Remote theme**: `pages-themes/cayman@v0.2.0` (GitHub Pages compatible)
- **Plugins**: jekyll-feed, jekyll-remote-theme, jekyll-toc
- **TOC system**: Custom floating TOC implementation in `_includes/toc.html`

## Development Workflow

### Local Development
```bash
# Install dependencies
bundle install

# Serve locally with auto-reload
bundle exec jekyll serve

# Build for production
bundle exec jekyll build
```

### Content Creation Patterns

#### Blog Posts
- Use front matter with: `layout: default`, `title`, `date`, `categories`
- Include `* TOC {:toc}` for automatic table of contents
- Add `{:top}` anchor after first heading for "Back to top" links
- Store images in `assets/images/YYYY-MM-DD-post-title/`
- Reference images: `{{ site.baseurl }}/assets/images/...`

#### Cross-post References
Use Jekyll's post_url tag for internal links:
```markdown
[Link text]({% post_url 2025-10-15-ai-agents-azure %})
```

#### Image Galleries (Flickity Carousel)
The site uses Flickity for image carousels. Include CSS/JS and structure:
```html
<div class="main-carousel" data-flickity='{ "cellAlign": "left", "contain": true, "wrapAround": true }'>
  <div class="carousel-cell">
    <img src="..." alt="...">
    <p>Caption</p>
  </div>
</div>
```

#### Collapsible Content
Use HTML `<details>` tags for expandable sections:
```html
<details markdown=1>
<summary>Title - click to expand ⏬</summary>
Content here...
</details>
```

### Styling Conventions
- **Code blocks**: Use triple backticks with language specification
- **Figures**: Include `<figure>` tags with `<figcaption>` for images
- **Emphasis**: Use blockquotes (`>`) for definitions and important callouts
- **Navigation**: Include "Back to top" links at post endings

## File Organization
- New posts must follow Jekyll's date-prefixed naming convention
- Image assets should mirror post date structure
- Keep `_site/` in `.gitignore` (auto-generated)
- Gemfile.lock is tracked for reproducible builds

## GitHub Pages Deployment
- No custom GitHub Actions needed - uses built-in Jekyll deployment
- Changes to main branch automatically trigger rebuild
- Site URL: `https://auroravoje.github.io`
- Build settings configured in `_config.yml`

## TOC Implementation
The site has a custom floating TOC system. When adding TOC to posts:
1. Include `* TOC {:toc}` in markdown
2. The `_includes/toc.html` handles styling and positioning
3. TOC appears as floating sidebar on desktop, hidden on mobile

## Content Focus
Site specializes in AI/ML content, particularly Azure AI services, with technical tutorials featuring step-by-step guides, code examples, and visual walkthroughs.