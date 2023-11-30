//
// Call genotype likelihoods with ANGSD
//

nextflow.enable.dsl = 2

include { GL_CHR; GL_CLEAN; } from '../../modules/local/angsd_gl.nf'

workflow ANGSD_GL {
    take:
    list_region
    
    main:
    
    // run gl per region
    ch_region = Channel.fromPath(list_region)
      .splitText()
      .map{it -> it.trim()}
    
    ch_gl_chr = GL_CHR (
        params.batch,
        file(params.list_bam),
        ch_region,
        params.gl_param
        )

    // filter gl per region
    ch_gl_clean = GL_CLEAN (
        ch_gl_chr.done,         // val ready
        params.batch,           // val batch
        file(params.list_bam),  // path list_bam
        ch_region,              // val region
        params.maf,             // val maf
        params.n,               // val n
        params.mis,             // val mis
    )
    // merge output
    ch_gl_clean.beagle
        .view()
    
    // ch_region 
    // | map {it ->
    //         "${params.wdir}gl_chr/${meta_gl_first.batch}.${it}.tv_maf${meta_gl_first.maf}_mis${meta_gl_first.mis}.beagle"}
    // | view()

//     | collectFile("${meta_gl_first.batch}.tv_maf${meta_gl_first.maf}_mis${meta_gl_first.mis}.beagle",
//             storeDir: params.wdir,
//             keepHeader: true,
//             skip: 1,
//             sort: false)
// 


    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

workflow {
    ANGSD_GL ( params.list_region )
}
