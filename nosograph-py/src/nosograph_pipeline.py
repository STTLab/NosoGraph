from __future__ import annotations

import logging
import subprocess
from pathlib import Path
from typing import Optional, List


class NosoGraphPipelineError(Exception):
    """Custom exception for pipeline failures."""
    pass

class NosoGraphPipeline:

    VALID_ASSEMBLERS = {"canu", "flye"}
    VALID_TECHNOLOGIES = {"pacbio", "nanopore"}

    def __init__(
        self,
        script_path: str,
        long_reads: str,
        short_r1: str,
        short_r2: str,
        assembler: str,
        technology: str,
        outdir: str,
        genome_size: Optional[str] = None,
        threads: int = 1,
        racon_iter: int = 0,
        pilon_iter: int = 0,
    ) -> None:

        self._logger = logging.getLogger(self.__class__.__name__)

        self.script_path = Path(script_path)

        self.long_reads = Path(long_reads)
        self.short_r1 = Path(short_r1)
        self.short_r2 = Path(short_r2)

        self.assembler = assembler
        self.technology = technology

        self.genome_size = genome_size

        self.outdir = Path(outdir)

        self.threads = threads
        self.racon_iter = racon_iter
        self.pilon_iter = pilon_iter

        self._validate()

    def _validate(self) -> None:
        if not self.script_path.exists():
            raise FileNotFoundError(
                f"Pipeline script not found: {self.script_path}"
            )
        if self.assembler not in self.VALID_ASSEMBLERS:
            raise ValueError(
                f"Invalid assembler '{self.assembler}'. "
                f"Choose from {self.VALID_ASSEMBLERS}"
            )
        if self.technology not in self.VALID_TECHNOLOGIES:
            raise ValueError(
                f"Invalid technology '{self.technology}'. "
                f"Choose from {self.VALID_TECHNOLOGIES}"
            )
        if self.assembler == "canu" and not self.genome_size:
            raise ValueError(
                "genome_size is required when assembler='canu'"
            )

    def build_command(self) -> List[str]:
        cmd = [
            str(self.script_path),
            "-l", str(self.long_reads),
            "-1", str(self.short_r1),
            "-2", str(self.short_r2),
            "-asm", self.assembler,
            "-tech", self.technology,
            "-o", str(self.outdir),
            "-t", str(self.threads),
            "--racon-iter", str(self.racon_iter),
            "--pilon-iter", str(self.pilon_iter),
        ]
        if self.genome_size:
            cmd.extend(["-g", self.genome_size])

        return cmd

    def run(
        self,
        cwd: Optional[str] = None,
        env: Optional[dict] = None,
    ) -> int:

        cmd = self.build_command()

        self._logger.info("Starting NosoGraph pipeline")
        self._logger.info("Command: %s", " ".join(cmd))

        try:
            process = subprocess.Popen(
                cmd,
                cwd=cwd,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True,
            )

            assert process.stdout is not None
            assert process.stderr is not None

            while True:
                stdout_line = process.stdout.readline()
                stderr_line = process.stderr.readline()

                if stdout_line:
                    self._logger.info(stdout_line.rstrip())

                if stderr_line:
                    self._logger.error(stderr_line.rstrip())

                if (
                    stdout_line == ""
                    and stderr_line == ""
                    and process.poll() is not None
                ):
                    break

            return_code = process.wait()
            if return_code != 0:
                self._logger.error(
                    "Pipeline exited with code %s",
                    return_code,
                )
                raise NosoGraphPipelineError(
                    f"Pipeline failed with exit code {return_code}"
                )

            self._logger.info("Pipeline completed successfully")
            return return_code

        except FileNotFoundError as e:
            self._logger.exception("Executable not found")
            raise NosoGraphPipelineError(str(e)) from e

        except subprocess.SubprocessError as e:
            self._logger.exception("Subprocess execution failed")
            raise NosoGraphPipelineError(str(e)) from e

        except Exception as e:
            self._logger.exception("Unexpected pipeline error")
            raise NosoGraphPipelineError(str(e)) from e
