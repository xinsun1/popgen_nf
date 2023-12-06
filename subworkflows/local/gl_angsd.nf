//
// Call genotype likelihoods with ANGSD
//

nextflow.enable.dsl = 2

include { GL_CHR;                    }    from '../../modules/local/angsd_gl.nf'
include { GL_FILTER;                 }    from '../../modules/local/angsd_gl.nf'

workflow ANGSD_GL {
    take:
    list_region
    
    main:
    
    // run gl per region
    if ( params.run_gl == true) {
        ch_region = Channel.fromPath(list_region)
          .splitText()
          .map{it -> it.trim()}
    
        ch_gl_chr = GL_CHR (
            params.batch,
            file(params.list_bam),
            ch_region,
            params.gl_param
            )
        gl_done = ch_gl_chr.done.collect()
    }
    else {
        gl_done = true
    }


    // filter gl per region
    if ( params.run_filter == true) {
        ch_gl_filter = GL_FILTER (
            gl_done,                // val ready
            params.batch,           // val batch
            file(list_region),      // path region
            params.maf,             // val maf
            params.n,               // val n
            params.mis,             // val mis
        )
    }

    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

workflow {
    ANGSD_GL ( params.list_region )
}
