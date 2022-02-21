<p align="center">
  <img src="https://user-images.githubusercontent.com/25080503/65772647-89525700-e132-11e9-80ff-12ad30a25466.png">
</p>

[![Documentation Status](https://readthedocs.org/projects/dbtvault/badge/?version=latest)](https://dbtvault.readthedocs.io/en/latest/?badge=latest)

# Documentation for [dbtvault](https://github.com/Datavault-UK/dbtvault)

## Developing

This documentation website uses the [mkdocs documentation framework](https://www.mkdocs.org/) and 
the [material for mkdocs](https://squidfunk.github.io/mkdocs-material/) theme. 

### Modifying
To update any docs, simply edit the corresponding `.md` files in the `docs/` directory.

### Running locally
- Ensure that dependencies are installed from the provided `Pipfile`. 
Note: Ignore the `docs/requirements.txt` file for local development. This dependency file is for automated builders.
- Run `mkdocs serve` from the terminal
- This local website will automatically re-generate itself as you make changes, so no need to close it down.