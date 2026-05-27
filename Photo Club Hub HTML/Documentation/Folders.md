## Folder structure of generated output site

Build/
    nl/ // for Dutch website pages, is there a home page??
        clubs/ // clubs/ itself contains HTML version of <filename>.level2.json files, filtered to only show clubs
            fcVeghel/ // lists all (current and optionally former) members of fcVeghel
                portfolios/ // optional portfolio when generated using Lightroom plug-in
            fgDeGender/ // idem for all other clubs hosted on this site
                portfolios/ // optional portfolio when generated using Lightroom plug-in
        expertises/ // contains HTML version of root.level0.json files in one language
            Abstract/ // contains index of club members with the Abstract expertise tag
            Architecture/ // idem for all (both supported and temporary expertises) other expertises
        expositions/ // future extension (doesn't exist yet)
        museums/ // contains HTML version of <filename>.level2.json files, filtered to only show museums
    en/ // for English website pages, is there a home page??
        clubs/ // clubs/ itself contains HTML version of <filename>.level2.json files, filtered to only show clubs
            fcVeghel/ // lists all (current and optionally former) members of fcVeghel
                portfolios/ // optional portfolio when generated using Lightroom plug-in
            fgDeGender/ // idem for all other clubs hosted on this site
                portfolios/ // optional portfolio when generated using Lightroom plug-in
        expertises/ // contains HTML version of root.level0.json files in one language
            Abstract/ // contains index of club members with the Abstract expertise tag
            Architecture/ // idem for all (both supported and temporary expertises) other expertises
        expositions/ // future extension (doesn't exist yet)
        museums/ // contains HTML version of <filename>.level2.json files, filtered to only show museums
    xx/ // other languages in the future go here

Notes:
- this is the to-be folder structure. The as-is structure is still a quite different.
- Club directories are currently distributed across http://vdhamer.com and https://fcdegender.nl.
- In princple, any club may decide to host its own data on any server (e.g. the one with its website).
