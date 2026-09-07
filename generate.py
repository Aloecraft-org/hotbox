#!/usr/bin/env python3
"""Render one build context per image from config/images.yaml.

Entry point:   generate.py <images.yaml> <build-dir>
Output:        <build-dir>/<name>/{Containerfile,packages.txt}, one per image.
               Image names go to stdout in YAML order, for build.sh to read;
               progress goes to stderr.
Fan-out:       the "images" section of the YAML; "images_other" is not built.
"""

import pathlib
import re
import shutil
import sys

try:
    import yaml
except ModuleNotFoundError:
    sys.exit("generate.py needs PyYAML: apt install python3-yaml")

CONTAINERFILE = """\
# Generated from {src}. Do not edit; edit the YAML and re-run build.sh.
FROM {base}
COPY packages.txt /tmp/packages.txt
RUN set -eu; {install}
WORKDIR /work
CMD ["/bin/sh"]
"""


def images(doc):
    """Yield (name, spec) for the images section, skipping images_other."""
    for section in doc:
        for entry in section.get("images", []):
            (name, spec), = entry.items()
            yield name, spec


# depth: the install command is a YAML block scalar with shell line
# continuations; collapse it to one line so it survives a single RUN.
def one_line(command):
    return " ".join(re.sub(r"\\\n", " ", command).split())


def main(src, out):
    doc = yaml.safe_load(pathlib.Path(src).read_text())
    out = pathlib.Path(out)
    shutil.rmtree(out, ignore_errors=True)
    for name, spec in images(doc):
        context = out / name
        context.mkdir(parents=True)
        (context / "packages.txt").write_text(spec["packages.txt"])
        (context / "Containerfile").write_text(CONTAINERFILE.format(
            src=src, base=spec["base"],
            install=one_line(spec["package-install-command"])))
        print(f"generated {context}/ from {spec['base']}", file=sys.stderr)
        print(name)


if __name__ == "__main__":
    main(*sys.argv[1:3])
