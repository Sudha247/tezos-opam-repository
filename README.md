# Tezos artefacts

This repository contains different artefacts used in [Tezos](https://gitlab.com/tezos/tezos)

- *packages* contains specific OPAM packages.
- *zcash-params* contains the Sapling parameters.
- *scripts* contains miscellaneous scripts.

## Dockerfiles

Several dockerfiles are provided to build docker images used in the CI of the repository [Tezos](https://gitlab.com/tezos/tezos)
- *minimal.Dockerfile* is the base image used to build Tezos docker images.
- *opam.Dockerfile* is the base image used by the different jobs of the CI

## Poetry files

*poetry.lock* and *pyproject.toml* are related to the Python tests and scripts used in Tezos. They
must not be modified independently from the ones provided in the Tezos repo. They are used to build
the virtual environment the CI jobs will use. They are useful to speed up the jobs.
