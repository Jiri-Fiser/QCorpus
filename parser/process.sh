#!/usr/bin/env bash

python3.11 py_pyast.py example4.py > output/example_pyast.xml
xsltproc pyast_simplify.xslt output/example_pyast.xml > output/example_pyast_s.xml
xsltproc pyast_qcast.xslt output/example_pyast_s.xml > output/example_qcast.xml
xmllint --format output/example_qcast.xml > formatted_output/example_qcast.xml
xmllint --format output/example_pyast_s.xml > formatted_output/example_pyast_s.xml
