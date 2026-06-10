## Folder structure of generated output site

```
Build/                        // index.html contains (temporary) language selector
├── nl/                       // Dutch branch; no index.html file
│   ├── clubs/                // Level 1 output: index page listing all clubs
│   │   ├── fcVeghel/         // Level 2 output: index page lists all current/former club members (and maybe expo's)
│   │   │   └── portfolios/   // optional portfolio directory made by LR plugin
│   │   │       ├── John_Doe/ // one subdirectory per club member, named after the member
│   │   │       └── Jane_Doe/
│   │   └── fgDeGender/
│   │       ├── portfolios/
│   │       │   ├── John_Doe/
│   │       │   └── Jane_Doe/
│   │       └── expositions/  // reserved for future extension: no index.html file
│   │           ├── Expo2025/ // portfolio with all images displayed at one particular exposition
│   │           └── Expo2026/
│   ├── expertises/           // Level 0 output: index page listing all expertises
│   │   ├── Abstract/         // Level 0 output: index of club members with the Abstract expertise tag
│   │   └── Architecture/
│   ├── expositions/          // reserved for future extension: index of past and future expositions
│   └── museums/              // reserved for future extension: Level 1 museums list
├── en/
│   ├── clubs/
│   │   ├── fcVeghel/
│   │   │   └── portfolios/
│   │   │       ├── John_Doe/
│   │   │       └── Jane_Doe/
│   │   └── fgDeGender/
│   │       ├── portfolios/
│   │       │   ├── John_Doe/
│   │       │   └── Jane_Doe/
│   │       └── expositions/
│   │           ├── Expo2025/
│   │           └── Expo2026/
│   ├── expertises/
│   │   ├── Abstract/
│   │   └── Architecture/
│   ├── expositions/
│   └── museums/
└── de/
```

Notes:
- Club directories are currently distributed across http://vdhamer.com and https://fcdegender.nl.
- In principle, any club may decide to host its own data on any server (e.g. the server holding its website).
