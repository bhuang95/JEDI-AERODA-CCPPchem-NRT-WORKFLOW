import argparse
from netCDF4 import Dataset
import numpy as np
import os

# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument("filepath", type=str, help="File path")
args = parser.parse_args()

# Open file
f = Dataset(args.filepath, "a", format="NETCDF4")

# Loop over groups
for group in f.groups:
    # Get nsc dimension
    nsc = f.groups[group].dimensions["nsc"].size

    # Add attribute
    f.groups[group].nsc = nsc
