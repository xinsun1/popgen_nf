process GL_CHR {
    tag "$batch_id"
    label 'process_medium'
    executor 'slurm'
    // executor 'local'
    cpus 1
    time '24h'
    queue 'cpuqueue'
    memory '16 GB'
    // remember to set executor.perCpuMemAllocation = true in config file


    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/angsd%3A0.940--hce60e53_2' :
        'angsd:0.940--hce60e53_2'}"

    publishDir(
        path: "${params.wdir}gl_chr",
        mode: 'move',
    )

    input:
    val batch
    path list_bam
    val region
    val param_gl

    output:
    path "*.beagle.gz", emit: beagle_gz
    path "*.arg", emit: arg
    path "*.mafs.gz", emit: maf_gz
    val true, emit: done

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    
    """
    angsd -remove_bads 1 -uniqueOnly 1 \\
        -out ${batch}.${region} \\
        ${param_gl} \\
        -nThreads 1 \\
        -bam ${list_bam} \\
        -r ${region}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(angsd))
    END_VERSIONS
    """
}

process GL_FILTER {
    tag "$batch_id"
    label 'process_low'
    executor 'slurm'
    // executor 'local'
    cpus 2
    time '12h'
    queue 'cpuqueue'
    memory '24 GB'

    // remember to set executor.perCpuMemAllocation = true in config file
    
    publishDir(
        path:     "${params.wdir}gl_chr",
        pattern:  "${batch}.*.is_tv_maf${maf}_mis${mis}",
        mode:     'move',
    )
    publishDir(
        path:     "${params.wdir}",
        pattern:  "${batch}.tv_maf${maf}_mis${mis}.*gz",
        mode:     'move',
    )

    input:
    val ready
    val batch
    path list_region
    val maf
    val n
    val mis

    output:
    path "${batch}.*.is_tv_maf${maf}_mis${mis}", emit: is_f
    path "${batch}.tv_maf${maf}_mis${mis}.beagle.gz", emit: beagle
    path "${batch}.tv_maf${maf}_mis${mis}.mafs.gz", emit: maf
    val true, emit: done

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    f_mafs="${batch}.tv_maf${maf}_mis${mis}.mafs"
    f_beagle="${batch}.tv_maf${maf}_mis${mis}.beagle"

    idx=1
    for region in \$(less ${list_region})
    do
        maf_gz="${params.wdir}gl_chr/${batch}.\${region}.mafs.gz"
        beagle_gz="${params.wdir}gl_chr/${batch}.\${region}.beagle.gz"
        region_filter="${batch}.\${region}.is_tv_maf${maf}_mis${mis}"

        # is first file
        if [ \$idx -eq 1 ]; then
            zcat \${maf_gz} | head -1 > \${f_mafs}
            zcat \${beagle_gz} | head -1 > \${f_beagle}
        fi
        
        # check filter 
        zcat \${maf_gz} | \\
        awk '{\\
            if(NR==1){print 1}\\
            else{if(\\
            (\$3=="A" && \$4=="G") || \\
            (\$3=="T" && \$4=="C") || \\
            (\$3=="C" && \$4=="T") || \\
            (\$3=="G" && \$4=="A") || \\
            \$5 < (${maf}/100) || \\
            \$5 > (1-(${maf}/100)) || \\
            \$6/${n} < (${mis}/100)\\
            ){print 0}\\
            else{print 1}\\
            }}' \\
            > \${region_filter}
        
        zcat \${beagle_gz} | \\
        awk 'NR==FNR \\
            {a[FNR]=\$1} \\
            NR != FNR \\
            {if(a[FNR]==1){print \$0}}' \\
            \${region_filter} \\
            - | \\
            tail -n +2 \\
            >> \${f_beagle} &

        zcat \${maf_gz} | \\
        awk 'NR==FNR {a[FNR]=\$1} \\
            NR != FNR \\
            {if(a[FNR]==1){print \$0}}' \\
            \${region_filter} \\
            - | \\
            tail -n +2 \\
            >> \${f_mafs} &
        wait

        (( idx+=1 ))

    done

    gzip \${f_beagle} &
    gzip \${f_mafs} &
    wait 
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo bash))
    END_VERSIONS
    """
}
