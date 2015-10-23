# ==============================================================================
#           File: Rprofile
#         Author: Pedro Ferrari
#        Created: 13 Aug 2015
#  Last Modified: 23 Oct 2015
#    Description: My R profile file
# ==============================================================================
# Set default CRAN mirror to Argentina
options(repos = "http://mirror.fcaglp.unlp.edu.ar/CRAN/")

# Prompt similar to Python REPL
options(prompt=">>> ")
options(continue="... ")

# Don't convert strings to factor variables in a data.frame
options(stringsAsFactors=FALSE)

# Don't show significance stars in regressions summary
options(show.signif.stars=FALSE)

# Change plot window defaults
setHook(packageEvent("grDevices", "onLoad"), function(...) {
            grDevices::windows.options(width=6.5, height=5.5, xpos=-500,
                                       ypos=-700)})
# Give warnings on partial matches
# options(warnPartialMatchAttr = TRUE, warnPartialMatchDollar = TRUE,
        # warnPartialMatchArgs = TRUE)

# To use with vim-R-plugin
# library(vimcom)
