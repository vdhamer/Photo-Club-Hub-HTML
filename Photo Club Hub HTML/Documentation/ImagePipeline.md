#  How do images flow through the software?

- Ignite stores the images (for Level 2 thumbnails) in a directory /images/DSC_6217.jpg relative to the root of the site
    - where is that directory? 
      ``/Users/petervandenhamer/Library/Containers/com.vdHamer.Photo-Club-Hub-HTML/**Data/Build**/images``
    - that directory **IS** filled by copying files from elsewhere. Experiment: remove file and run Ignite app -> reappeared.
    - that directory **IS** cleared at the start of a build. Experiment: add a new file and run  Ignite app -> file gone.
    - where are the 155 (!) files copied from?
