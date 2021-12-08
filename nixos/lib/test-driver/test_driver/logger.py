from colorama import Style
from contextlib import contextmanager
from queue import Queue, Empty
from typing import Any, Dict, Iterator, Tuple
from xml.sax.saxutils import XMLGenerator

import codecs
import logging
import os
import sys
import time
import unicodedata

logging.basicConfig(format="%(message)s")
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

machine_colours_iter = (
    "\x1b[{}m".format(x) for x in itertools.cycle(reversed(range(31, 37)))
)


class MachineLogAdapter(logging.LoggerAdapter):
    def process(self, msg: str, kwargs: Any) -> Tuple[str, Any]:
        return (
            f"{self.extra['colour_code']}{self.extra['machine']}\x1b[39m: {msg}",
            kwargs,
        )


class SerialFilter(logging.Filter):
    """Drop serial logs."""

    def filter(self, record):
        return not getattr(record, "serial_logger", False)


serial_filter = SerialFilter()
