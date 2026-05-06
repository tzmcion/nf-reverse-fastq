process gene_location {
    cpus 4
    conda "./environments/python_envs.yaml"

    input:
    path genes_names
    path gtf_file

    output:
    path "./localizations.csv", emit: genes_locs

    script:
    """
    gzip -d -c ${gtf_file} > ./annots.gtf
    extract_genes_location.py ${genes_names} ./annots.gtf > ./localizations.csv
    """
}