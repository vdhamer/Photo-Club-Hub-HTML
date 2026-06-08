## Folder structure of generated output site

Build/
    nl/ // Dutch pages; no language-level home page (nl/ is just a container)
        clubs/ // Level 1 output: index page listing all clubs, linking to each club's Level 2 page (not yet generated at this path)
            fcVeghel/ // Level 2 output: lists all (current and optionally former) members of fcVeghel
                portfolios/ // optional portfolio when generated using Lightroom plug-in
            fgDeGender/ // idem for all other clubs hosted on this site
                portfolios/ // optional portfolio when generated using Lightroom plug-in
        expertises/ // Level 0 output: index page listing all expertises, linking to each ExpertisePage
            Abstract/ // Level 0 output: index of club members with the Abstract expertise tag
            Architecture/ // idem for all (both supported and temporary) other expertises
        expositions/ // future extension (doesn't exist yet)
        museums/ // future: Level 1 output for museums, analogous to clubs/
    en/ // English pages; no language-level home page (en/ is just a container)
        clubs/ // Level 1 output: index page listing all clubs, linking to each club's Level 2 page (not yet generated at this path)
            fcVeghel/ // Level 2 output: lists all (current and optionally former) members of fcVeghel
                portfolios/ // optional portfolio when generated using Lightroom plug-in
            fgDeGender/ // idem for all other clubs hosted on this site
                portfolios/ // optional portfolio when generated using Lightroom plug-in
        expertises/ // Level 0 output: index page listing all expertises, linking to each ExpertisePage
            Abstract/ // Level 0 output: index of club members with the Abstract expertise tag
            Architecture/ // idem for all (both supported and temporary) other expertises
        expositions/ // future extension (doesn't exist yet)
        museums/ // future: Level 1 output for museums, analogous to clubs/
    xx/ // other languages in the future go here

Notes:
- this is the to-be folder structure. The as-is structure is still quite different.
- Club directories are currently distributed across http://vdhamer.com and https://fcdegender.nl.
- In principle, any club may decide to host its own data on any server (e.g. the one with its website).
