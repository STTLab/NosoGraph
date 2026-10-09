<!-- SPDX-License-Identifier: MPL-2.0 -->
# Example Nextflow configs

Ready-to-copy config files for running `--pipeline autocycler`. Copy one, edit the values marked in its comments, and pass it with `-c`:

```bash
cp example/nextflow-config/autocycler-workstation.config my-run.config
# edit my-run.config
nextflow run main.nf -profile micromamba -c my-run.config \
    --long_reads /data/reads/BAC_S001.fastq.gz --outdir results/BAC_S001
```

Command-line options such as `--threads 16` still override anything in the file.

| File | Use it for |
|---|---|
| [`autocycler-workstation.config`](autocycler-workstation.config) | One machine. Caps total CPU and memory so jobs queue instead of overloading it. |
| [`autocycler-slurm.config`](autocycler-slurm.config) | A SLURM cluster. Partition, queue size, per-step resources and a shared Singularity cache. |
| [`autocycler-canu-stack.config`](autocycler-canu-stack.config) | Adding `canu` to the assemblers, with larger limits for canu jobs only. |
| [`autocycler-frozen-conda-env.config`](autocycler-frozen-conda-env.config) | A conda env built once and frozen, so nothing is solved or downloaded at run time. |
| [`autocycler-pinned-image.config`](autocycler-pinned-image.config) | An exact container image (by digest), or a local `.sif` file. |

## Things to know

- **Choose the engine with `-profile`, not in the file.** Use `-profile micromamba` for conda or `-profile singularity` for containers, and add `slurm` for a cluster (`-profile slurm,singularity`). Setting `params.engine` inside a `-c` file has no effect.
- **Set the SLURM partition as `process.queue`** in the file, or pass `--queue` on the command line. `params.queue` inside a `-c` file is ignored.
- **One job can't ask for more than the machine has.** With the local executor, a job requesting more CPUs (`threads`) or memory than the machine has fails immediately with `Process requirement exceeds available CPUs/memory`. Lower `threads` or the `memory` values to fit.
- **One `--outdir` per sample.** The Autocycler pipeline has no `--sample_id`, so samples sharing an output folder overwrite each other.
- **Combine files** by repeating `-c`, for example `-c autocycler-slurm.config -c autocycler-canu-stack.config`. Later files win where they overlap.
- To see what Nextflow will actually use, run `nextflow -c my-run.config config -profile <profiles>`.

More detail on the pipeline and on choosing assemblers: [Autocycler Tutorial](https://github.com/STTLab/NosoGraph/wiki/Autocycler-Tutorial).
