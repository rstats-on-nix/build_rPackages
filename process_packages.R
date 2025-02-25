library(data.table)
library(jsonlite)
library(rix)

process_packages <- function(cran_json, default_nix, agg) {
  # Get broken packages from JSON
  df <- rbindlist(lapply(cran_json[["packages"]], as.data.table), fill = TRUE)
  broken_pkgs <- unique(df[broken == TRUE, name])
  agg <- agg[N > 3000] # 100 downloads per day
  agg[package == "import", package := "r_import"] #change in place
  
  # Get broken packages from default.nix
  start <- grep("brokenPackages =", default_nix)
  end <- which(grepl("\\];", default_nix)) 
  end <- end[end > start][1]

  if (length(start) > 0 && length(end) > 0) {
    brokenPackages <- trimws(default_nix[(start + 1):(end - 1)])
    brokenPackages <- gsub("_", ".", brokenPackages)
    brokenPackages <- grep("^\\s*#", brokenPackages, value = TRUE, invert = TRUE)
    brokenPackages <- gsub('[" ]', "", brokenPackages)  # Remove quotes and spaces
  } else {
    brokenPackages <- character(0)
  }

  system_os <- Sys.info()["sysname"]
  if (system_os == "Darwin") {
  # Get packagesRequiringX  from default.nix
    start <- grep("packagesRequiringX =", default_nix)
    end <- which(grepl("\\];", default_nix)) 
    end <- end[end > start][1]

    if (length(start) > 0 && length(end) > 0) {
      packagesRequiringX <- trimws(default_nix[(start + 1):(end - 1)])
      packagesRequiringX <- gsub("_", ".", packagesRequiringX)
      packagesRequiringX <- grep("^\\s*#", packagesRequiringX, value = TRUE, invert = TRUE)
      packagesRequiringX <- gsub('[" ]', "", packagesRequiringX)  # Remove quotes and spaces
    } else {
      packagesRequiringX <- character(0)
    }
  } else {
    packagesRequiringX <- character(0)
  }
  
  # Remove broken packages from list and packages requiring X (for darwin)
  colnames(agg) <- c("package", "N")
  pkgs <- setdiff(setdiff(setdiff(agg[["package"]], broken_pkgs), brokenPackages), packagesRequiringX)

  # Run rix
  rix(
    date = "2025-02-17",
    r_pkgs = pkgs,
    ide = "other",
    project_path = ".",
    overwrite = TRUE,
    print = TRUE
  )
}
