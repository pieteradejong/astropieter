# Pieter de Jong - Personal website
URL = [pieter.am](https://pieter.am/) and [peter.am](https://peter.am/); I have a highly common first and last name, and it's easily misspelled between English and Dutch, so finding a proper domain was challenging. I settled on these, so just yelling over the crowd "it's PETER DOT AM, AM AS IN MORNINGTIME!" should work.


**Thsi is my main online presence**, aside from [my LinkedIn](https://www.linkedin.com/in/pieteradejong/) and [my GitHub](https://github.com/pieteradejong). The Internet is a large place, and standing out is both critical and hard. This is where I aim to do so.

# Goals
* Marketing: put myself out there.
* Connect: Find like-minded, share ideas, potentially work together, etc.

# Website 'Table of contents':

* Blog - I like to write
* About Me - Personal background, history, what sets me apart from the crowd.
* Reading: I love to read, and seek out fellow readers.
* Contact: self-evident.


# Maintenance / deployment
For hosting I use [Siteground](https://www.siteground.com/), and for DNS I use [iwantmyname](https://iwantmyname.com/). 

I use the React-based `Astro.js` framework for development; the for web development standard process of `npm run astro dev` that monitors files for changes so you see all changes reflected immediately on `localhost`; and a custom `.sh` script to use `rsync` to build the site and sync all changes to my Siteground server. 


## rsync script
I run this `$ astrosync` from anywhere to build + sync my site to prod:

```bash
astrosync() {
  cd <local_astropieter_dir>
  npm run astro build
  rsync -av --delete -e <ssh_key> <local_build_dir> <server_host>
}
```

# TODO 
Stuff I would like to add in the future:
* Top priorities: content, quality, and loading speed.
* auto translate to any language, especially Spanish and Dutch. Classic Latin and Classic Greek would be cool too.
* Low-friction contact methods.
* Inline programming code, e.g. `Python`.
* If/when my content becomes good enough, a micro-payment "tip jar".

# Astro Blog

A modern, fast blog built with Astro.js featuring static search capabilities.

## Features

- 🚀 Built with Astro.js for optimal performance
- 📝 Markdown and MDX support
- 🔍 Static search functionality with Pagefind
- 📱 Responsive design
- 🎨 Clean, professional styling
- 📊 LaTeX support for mathematical content
- 🔄 Easy deployment with included scripts

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/astropieter.git
cd astropieter
```

2. Run the initialization script:
```bash
chmod +x init.sh
./init.sh
```

This will:
- Install all necessary dependencies
- Set up the search functionality
- Create required directories
- Configure the project

3. Start the development server:
```bash
npm run dev
```

## Search Functionality

The site includes static search powered by Pagefind. To use the search:

1. Visit any page and use the search box in the header
2. Or navigate directly to `/search?q=your-search-term`

The search index is automatically generated during deployment.

## Deployment

To deploy the site:

1. Update the configuration in `deploy.sh` with your deployment details
2. Run the deployment script:
```bash
./deploy.sh
```

The script will:
- Build the site
- Generate the search index
- Deploy using either your existing `astrosync` script or rsync

## Project Structure

```
.
├── src/
│   ├── components/    # Reusable components
│   ├── content/      # Blog posts and other content
│   ├── layouts/      # Page layouts
│   ├── pages/        # Astro pages
│   └── styles/       # Global styles
├── public/           # Static assets
├── init.sh          # Initialization script
├── deploy.sh        # Deployment script
└── pagefind.json    # Search configuration
```

## Customization

### Search Configuration

Edit `pagefind.json` to customize search behavior:
- Update `site` URL
- Modify `exclude_selectors` to exclude content from search
- Adjust other search parameters

### Styling

All styles use CSS variables defined in `src/styles/global.css`. Key variables:
- `--accent`: Primary accent color (used for links)
- `--non-link-text`: Color for non-interactive text
- `--card-bg`: Background color for cards
- `--border`: Border color
- `--mobile-cutoff`: Breakpoint for mobile devices

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details
