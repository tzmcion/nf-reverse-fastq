#!/bin/env python

import polars as pl
import colorama
import sys

ARGS = sys.argv

def _raise_error(index:int, msg:str):
    """
    Method raises exception and quits program, writes out the message provided in argument
    """
    raise RuntimeError(colorama.Fore.RED + "ERROR " + str(index) + ": " + colorama.Fore.LIGHTMAGENTA_EX + msg + colorama.Fore.RESET)

if(len(ARGS) != 3):
    _raise_error(1,"missing arguments -> needed are: [1]path to file with genes of interest and [2]path to .gtf file")
GENES_FILE = ARGS[1]
if(len(GENES_FILE) < 4):
    _raise_error(2, "incorrect name of the file or incorrect file type. Accepted is .tsv, .csv, .txt")
extension = GENES_FILE[-4:].lower()
if(extension not in [".tsv", ".csv", ".txt"]):
    _raise_error(2, "incorrect name of the file or incorrect file type. Accepted is .tsv, .csv, .txt")

df = pl.DataFrame()

try:
    df = pl.read_csv(GENES_FILE, has_header=False)
    if(len(df.columns) > 1):
        _raise_error(3, f"provided file for gene names: {GENES_FILE} is corrupted, does not exist, or canot be read. File should only have gene ids, one per line")
except:
    _raise_error(3, f"provided file for gene names: {GENES_FILE} is corrupted, does not exist, or canot be read. File should only have gene ids, one per line")

genes = [x.upper() for x in df.get_column(df.columns[0]).to_list()]

#Here get the gtf file

GTF_PATH = ARGS[2]
if(len(GTF_PATH) < 4):
    _raise_error(4, "incorrect name of the file for genome annotations. Accepted format is .gtf")
extension = GTF_PATH[-4:].lower()
if(extension != ".gtf"):
    _raise_error(4, "incorrect name of the file for genome annotations. Accepted format is .gtf")

df = pl.DataFrame()

#Calculate rows to skip
rows_to_skip = -1
with open(GTF_PATH, 'r') as f:
    start = "#"
    while start == "#":
        line = f.readline()
        start = line[0]
        rows_to_skip+=1

try:
    df = pl.read_csv(GTF_PATH, new_columns=["chrom", "source", "feature", "start", "stop", "score", "strand", "frame", "attribs"],
     separator="\t",
     skip_rows=rows_to_skip,
     has_header=False,
    ignore_errors=True,
    schema_overrides={"chrom": pl.String})
except:
    _raise_error(5, "GTF file is corrupted, could not convert to DataFrame correctly. Please check if it has 9 collumns, tab-separated")

df = df.filter(pl.col("feature").eq("gene"))

attribs = df.get_column("attribs")
gene_ids = []
gene_names = []

for attr in attribs:
    sp_attrs = str(attr).split(';')
    gene_id = ""
    gene_name = ""
    for sp_attr in sp_attrs:
        if("gene_id" in sp_attr):
            gene_id = sp_attr.strip().split(' ')[1].replace("\"","").upper()
        if("gene_name" in sp_attr):
            gene_name = sp_attr.strip().split(' ')[1].replace("\"","").upper()
    gene_ids.append(gene_id)
    gene_names.append(gene_name)

gene_ids_series = pl.Series("gene_id", gene_ids)
gene_names_series = pl.Series("gene_name", gene_names)

df = df.with_columns(gene_ids_series)
df = df.with_columns(gene_names_series)

#Assume gene_id cannot be identical to gene_name

results = pl.DataFrame()
results = df.filter(pl.col("gene_name").is_in(genes))
if(results.is_empty()):
    results = df.filter(pl.col("gene_id").is_in(genes))

if(results.is_empty()):
    print("#" + colorama.Fore.YELLOW + " [WARNING] " + colorama.Fore.RESET + "No genes were found based by ID (ex. ENSG00000071575) or name (ex. BRCA1) with provided list: " + colorama.Fore.LIGHTMAGENTA_EX + str(genes) + colorama.Fore.RESET)

idx = 0
for row in results.iter_rows():
    chrom = row[0]
    attr = row[8]
    sp_attrs = str(attr).split(';')
    gene_name = ""
    for sp_attr in sp_attrs:
        if("gene_name" in sp_attr):
            gene_name = sp_attr.strip().split(' ')[1].replace("\"","").upper()
    start = int(row[3])

    end = int(row[4])
    print(f"{gene_name};{chrom}:{start}-{end}")
    idx+=1