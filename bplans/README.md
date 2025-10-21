# Business Plans for Innovasjon Norge

This directory contains 8 complete Norwegian business plans optimized for Innovasjon Norge (Innovation Norway) funding applications.

## Overview

- **Total Funding Target:** NOK 2,800,000
- **Number of Plans:** 8
- **Language:** Norwegian (Norsk)
- **Target:** innovasjonnorge.no

## Structure

```
bplans/
├── __shared/              # Shared templates and styles
│   └── template.html.erb  # ERB template for all plans
├── data/                  # JSON data for each business plan
│   ├── syre.json
│   ├── speis.json
│   ├── norwegianhedge.json
│   ├── pubhealthcare.json
│   ├── ragnhild.json
│   ├── govt_bergen.json
│   ├── nato.json
│   └── ai3.json
├── assets/
│   └── images/           # Product images (carousel)
│       ├── ivaar_fkyeah1.png
│       ├── ivaar_fkyeah2.png
│       └── ivaar_fkyeah3.png
├── generated/            # Generated HTML files
│   └── *.html
├── generate.rb          # Ruby generator script
├── index.html          # Directory listing
└── README.md           # This file
```

## Business Plans

### 1. SYRE™ - 3D-printede sko med bærekraft
- **Sector:** Environment & Sustainability
- **Funding:** NOK 250,000
- **Innovation:** Multi-material 3D printing for custom footwear
- **Key Features:** Parametric CAD, aerospace-grade materials, 1:1 donation model

### 2. SPEIS - NATO Aurora skip + kampfly 7-10. gen
- **Sector:** Maritime + Defense
- **Funding:** NOK 500,000
- **Innovation:** Nuclear-hybrid Arctic dominance ships + next-gen fighter jets
- **Key Features:** AI propulsion, 3.5m ice-breaking, modular mission systems

### 3. Norwegian Hedge - Hedgefond + Ruby-handelsbots
- **Sector:** Technology + Finance
- **Funding:** NOK 300,000
- **Innovation:** Ruby trading bot swarm with AI³ integration
- **Key Features:** High-frequency trading, scalping, arbitrage algorithms

### 4. pub.healthcare - Autonome parametriske sykehus
- **Sector:** Health
- **Funding:** NOK 500,000
- **Innovation:** Self-constructing hospitals with parametric architecture
- **Key Features:** Robotic assembly, AI patient care, energy self-sufficiency

### 5. Ragnhild - Begravelsesbyrå (Karaokekiste)
- **Sector:** Social Innovation
- **Funding:** NOK 150,000
- **Innovation:** Modern funeral services (Karaokekiste, Diskokiste, Klovnepallbærere)
- **Key Features:** LED-lit caskets, sound systems, holographic displays

### 6. Bergen Selvstyreparti - Politisk teknologiplattform
- **Sector:** Civic Tech
- **Funding:** NOK 200,000
- **Innovation:** Blockchain-based local governance platform
- **Key Features:** Decentralized voting, transparent decision-making

### 7. NATO Aurora - Arktiske dominanseskip
- **Sector:** Maritime + Defense
- **Funding:** NOK 500,000
- **Innovation:** Superior Arctic icebreakers for NATO
- **Key Features:** Dual nuclear reactors, AI optimization, Polar Class 1 hull

### 8. AI³ - Ruby 3D-printing for romfart
- **Sector:** Energy & Environment + Aerospace
- **Funding:** NOK 400,000
- **Innovation:** Ruby-driven 3D printing for spacecraft propulsion components
- **Key Features:** Parametric design, fusion drive nozzles, quantum vacuum thrusters

## Innovation Norway Requirements

Each business plan includes these required sections in Norwegian:

1. **Sammendrag** - Executive summary (innovation, novelty, customer benefit, market potential)
2. **Markedsanalyse** - Market size (Norway/Nordics), customer segments, competition, competitive advantage
3. **Teknologi og Innovasjon** - Technical description, unique innovation, IP status, development stage
4. **Forretningsmodell** - Revenue streams, path to profitability, scalability plan
5. **Utviklingsveikart** - Quarterly milestones (Q1 2026 - Q4 2027)
6. **Finansieringsbehov** - Total funding needed, Innovation Norway request, detailed allocation
7. **Team og Kompetanse** - Key personnel backgrounds and expertise
8. **Bærekraft og Samfunnsansvar** - Environmental, social, economic impact + UN SDG alignment

## Design Template

All plans follow the exact SYRE™ layout:

- **Logo:** Black Han Sans, 70px, with optional TM symbol
- **Gradient:** `linear-gradient(45deg, #ff007f, #00c9ff, #ffcc00, #ff007f)`
- **Animation:** gradientMove (5s) + background-size 400%
- **Structure:** Header → Carousel (if images) → Main sections → Chart.js visualizations
- **Responsive:** Mobile breakpoint 768px
- **Dependencies:** Swiper 8, Chart.js, Google Fonts

## Usage

### Generating HTML Files

```bash
# Generate all business plans
ruby generate.rb

# Output will be in generated/ directory
```

### Modifying Plans

1. Edit the corresponding JSON file in `data/`
2. Run `ruby generate.rb` to regenerate HTML
3. View the updated plan in `generated/`

### JSON Schema

Each JSON file follows this structure:

```json
{
  "meta": {
    "name": "Business Name",
    "tagline": "Short tagline",
    "logo_text": "LOGO",
    "trademark": true/false,
    "sector": "Sector name",
    "funding_nok": 250000
  },
  "sammendrag": { ... },
  "markedsanalyse": { ... },
  "teknologi": { ... },
  "forretningsmodell": { ... },
  "veikart": { ... },
  "finansiering": { ... },
  "team": [ ... ],
  "baerekraft": { ... },
  "charts": [ ... ],
  "carousel": { ... }
}
```

## Quality Metrics

- ✅ File size: <25KB per JSON, <100KB per generated HTML
- ✅ All content in Norwegian
- ✅ Responsive design (768px breakpoint)
- ✅ Chart.js visualizations for financial/market data
- ✅ Innovation Norway compliance: 100%

## Validation

The generator includes built-in validation:

- Required sections check
- File size warnings
- JSON parsing validation
- Missing field detection

## Dependencies

- Ruby 3.0+
- ERB (built-in)
- JSON (built-in)
- Modern web browser for viewing HTML

## Browser Compatibility

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers (iOS Safari, Chrome Android)

## License

All business plans are proprietary and confidential. For Innovation Norway funding applications only.

## Contact

For questions or modifications, refer to the main pub3 repository documentation.
