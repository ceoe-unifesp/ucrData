shr_years <- function() {
  res <- "https://cde.ucr.cjis.gov/LATEST/webapp/assets/JSON/downloads/masters.json" |>
    httr::GET() |>
    httr::content() |>
    purrr::keep(\(x) x$id == "shr") |>
    purrr::pluck(1)

  seq(res$minYear, res$maxYear)
}

shr_links <- function(years = shr_years()) {
  years |>
    purrr::map(\(yr) {
      u <- glue::glue("https://cde.ucr.cjis.gov/LATEST/s3/signedurl?key=nibrs/master/shr/shr-{yr}.zip")
      httr::GET(u) |>
        httr::content()
    }, .progress = TRUE)
}

shr_download <- function(link_data, path) {
  u <- link_data[[1]]
  nm <- basename(names(link_data))
  f <- file.path(path, nm)
  if (!file.exists(f)) {
    httr::GET(u, httr::write_disk(f, TRUE))
  }
  f
}

shr_unzip <- function(zip_file, path) {
  file_name_within_zip <- zip::zip_list(zip_file)$filename
  txt_file_old <- fs::path(path, file_name_within_zip)
  file_name_zip <- fs::path_file(zip_file)
  file_name_txt <- fs::path_ext_set(file_name_zip, "txt")
  txt_file_new <- fs::path(path, file_name_txt)
  zip::unzip(zip_file, exdir = path)
  fs::file_move(txt_file_old, txt_file_new)
}

repeated_specs <- function(num, type) {
  if (type == "victim") {
    v <- c("age", "sex", "race", "ethnic")
    sprintf('%s_%02d_%s', type, num, v)
  } else {
    v <- c(
      "age", "sex", "race", "ethnic", "weapon",
      "relat", "circ", "subcirc"
    )
    sprintf('%s_%02d_%s', type, num, v)
  }
}

shr_fwf_specs <- function() {
  nms <- repeated_specs
  shr_fwf_fixed <- readr::fwf_positions(
    start = c(
      1, 2,  4, 11, 13, 14, 16, 25, 28, 31, 32, 56, 62, 64, 70, 71, 72, 75,
      76, 78, 79, 80, 81, 83, 84, 85, 86, 88, 90, 92, 93, 96,
      98 + cumsum(rep(c(1, 2, 1, 1), 10)),
      148 + cumsum(rep(c(1, 2, 1, 1, 1, 2, 2, 2), 10))
    ),
    end =   c(
      1, 3, 10, 12, 13, 15, 24, 27, 30, 31, 55, 61, 63, 69, 70, 71, 74, 75,
      77, 78, 79, 80, 82, 83, 84, 85, 87, 89, 91, 92, 95, 98,
      98 + cumsum(rep(c(2, 1, 1, 1), 10)),
      148 + cumsum(rep(c(2, 1, 1, 1, 2, 2, 2, 1), 10))
    ),
    col_names = c(
      "identifier", "state_code", "ori_code", "group", "division", "year",
      "population", "county", "msa", "msa_ind", "agency_name", "state_name",
      "offense_month", "last_update", "action_type", "homicide",
      "incident_number", "situation",
      nms(1, "victim"), nms(1, "offender"),
      "victim_count", "offender_count",
      # repeat until victim_11_xxx and offender_11_xxx
      nms(2, "victim"), nms(3, "victim"), nms(4, "victim"),
      nms(5, "victim"), nms(6, "victim"), nms(7, "victim"),
      nms(8, "victim"), nms(9, "victim"), nms(10, "victim"),
      nms(11, "victim"),
      nms(2, "offender"), nms(3, "offender"), nms(4, "offender"),
      nms(5, "offender"), nms(6, "offender"), nms(7, "offender"),
      nms(8, "offender"), nms(9, "offender"), nms(10, "offender"),
      nms(11, "offender")
    )
  )
  shr_fwf_fixed
}

shr_col_types <- function() {
  readr::cols(
    identifier = readr::col_character(),
    state_code = readr::col_character(),
    ori_code = readr::col_character(),
    group = readr::col_character(),
    division = readr::col_character(),
    year = readr::col_double(),
    population = readr::col_double(),
    county = readr::col_character(),
    msa = readr::col_character(),
    msa_ind = readr::col_integer(),
    agency_name = readr::col_character(),
    state_name = readr::col_character(),
    offense_month = readr::col_number(),
    last_update = readr::col_character(),
    action_type = readr::col_integer(),
    homicide = readr::col_character(),
    incident_number = readr::col_character(),
    situation = readr::col_character(),
    victim_count = readr::col_double(),
    offender_count = readr::col_double(),
    .default = readr::col_character()
  )
}

shr_read <- function(file) {
  readr::read_fwf(
    file,
    col_positions = shr_fwf_specs(),
    guess_max = 1e6,
    col_types = shr_col_types()
  )
}

read_shr_online <- function(years = shr_years(),
                            verbose = TRUE,
                            path = fs::file_temp("shr")) {
  if (verbose) usethis::ui_info("Getting SHR links...")
  links <- shr_links(years)
  if (verbose) usethis::ui_done("Done!")
  if (verbose) usethis::ui_info("Downloading raw files...")
  path_zip <- fs::path(path, "zip")
  fs::dir_create(path_zip)
  purrr::walk(links, \(x) shr_download(x, path_zip), .progress = TRUE)
  if (verbose) usethis::ui_done("Done!")
  if (verbose) usethis::ui_info("Extracting raw files...")
  path_txt <- fs::path(path, "txt")
  fs::dir_create(path_txt)
  zip_files <- fs::dir_ls(path_zip)
  purrr::walk(zip_files, \(x) shr_unzip(x, path_txt), .progress = TRUE)
  if (verbose) usethis::ui_done("Done!")
  if (verbose) usethis::ui_info("Reading raw files...")
  txt_files <- fs::dir_ls(path_txt)
  names(txt_files) <- substr(fs::path_file(txt_files), 5, 8)
  res_list <- purrr::map(txt_files, shr_read, .progress = TRUE)
  da <- purrr::list_rbind(res_list, names_to = "file_year")
  if (verbose) usethis::ui_done("Done!")
  if (verbose) usethis::ui_info("Cleaning up...")
  fs::dir_delete(path)
  da
}
