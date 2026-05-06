<br />
<div align="center">
  <a href="https://github.com/tzmcion">
    <img src="https://repository-images.githubusercontent.com/9052236/ecd9481e-f4b3-4324-b832-a08ee1d99564" alt="Logo" width="100" height="60">
    <h3>nf-reverse-fastq</h3>
  </a>
</div>
<hr>
This flow downloads hg38 reference genome file (.fasta), as well as it's annotations file (.gtf) from `ensembl.org`
Then using SRA records (SRR*****) given in `/input_files/SRA.csv` and gene names given in `/input_files/genes.csv` it extract the fastq records which cover the regions of specified genes, and saves them to `/results/{SRR_ID}_{gene_id}.fastq`. 

### Computational time:
 - **First run** of the flow will take some time (~2h), as reference genome, annotations, and building index (most time consuming) need some time to download and process.
 - **N-run** will mostly depend on download speed, as extracting information takes short time (for a few genes around 2 minutes).

### Usage:
1. Create a conda environment with nextflow, or have nextflow installed
2. Create a profile for your run in `nextflow.config` and set params for your project:
```{nf}
profiles {
    test_run {
        params.batch = "/test_run"
    }
    default_run {
        params.batch = ""
        params.csvSRA = "./input_files/SRA.csv"
        params.genes = "./input_files/genes.csv"
    }
    {your_new_profile_name} {
        params.batch = {/your_batch_name}
        params.csvSRA = {path_to_your_SRA.csv}
        params.genes = {path_to_your_genes.csv}
    }
}
```
3. Create the .csv files for flow input

The csv files with genes of interest only must have in first column the gene name or SRA id. Other columns may also appear, but will not be used: <br>
*You can just follow the same patterns/templates which are already in input_files. Only data in first column is used by the flow*


4. Run the flow with `nextflow run ./main.nf -profile {your_new_profile_name}`
