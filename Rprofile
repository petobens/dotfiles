# Set default CRAN mirror to USA
options(repos = "http://cran.us.r-project.org")

# Prompt similar to Python REPL
options(prompt=">>> ")
options(continue="... ")

# Don't convert strings to factor variables by default in a data.frame
options(stringsAsFactors=FALSE)

# Don't show significance stars in regressions summary
options(show.signif.stars=FALSE)

# Give warnings on partial matches
# options(warnPartialMatchAttr = TRUE, warnPartialMatchDollar = TRUE,
        # warnPartialMatchArgs = TRUE)

# Load some libraries by default
if (interactive()) {
    require("colorout", quietly = TRUE)
    setOutputColors(normal = 145, negnum = 173, zero = 173,
                    number = 173, date = 114, string = 114,
                    const = 38 , false = 170, true = 170,
                    infinite = 173, index = 39, stderror = 204,
                    warn = c(235, 173), error = c(235, 204),
                    verbose = FALSE, zero.limit = NA)
}
