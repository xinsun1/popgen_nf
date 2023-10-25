process SMARTPCA_PAR {
    tag '$batch_id'
    label 'process_medium'
    cpus 2

    input:
    val batch_id
    val eigen_file
    val eigen_ind_file
    val pop_file
    val n_chr
    val lsqprj
    path wdir

    output:
    path par.${batch_id}, emit: par_file
    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
    """
    echo '
genotypename:   ${eigen_file}.geno
snpname:        ${eigen_file}.snp
indivname:      ${eigen_ind_file}
evecoutname:    ${batch_id}.evec
evaloutname:    ${batch_id}.eval
lsqproject:     ${lsqprj}
numthreads:     ${task.cpus}
numchrom:       ${n_chr}
poplistname:    ${pop_file}
numoutlieriter: 0' > ${wdir}/par.${batch_id}
    echo '${args}' >> ${wdir}/par.${batch_id}
    """
}

process SMARTPCA {
    tag '$batch_id'
    label 'process_medium'
    cpus 2

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eigensoft%3A8.0.0--h6a739c9_3' :
        '/maps/projects/mjolnir1/people/gnr216/a-software/sigularity_module/eigensoft:8.0.0--h6a739c9_3'}"

    input:
    path par_file
    val batch_id

    output:
    path "*.evec", emit: evalout
    path "*.evec", emit: evecout
    path "log.*", emit: log_pca

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    smartpca \\
        -p ${par_file} \\
        > log.${batch_id}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(smartpca) | sed 's/^.*version: //; s/Using.*\$//' ))
    END_VERSIONS
    """
}