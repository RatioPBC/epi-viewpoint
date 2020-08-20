## Editor config

For IntelliJ IDEA, create a new File Watcher to format code when a file changes.

1. Open Preferences
2. Go to "Tools > File Watchers"
3. Create a new file watcher and set the following:
    * “Name”: “format everything”
    * “File type”: “Any”
    * “Scope”: “All Places”
    * “Program”: “$ProjectFileDir$/bin/dev/format”
    * “Arguments”: “$FilePath$”
    * “Output paths to refresh: “$FilePath$”
    * “Working directory”: “$ProjectFileDir$”
    * Expand "Advanced Options"
        * Uncheck "Auto-save edited files to trigger the watcher"
        * Uncheck "Trigger the watcher on external changes"
