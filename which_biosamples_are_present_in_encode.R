is_sample_in_encode <- function(samples_to_check_filepath){

  samples_to_check <- readLines(samples_to_check_filepath)
  encode_experiment_matrix_path <- "encode_experiment_matrix.tsv"
  encode_experiment_matrix_df <- read.csv(encode_experiment_matrix_path, header = TRUE, sep = "\t")

  included_samples <- encode_experiment_matrix_df$sample[match(
    gsub("[- +_]", "", tolower(samples_to_check), perl = TRUE),
    gsub("[- +_]", "", tolower(encode_experiment_matrix_df$sample), perl = TRUE)
  )]

  included_samples <- included_samples[!is.na(included_samples)]
  write(included_samples,stdout())
}

#is_sample_in_encode("cell_lines_of_interest")
