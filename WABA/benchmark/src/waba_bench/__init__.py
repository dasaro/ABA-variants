"""
WABA Benchmark Suite

A modular benchmarking framework for Weighted Assumption-Based Argumentation.
"""

__version__ = "2.0.0"

from . import planner
from . import runner
from . import generator
from . import analyzer
from . import consistency
from . import utils

__all__ = [
    'planner',
    'runner',
    'generator',
    'analyzer',
    'consistency',
    'utils',
]
