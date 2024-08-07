from json import load
import re
from parser.py_pyast import process_string


def source(cell):
    return "".join(cell["source"])


def is_code(cell):
    return cell["cell_type"] == "code"


def is_markdown(cell):
    return cell["cell_type"] == "markdown"


class JupyterNotebookScaner:
    def __init__(self, filename):
        context = load(open(filename))
        self.language = context["metadata"]["kernelspec"]["language"]
        self.cells = context["cells"]
        self.fragments = list(self.cell_filter())

    def cell_filter(self):
        pass


class AllCodeJNScaner(JupyterNotebookScaner):
    def __init__(self, filename):
        super().__init__(filename)

    def cell_filter(self):
        for cell in self.cells:
            if is_code(cell):
                yield source(cell)


class PPSS_JNScanner(JupyterNotebookScaner):

    def __init__(self, filename):
        super().__init__(filename)

    def cell_filter(self):
        for c1, c2 in zip(self.cells, self.cells[1:]):
            if is_code(c2) and is_markdown(c1) and re.search(f"####\s+Cvičení", source(c1)):
                yield source(c2)


s = PPSS_JNScanner("/home/fiser/data/studenti_qc/anezka_hradcova/PPSS Lekce 5.ipynb")
for i, f in enumerate(s.fragments):
    print(f"*** {i} ***************************")
    try:
        print(process_string(f, "../parser/pyast_simplify.xslt", "../parser/pyast_qcast.xslt"))
    except SyntaxError:
        pass