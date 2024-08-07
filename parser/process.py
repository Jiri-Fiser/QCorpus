from ast import parse

from lxml import etree as ET
from py_pyast import generate, pyast_ns, qc_ns


def join_nodes(dummy, nodes, separator=","):
    return separator.join(str(node) for node in nodes)


def transform_etree_with_xslt(etree, xslt_file, params={}):
    # Načíst XSLT soubor
    with open(xslt_file, 'rb') as f:
        xslt_content = f.read()
    ns = ET.FunctionNamespace("http://jf.cz/ns/pyex")
    ns.prefix = "ex"
    ns["join"] = join_nodes
    xslt_root = ET.XML(xslt_content)
    transform = ET.XSLT(xslt_root)

    # Aplikovat transformaci
    transformed_etree = transform(etree, **params)

    # Vrátit transformovaný etree
    return transformed_etree


def process(ast):
    ET.register_namespace("py", pyast_ns)
    ET.register_namespace("qc", qc_ns)
    root = ET.Element(f"{{{pyast_ns}}}ast")
    generate(ast, root)
    stree = transform_etree_with_xslt(root, "pyast_simplify.xslt")
    qctree = transform_etree_with_xslt(stree, "pyast_qcast.xslt")
    return qctree


def to_string(qc):
    return ET.tostring(qc, encoding="unicode", pretty_print=True)

if __name__ == "__main__":
    test_prog = """
for i in range(2):
    for j in range(2):
        print(i,j)
    """
    ast = parse(test_prog)
    qc = process(ast)
    print(ET.tostring(qc, encoding="unicode", pretty_print=True))
    r = transform_etree_with_xslt(qc, "tags_depth.xslt")
    print(int(r))
