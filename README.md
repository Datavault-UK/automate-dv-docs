<p align="center">
  <img src="https://user-images.githubusercontent.com/25080503/237990810-ab2e14cf-a449-47ac-8c72-6f0857816194.png#gh-light-mode-only" alt="AutomateDV">
  <img src="https://user-images.githubusercontent.com/25080503/237990915-6afbeba8-9e80-44cb-a57b-5b5966ab5c02.png#gh-dark-mode-only" alt="AutomateDV">
</p>

[![Documentation Status](https://readthedocs.org/projects/automate_dv/badge/?version=latest)](https://automate-dv.readthedocs.io/en/latest/?badge=latest)

# Documentation for [AutomateDV](https://github.com/Datavault-UK/automate-dv)

## Developing

This documentation website is built with [Zensical](https://zensical.org/). 
Site configuration lives in `mkdocs.yml`, which Zensical reads directly.

### Modifying
To update any docs, simply edit the corresponding `.md` files in the `docs/` directory.

### Running locally
- Ensure that dependencies are installed from the provided `Pipfile` (`pipenv install`).
Note: Ignore the `docs/requirements.txt` file for local development. This dependency file is for automated builders.
- Run `zensical serve` from the terminal
- This local website will automatically re-generate itself as you make changes, so no need to close it down.

### Updating dependencies
`docs/requirements.txt` is used by Read the Docs and is generated from `Pipfile.lock`. 
After changing the `Pipfile`, regenerate it with:

```bash
pipenv lock
pipenv requirements > docs/requirements.txt
```