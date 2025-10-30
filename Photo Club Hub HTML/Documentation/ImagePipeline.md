#  How do images flow through the software?

- Ignite stores the images (for Level 2 thumbnails) in a directory /images/DSC_6217.jpg relative to the root of the site
    - where is that directory? 
      ``/Users/petervandenhamer/Library/Containers/com.vdHamer.Photo-Club-Hub-HTML/Data/Build/images`` (Note **Data/Build** part of path)
    - that directory **IS** filled by copying files from elsewhere. Experiment: remove file and run Ignite app -> reappeared.
    - that directory **IS** cleared at the start of a build. Experiment: introduce a new file and run Ignite app -> file disappears.
    - the 155 image files are copied over from
      ``/Users/petervandenhamer/Library/Containers/com.vdHamer.Photo-Club-Hub-HTML/Data/Assets/images`` (Note **Data/Assets** part of path)
    - who copies the code from Data/Assets to Data/Build?? Code for publishing in Ignite

- Something puts the required images (and more?) into the Data/Assets folder
    - where is that directory?
      ``/Users/petervandenhamer/Library/Containers/com.vdHamer.Photo-Club-Hub-HTML/Data/Assets/images``
    - that directory **ISN'T** filled by copy files from elsewhere: Experiment: remove file and run Ignite app -> file doesn't reappear.
    - that directory **ISN'T** cleared at the start of a build. Experiment: introduce a new file and run Ignite app -> file doesn't disappear.
