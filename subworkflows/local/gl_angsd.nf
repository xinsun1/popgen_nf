//
// Call genotype likelihoods with ANGSD
//

nextflow.enable.dsl = 2

include { GL_CHR; GL_CLEAN; } from '../../modules/local/angsd_gl.nf'

workflow ANGSD_GL {
    take:
    meta_batch
    list_region
    

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t', quote: '"')
    | map { row ->
        meta_gl = [
            batch:          row.BATCH,
            list_bam:       file(row.LIST_BAM),
            param_gl:       row.GL_PARA,
            n:              row.N,
            maf:            row.MAF,
            mis:            row.MIS
        ]
    }
    | set { meta_gl }

    Channel.fromPath(list_region)
    | splitText()
    | map{it -> it.trim()}
    | set {ch_region}
    
    ch_meta_region = meta_gl
        .combine(ch_region)

    GL_CHR (ch_meta_region)
    GL_CLEAN (ch_meta_region)

    batch = meta_gl.first().batch
    maf = meta_gl.first().maf
    mis = meta_gl.first().mis
    
    ch_region 
        .map {it ->
            "${params.wdir}gl_chr/${batch}.${it}.tv_maf${maf}_mis${mis}.beagle"} \
        .collectFile("${batch}.tv_maf${maf}_mis${mis}.beagle",
            storeDir: params.wdir,
            keepHeader: true,
            skip: 1,
            sort: false)



    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

workflow {
    ANGSD_GL ( params.meta, params.list_region )
}
