from pathlib import Path

import io
import logging
import os
import pty
import subprocess

logger = logging.getLogger(__name__)


class VLan:
    """This class handles a VLAN that the run-vm scripts identify via its
    number handles. The network's lifetime equals the object's lifetime.
    """

    nr: int
    socket_dir: Path

    process: subprocess.Popen
    pid: int
    fd: io.TextIOBase

    def __repr__(self) -> str:
        return f"<Vlan Nr. {self.nr}>"

    def __init__(self, nr: int, tmp_dir: Path):
        self.nr = nr
        self.socket_dir = tmp_dir / f"vde{self.nr}.ctl"

        # TODO: don't side-effect environment here
        os.environ[f"QEMU_VDE_SOCKET_{self.nr}"] = str(self.socket_dir)

        logger.info("start vlan")
        pty_master, pty_slave = pty.openpty()

        self.process = subprocess.Popen(
            ["vde_switch", "-s", self.socket_dir, "--dirmode", "0700"],
            stdin=pty_slave,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=False,
        )
        self.pid = self.process.pid
        self.fd = os.fdopen(pty_master, "w")
        self.fd.write("version\n")

        # TODO: perl version checks if this can be read from
        # an if not, dies. we could hang here forever. Fix it.
        assert self.process.stdout is not None
        self.process.stdout.readline()
        if not (self.socket_dir / "ctl").exists():
            raise Exception("cannot start vde_switch")

        logger.info(f"running vlan (pid {self.pid})")

    def __del__(self) -> None:
        logger.info(f"kill vlan (pid {self.pid})")
        self.fd.close()
        self.process.terminate()
