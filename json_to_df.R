encode_experiments_df <- jsonlite::fromJSON("encode_experiment_matrix.simple.json")
write.table(x = encode_experiments_df, file = "encode_experiment_matrix.tsv", sep = "\t", col.names = TRUE, row.names = FALSE, quote = FALSE)
