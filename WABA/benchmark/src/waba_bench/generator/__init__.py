"""
Framework Generator Module

Generates WABA framework instances with various topologies and parameters.
"""

from .framework_templates import FrameworkGenerator
from .dimension_config import DimensionConfig
from .balanced_config import BalancedConfig

__all__ = [
    'FrameworkGenerator',
    'DimensionConfig',
    'BalancedConfig',
]
